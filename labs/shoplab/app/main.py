from __future__ import annotations

import base64
import binascii
import hashlib
import hmac
import html
import ipaddress
import json
import os
import time
import uuid
from contextlib import asynccontextmanager
from pathlib import Path
from urllib.parse import urlparse

import psycopg
from fastapi import Body, Depends, FastAPI, Header, HTTPException, Request
from fastapi.responses import HTMLResponse, JSONResponse, RedirectResponse
from prometheus_client import CONTENT_TYPE_LATEST, Counter, generate_latest
from starlette.responses import Response


MODE = os.getenv("LAB_MODE", "vulnerable")
DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://websec:local-training-only@db:5432/websec")
SIGNING_KEY = os.getenv("LAB_SIGNING_KEY", "synthetic-local-key-not-for-production").encode()
LOG_PATH = Path(os.getenv("LOG_PATH", "/tmp/websec-app.jsonl"))
REQUESTS = Counter("websec_http_requests_total", "ShopLab HTTP requests", ["method", "path", "status", "mode"])
AUTH_EVENTS = Counter("websec_auth_events_total", "ShopLab authentication and authorisation events", ["event", "result", "mode"])
FAILURES: dict[str, list[float]] = {}
REVOKED: dict[str, int] = {}
ALLOWED_ORIGINS = {"https://127.0.0.1:8443", "https://localhost:8443"}
UPLOAD_ROOT = Path("/tmp/shoplab-uploads")


def b64(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).decode().rstrip("=")


def unb64(value: str) -> bytes:
    return base64.urlsafe_b64decode(value + "=" * (-len(value) % 4))


def make_token(user_id: int, username: str, role: str) -> str:
    header = b64(json.dumps({"alg": "HS256", "typ": "JWT"}, separators=(",", ":")).encode())
    payload = b64(json.dumps({"sub": str(user_id), "username": username, "role": role, "jti": str(uuid.uuid4()), "exp": int(time.time()) + 1800}, separators=(",", ":")).encode())
    signature = b64(hmac.new(SIGNING_KEY, f"{header}.{payload}".encode(), hashlib.sha256).digest())
    return f"{header}.{payload}.{signature}"


def read_token(token: str) -> dict:
    try:
        header, payload, signature = token.split(".")
        expected = b64(hmac.new(SIGNING_KEY, f"{header}.{payload}".encode(), hashlib.sha256).digest())
        if not hmac.compare_digest(signature, expected):
            raise ValueError("signature")
        data = json.loads(unb64(payload))
        if int(data["exp"]) < int(time.time()):
            raise ValueError("expired")
        if data.get("jti") in REVOKED:
            raise ValueError("revoked")
        return data
    except Exception as exc:
        raise HTTPException(status_code=401, detail="token invalide ou expiré") from exc


def password_hash(password: str, salt: bytes) -> str:
    value = hashlib.pbkdf2_hmac("sha256", password.encode(), salt, 210_000)
    return f"{b64(salt)}${b64(value)}"


def verify_password(password: str, stored: str) -> bool:
    salt_b64, digest = stored.split("$", 1)
    return hmac.compare_digest(password_hash(password, unb64(salt_b64)), stored)


def db():
    return psycopg.connect(DATABASE_URL)


def log_event(event: str, result: str, correlation_id: str, **fields) -> None:
    safe = {k: v for k, v in fields.items() if k.lower() not in {"authorization", "cookie", "password", "token"}}
    record = {"timestamp": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()), "service": "websec-api", "event": event, "result": result, "mode": MODE, "correlation_id": correlation_id, **safe}
    line = json.dumps(record, ensure_ascii=False, separators=(",", ":"))
    print(line, flush=True)
    LOG_PATH.parent.mkdir(parents=True, exist_ok=True)
    with LOG_PATH.open("a", encoding="utf-8") as handle:
        handle.write(line + "\n")


