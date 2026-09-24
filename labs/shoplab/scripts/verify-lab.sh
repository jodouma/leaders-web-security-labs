#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"

suite=${1:-basic}
pass=0 warn=0 fail=0
tmp=$(mktemp -d "${TMPDIR:-/tmp}/shoplab-verify.XXXXXX")
cleanup() {
  rm -rf "$tmp"
}
trap cleanup EXIT INT TERM

ok() { printf '[PASS] %s\n' "$1"; pass=$((pass+1)); }
bad() { printf '[FAIL] %s\n' "$1" >&2; fail=$((fail+1)); }
note() { printf '[WARN] %s\n' "$1" >&2; warn=$((warn+1)); }
assert_status() {
  local label=$1 expected=$2; shift 2
  local actual
  actual=$(curl -ksS -o /dev/null -w '%{http_code}' "$@" || true)
  if [[ "$actual" == "$expected" ]]; then ok "$label ($actual)"; else bad "$label (attendu=$expected obtenu=$actual)"; fi
}
login() {
  curl -ksS -H 'Content-Type: application/json' -d "{\"username\":\"$1\",\"password\":\"$2\"}" "$base/api/auth/login"
}

base="http://127.0.0.1:${SHOPLAB_HTTP_PORT:-8080}"
https="https://127.0.0.1:${SHOPLAB_HTTPS_PORT:-8443}"
if ! curl -fsS "$base/api/health" >/dev/null; then
  bad 'lab non démarré'; printf 'Résumé: PASS=%d WARN=%d FAIL=%d\n' "$pass" "$warn" "$fail"; exit 1
fi

