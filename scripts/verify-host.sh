#!/usr/bin/env bash
set -uo pipefail
pass=0 warn=0 fail=0
ok(){ printf '[PASS] %s\n' "$*"; pass=$((pass+1)); }
warning(){ printf '[WARN] %s\n' "$*" >&2; warn=$((warn+1)); }
bad(){ printf '[FAIL] %s\n' "$*" >&2; fail=$((fail+1)); }
has(){ command -v "$1" >/dev/null 2>&1; }

for cmd in git curl openssl python3 docker; do
  if has "$cmd"; then ok "$cmd disponible"; else bad "$cmd absent"; fi
done
if has docker; then
  if docker info >/dev/null 2>&1; then ok 'daemon Docker accessible'; else bad 'daemon Docker inaccessible'; fi
  if docker compose version >/dev/null 2>&1; then ok "Compose v2: $(docker compose version --short 2>/dev/null || true)"; else bad 'docker compose v2 absent'; fi
fi
if has python3; then
  if python3 - <<'PY' >/dev/null 2>&1
import sys
raise SystemExit(0 if sys.version_info >= (3, 11) else 1)
PY
  then ok 'Python >= 3.11'; else bad 'Python 3.11+ requis'; fi
fi
arch=$(uname -m 2>/dev/null || printf unknown)
case "$arch" in x86_64|amd64|arm64|aarch64) ok "architecture $arch";; *) warning "architecture $arch non validée";; esac
free_kb=$(df -Pk . 2>/dev/null | awk 'NR==2 {print $4}')
if [[ ${free_kb:-0} -ge 6291456 ]]; then ok 'au moins 6 Gio libres'; else warning 'moins de 6 Gio libres ou mesure indisponible'; fi

printf 'Résumé: PASS=%d WARN=%d FAIL=%d\n' "$pass" "$warn" "$fail"
exit "$([[ $fail -eq 0 ]] && printf 0 || printf 1)"