def initialise() -> None:
    for attempt in range(30):
        try:
            with db() as conn, conn.cursor() as cur:
                cur.execute("CREATE TABLE IF NOT EXISTS users (id integer primary key, username text unique not null, password_hash text not null, email text not null, role text not null, display_name text not null, internal_note text not null)")
                cur.execute("CREATE TABLE IF NOT EXISTS products (id integer primary key, name text not null, description text not null, price numeric not null)")
                users = [(1, "alice", "atelier-alice", "alice@shoplab.invalid", "user", "Alice", "Compte synthétique A"), (2, "bob", "atelier-bob", "bob@shoplab.invalid", "user", "Bob", "Compte synthétique B"), (3, "admin", "atelier-admin", "admin@shoplab.invalid", "admin", "Admin Lab", "Administration locale")]
                for uid, username, password, email, role, display, note in users:
                    salt = hashlib.sha256(f"shoplab-{username}".encode()).digest()[:16]
                    cur.execute("INSERT INTO users VALUES (%s,%s,%s,%s,%s,%s,%s) ON CONFLICT (id) DO UPDATE SET username=EXCLUDED.username,password_hash=EXCLUDED.password_hash,email=EXCLUDED.email,role=EXCLUDED.role,display_name=EXCLUDED.display_name,internal_note=EXCLUDED.internal_note", (uid, username, password_hash(password, salt), email, role, display, note))
                products = [(1, "Desk lamp", "LED laboratory lamp", 45), (2, "USB key", "Synthetic training item", 12), (3, "Notebook", "Evidence notebook", 8)]
                for row in products:
                    cur.execute("INSERT INTO products VALUES (%s,%s,%s,%s) ON CONFLICT (id) DO UPDATE SET name=EXCLUDED.name,description=EXCLUDED.description,price=EXCLUDED.price", row)
                conn.commit()
            return
        except psycopg.OperationalError:
            if attempt == 29:
                raise
            time.sleep(1)


@asynccontextmanager
async def lifespan(_: FastAPI):
    initialise()
    yield


app = FastAPI(title="ShopLab API", version="1.0.0", lifespan=lifespan)


@app.middleware("http")
async def audit(request: Request, call_next):
    correlation_id = request.headers.get("x-correlation-id", str(uuid.uuid4()))[:80]
    request.state.correlation_id = correlation_id
    started = time.monotonic()
    try:
        response = await call_next(request)
    except Exception:
        log_event("http_request", "error", correlation_id, method=request.method, path=request.url.path, status=500)
        raise
    duration_ms = round((time.monotonic() - started) * 1000, 2)
    REQUESTS.labels(request.method, request.url.path, str(response.status_code), MODE).inc()
    response.headers["X-Correlation-ID"] = correlation_id
    log_event("http_request", "ok" if response.status_code < 400 else "denied", correlation_id, method=request.method, path=request.url.path, status=response.status_code, duration_ms=duration_ms)
    return response


def current_user(request: Request, authorization: str | None = Header(default=None)) -> dict:
    token = authorization[7:] if authorization and authorization.startswith("Bearer ") else request.cookies.get("lab_session")
    if not token:
        AUTH_EVENTS.labels("authentication", "missing", MODE).inc()
        raise HTTPException(status_code=401, detail="session ou Bearer token requis")
    return read_token(token)


def revoke(token: str) -> dict:
    data = read_token(token)
    REVOKED[str(data["jti"])] = int(data["exp"])
    now = int(time.time())
    for jti, expiry in list(REVOKED.items()):
        if expiry < now:
            REVOKED.pop(jti, None)
    return data


def require_csrf(request: Request) -> None:
    if MODE != "corrected":
        return
    cookie = request.cookies.get("lab_csrf", "")
    header = request.headers.get("x-csrf-token", "")
    origin = request.headers.get("origin")
    if not cookie or not header or not hmac.compare_digest(cookie, header):
        raise HTTPException(status_code=403, detail="jeton CSRF absent ou invalide")
    if origin and origin not in ALLOWED_ORIGINS:
        raise HTTPException(status_code=403, detail="origine refusée")


@app.get("/api/health")
def health():
    with db() as conn, conn.cursor() as cur:
        cur.execute("SELECT 1")
        cur.fetchone()
    return {"status": "ok", "service": "websec-api", "mode": MODE}


@app.get("/api/metrics")
def metrics():
    return Response(generate_latest(), media_type=CONTENT_TYPE_LATEST)