case "$suite" in
  basic)
    if curl -kfsS "$https/api/health" >/dev/null; then ok 'health HTTP et HTTPS'; else bad 'health HTTPS'; fi
    if compose --profile core config -q; then ok 'Compose valide'; else bad 'Compose invalide'; fi
    ;;
  authz)
    "$(dirname "$0")/set-mode.sh" corrected >/dev/null
    alice=$(login alice atelier-alice | python3 -c 'import json,sys; print(json.load(sys.stdin)["access_token"])')
    assert_status 'anonyme refusé' 401 "$base/api/users/2"
    assert_status 'propriétaire permis' 200 -H "Authorization: Bearer $alice" "$base/api/users/1"
    assert_status 'tiers refusé' 403 -H "Authorization: Bearer $alice" "$base/api/users/2"
    ;;
  session)
    "$(dirname "$0")/set-mode.sh" corrected >/dev/null
    curl -ksS -D "$tmp/login.headers" -c "$tmp/cookies" -H 'Content-Type: application/json' \
      -d '{"username":"alice","password":"atelier-alice"}' "$https/api/auth/login" >"$tmp/login.json"
    token=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["access_token"])' "$tmp/login.json")
    csrf=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["csrf_token"])' "$tmp/login.json")
    if grep -qi '^set-cookie: lab_session=' "$tmp/login.headers" && grep -qi 'httponly' "$tmp/login.headers" && grep -qi 'secure' "$tmp/login.headers" && grep -qi 'samesite=lax' "$tmp/login.headers"; then
      ok 'cookie de session HttpOnly, Secure et SameSite=Lax'
    else
      bad 'attributs du cookie de session incomplets'
    fi
    assert_status 'CSRF absent refusé' 403 -b "$tmp/cookies" -H 'Content-Type: application/json' -d '{"display_name":"Alice"}' "$https/api/profile/display-name"
    assert_status 'CSRF correct accepté' 200 -b "$tmp/cookies" -H "X-CSRF-Token: $csrf" -H 'Origin: https://127.0.0.1:8443' -H 'Content-Type: application/json' -d '{"display_name":"Alice"}' "$https/api/profile/display-name"
    curl -ksS -b "$tmp/cookies" -c "$tmp/cookies" -X POST "$https/api/auth/refresh" >"$tmp/refresh.json"
    rotated=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["access_token"])' "$tmp/refresh.json")
    assert_status 'ancien token refusé après rotation' 401 -H "Authorization: Bearer $token" "$base/api/users/1"
    assert_status 'token tourné accepté' 200 -H "Authorization: Bearer $rotated" "$base/api/users/1"
    assert_status 'logout accepté' 200 -X POST -b "$tmp/cookies" -H "X-CSRF-Token: $csrf" -H 'Origin: https://127.0.0.1:8443' "$https/api/auth/logout"
    assert_status 'token refusé après logout' 401 -H "Authorization: Bearer $rotated" "$base/api/users/1"
    ;;
  injection)
    "$(dirname "$0")/set-mode.sh" corrected >/dev/null
    rows=$(curl -fsS --get --data-urlencode "q=' OR '1'='1" "$base/api/products" | python3 -c 'import json,sys; print(len(json.load(sys.stdin)))')
    if [[ "$rows" == 0 ]]; then ok 'SQLi neutralisée'; else bad "SQLi retourne $rows lignes"; fi
    if curl -fsS --get --data-urlencode 'value=<b>x</b>' "$base/api/echo" | grep -q '&lt;b&gt;'; then ok 'XSS encodée'; else bad 'XSS non encodée'; fi
    ;;
  files)
    "$(dirname "$0")/set-mode.sh" corrected >/dev/null
    token=$(login alice atelier-alice | python3 -c 'import json,sys; print(json.load(sys.stdin)["access_token"])')
    assert_status 'traversal refusé' 400 --get --data-urlencode 'name=../sample-training-vault/demo.txt' "$base/api/file"
    payload='{"filename":"note.txt","content_type":"text/plain","content_b64":"Ym9uam91cg=="}'
    assert_status 'upload texte accepté' 201 -H "Authorization: Bearer $token" -H 'Content-Type: application/json' -d "$payload" "$base/api/uploads"
    if curl -fsS --get --data-urlencode 'url=http://127.0.0.1' "$base/api/url-check" | grep -q '"fetched":false'; then ok 'SSRF sans fetch'; else bad 'simulateur SSRF'; fi
    ;;
  api)
    "$(dirname "$0")/set-mode.sh" corrected >/dev/null
    if curl -fsS "$base/openapi.json" | python3 -c 'import json,sys; assert len(json.load(sys.stdin)["paths"]) > 0'; then
      ok 'schéma OpenAPI accessible via le proxy'
    else
      bad 'schéma OpenAPI inaccessible via le proxy'
    fi
    token=$(login alice atelier-alice | python3 -c 'import json,sys; print(json.load(sys.stdin)["access_token"])')
    body=$(curl -fsS -X PATCH -H "Authorization: Bearer $token" -H 'Content-Type: application/json' -d '{"display_name":"Alice","role":"admin"}' "$base/api/users/me")
    if grep -q 'display_name' <<<"$body" && ! grep -q '"role"' <<<"$body"; then ok 'mass assignment filtré'; else bad 'mass assignment'; fi
    ;;
  hardening)
    headers=$(curl -ksSI "$https/")
    if grep -qi '^content-security-policy:' <<<"$headers"; then ok 'CSP présente'; else bad 'CSP absente'; fi
    if grep -qi '^x-content-type-options:' <<<"$headers"; then ok 'nosniff présent'; else bad 'nosniff absent'; fi
    cid=$(compose --profile core ps -q api)
    if [[ -n "$cid" ]] && [[ $(docker inspect "$cid" --format '{{.HostConfig.ReadonlyRootfs}}') == true ]]; then ok 'API read-only'; else bad 'API non read-only'; fi
    ;;
  database)
    roles=$(compose --profile core exec -T db psql -U websec -d websec -Atc "SELECT count(*) FROM pg_roles WHERE rolname IN ('shoplab_runtime','shoplab_readonly','shoplab_backup')")
    [[ "$roles" == 3 ]] && ok 'trois rôles applicatifs présents' || bad "rôles présents=$roles attendu=3"
    runtime=$(compose --profile core exec -T db psql -U websec -d websec -Atc "SELECT has_table_privilege('shoplab_runtime','products','SELECT') AND NOT pg_has_role('shoplab_runtime','websec','MEMBER') AND NOT has_table_privilege('shoplab_runtime','audit_events','SELECT')")
    [[ "$runtime" == t ]] && ok 'runtime: lecture métier permise, DDL/audit refusés' || bad 'privilèges runtime incorrects'
    readonly=$(compose --profile core exec -T db psql -U websec -d websec -Atc "SELECT has_table_privilege('shoplab_readonly','products','SELECT') AND NOT has_table_privilege('shoplab_readonly','products','UPDATE')")
    [[ "$readonly" == t ]] && ok 'readonly: lecture permise, écriture refusée' || bad 'privilèges readonly incorrects'
    backup=$(compose --profile core exec -T db psql -U websec -d websec -Atc "SELECT has_table_privilege('shoplab_backup','users','SELECT') AND has_table_privilege('shoplab_backup','products','SELECT')")
    [[ "$backup" == t ]] && ok 'backup: lecture des tables métier permise' || bad 'privilèges backup incorrects'
    ;;
  observability)
    note "$suite nécessite la procédure guidée TP07 et une validation manuelle des preuves"
    ;;
  *) bad "suite inconnue: $suite" ;;
esac

printf 'Résumé: PASS=%d WARN=%d FAIL=%d suite=%s\n' "$pass" "$warn" "$fail" "$suite"
test "$fail" -eq 0
