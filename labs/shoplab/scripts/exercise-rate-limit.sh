#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"
base="http://127.0.0.1:${SHOPLAB_HTTP_PORT:-8080}"
"$(dirname "$0")/set-mode.sh" corrected >/dev/null
seen=0
for attempt in 1 2 3 4 5 6 7; do
  code=$(curl -sS -o /dev/null -w '%{http_code}' -H 'Content-Type: application/json' -d '{"username":"rate-limit-student","password":"synthetic-wrong"}' "$base/api/auth/login")
  printf '[%s] tentative=%d status=%s\n' "$([[ "$code" == 429 ]] && printf PASS || printf WARN)" "$attempt" "$code"
  if [[ "$code" == 429 ]]; then seen=1; break; fi
done
if [[ "$seen" == 1 ]]; then printf '[PASS] quota observé avec 429\n'; else printf '[FAIL] aucun 429 observé\n' >&2; exit 1; fi