@app.post("/api/auth/login")
def login(request: Request, payload: dict = Body(...)):
    username = str(payload.get("username", ""))
    password = str(payload.get("password", ""))
    recent = [x for x in FAILURES.get(username, []) if time.time() - x < 60]
    FAILURES[username] = recent
    if MODE == "corrected" and len(recent) >= 5:
        AUTH_EVENTS.labels("authentication", "rate_limited", MODE).inc()
        log_event("authentication", "rate_limited", request.state.correlation_id, username=username)
        raise HTTPException(status_code=429, detail="réessayer plus tard")
    with db() as conn, conn.cursor() as cur:
        cur.execute("SELECT id,username,password_hash,role,display_name FROM users WHERE username=%s", (username,))
        row = cur.fetchone()
    if not row or not verify_password(password, row[2]):
        FAILURES[username].append(time.time())
        AUTH_EVENTS.labels("authentication", "failed", MODE).inc()
        log_event("authentication", "failed", request.state.correlation_id, username=username)
        raise HTTPException(status_code=401, detail="identifiants invalides")
    token = make_token(row[0], row[1], row[3])
    AUTH_EVENTS.labels("authentication", "success", MODE).inc()
    log_event("authentication", "success", request.state.correlation_id, username=username, subject_id=row[0])
    csrf = b64(os.urandom(24))
    response = JSONResponse({"access_token": token, "csrf_token": csrf, "token_type": "bearer", "user": {"id": row[0], "username": row[1], "display_name": row[4]}})
    response.set_cookie("lab_session", token, httponly=True, secure=MODE == "corrected", samesite="lax", max_age=1800)
    response.set_cookie("lab_csrf", csrf, httponly=False, secure=MODE == "corrected", samesite="lax", max_age=1800)
    return response


@app.post("/api/auth/refresh")
def refresh(request: Request):
    token = request.cookies.get("lab_session")
    if not token:
        raise HTTPException(status_code=401, detail="session requise")
    old = revoke(token)
    new_token = make_token(int(old["sub"]), str(old["username"]), str(old["role"]))
    response = JSONResponse({"access_token": new_token, "token_type": "bearer"})
    response.set_cookie("lab_session", new_token, httponly=True, secure=MODE == "corrected", samesite="lax", max_age=1800)
    return response


@app.post("/api/auth/logout")
def logout(request: Request):
    require_csrf(request)
    token = request.cookies.get("lab_session")
    if token:
        revoke(token)
    response = JSONResponse({"status": "logged_out"})
    response.delete_cookie("lab_session")
    response.delete_cookie("lab_csrf")
    return response


@app.get("/api/users/{user_id}")
def user_profile(user_id: int, request: Request, user: dict = Depends(current_user)):
    if MODE == "corrected" and int(user["sub"]) != user_id and user.get("role") != "admin":
        AUTH_EVENTS.labels("authorization", "denied", MODE).inc()
        log_event("authorization", "denied", request.state.correlation_id, subject_id=user["sub"], object_id=user_id, action="read_profile")
        raise HTTPException(status_code=403, detail="accès objet refusé")
    with db() as conn, conn.cursor() as cur:
        cur.execute("SELECT id,username,email,role,display_name,internal_note FROM users WHERE id=%s", (user_id,))
        row = cur.fetchone()
    if not row:
        raise HTTPException(status_code=404, detail="utilisateur absent")
    AUTH_EVENTS.labels("authorization", "allowed", MODE).inc()
    result = {"id": row[0], "username": row[1], "email": row[2], "role": row[3], "display_name": row[4]}
    if MODE == "vulnerable":
        result["internal_note"] = row[5]
    return result


@app.patch("/api/users/me")
def update_me(payload: dict = Body(...), user: dict = Depends(current_user)):
    allowed = {"display_name"}
    updates = dict(payload) if MODE == "vulnerable" else {k: v for k, v in payload.items() if k in allowed}
    if not updates:
        raise HTTPException(status_code=422, detail="aucun champ autorisé")
    if "role" in updates:
        with db() as conn, conn.cursor() as cur:
            cur.execute("UPDATE users SET role=%s WHERE id=%s", (str(updates["role"]), int(user["sub"])))
            conn.commit()
    if "display_name" in updates:
        with db() as conn, conn.cursor() as cur:
            cur.execute("UPDATE users SET display_name=%s WHERE id=%s", (str(updates["display_name"])[:80], int(user["sub"])))
            conn.commit()
    return {"updated": sorted(updates)}


@app.post("/api/profile/display-name")
def update_display_name(request: Request, payload: dict = Body(...), user: dict = Depends(current_user)):
    require_csrf(request)
    value = str(payload.get("display_name", "")).strip()
    if not value or len(value) > 80:
        raise HTTPException(status_code=422, detail="display_name invalide")
    with db() as conn, conn.cursor() as cur:
        cur.execute("UPDATE users SET display_name=%s WHERE id=%s", (value, int(user["sub"])))
        conn.commit()
    return {"updated": ["display_name"]}


@app.get("/api/products")
def products(q: str = ""):
    with db() as conn, conn.cursor() as cur:
        if MODE == "vulnerable":
            # Intentionally vulnerable local teaching branch; TP05 replaces concatenation with parameters.
            cur.execute(f"SELECT id,name,description,price FROM products WHERE name ILIKE '%{q}%'")
        else:
            cur.execute("SELECT id,name,description,price FROM products WHERE name ILIKE %s", (f"%{q}%",))
        rows = cur.fetchall()
    return [{"id": r[0], "name": r[1], "description": r[2], "price": float(r[3])} for r in rows]


@app.get("/api/file")
def read_file(name: str):
    root = Path("/app/sample-public")
    candidate = (root / name).resolve()
    if MODE == "corrected" and (candidate.parent != root.resolve() or candidate.name != Path(name).name):
        raise HTTPException(status_code=400, detail="nom de fichier refusé")
    try:
        return {"name": name, "content": candidate.read_text(encoding="utf-8")}
    except FileNotFoundError as exc:
        raise HTTPException(status_code=404, detail="fichier absent") from exc


@app.get("/api/url-check")
def url_check(url: str):
    parsed = urlparse(url)
    allowed = parsed.scheme in {"http", "https"} and bool(parsed.hostname)
    reason = "format accepté; aucune requête réseau exécutée"
    if MODE == "corrected" and allowed:
        host = parsed.hostname or ""
        allowed = parsed.scheme == "https" and host == "status.shoplab.invalid" and parsed.port in {None, 443} and parsed.path == "/health"
        reason = "destination pédagogique allowlistée; aucune requête réseau exécutée" if allowed else "destination hors allowlist refusée"
    return {"url": url, "allowed": allowed, "reason": reason, "fetched": False}


@app.post("/api/uploads", status_code=201)
def upload(payload: dict = Body(...), user: dict = Depends(current_user)):
    filename = str(payload.get("filename", ""))
    content_type = str(payload.get("content_type", ""))
    try:
        content = base64.b64decode(str(payload.get("content_b64", "")), validate=True)
    except (binascii.Error, ValueError) as exc:
        raise HTTPException(status_code=422, detail="contenu base64 invalide") from exc
    if len(content) > 65_536:
        raise HTTPException(status_code=413, detail="fichier trop volumineux")
    UPLOAD_ROOT.mkdir(parents=True, exist_ok=True)
    if MODE == "corrected":
        suffixes = Path(filename).suffixes
        allowed_types = {".txt": "text/plain", ".png": "image/png"}
        if len(suffixes) != 1 or suffixes[0].lower() not in allowed_types or content_type != allowed_types[suffixes[0].lower()]:
            raise HTTPException(status_code=415, detail="type de fichier refusé")
        stored = f"{uuid.uuid4()}{suffixes[0].lower()}"
    else:
        stored = filename
    target = (UPLOAD_ROOT / stored).resolve()
    if MODE == "corrected" and target.parent != UPLOAD_ROOT.resolve():
        raise HTTPException(status_code=400, detail="nom de fichier refusé")
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_bytes(content)
    return {"original_name": Path(filename).name, "stored_name": stored, "size": len(content), "owner_id": user["sub"], "served": False}


@app.get("/api/redirect")
def redirect(next: str = "/"):
    if MODE == "corrected" and (not next.startswith("/") or next.startswith("//")):
        raise HTTPException(status_code=400, detail="redirection externe refusée")
    return RedirectResponse(next, status_code=302)


@app.get("/api/echo", response_class=HTMLResponse)
def echo(value: str = "bonjour"):
    rendered = value if MODE == "vulnerable" else html.escape(value)
    return f"<!doctype html><meta charset='utf-8'><p id='echo'>{rendered}</p>"
