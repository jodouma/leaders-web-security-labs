#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"

"$(dirname "$0")/set-mode.sh" corrected >/dev/null
base="http://127.0.0.1:${SHOPLAB_HTTP_PORT:-8080}"
token=$(curl -fsS -H 'Content-Type: application/json' -d '{"username":"alice","password":"atelier-alice"}' "$base/api/auth/login" | python3 -c 'import json,sys; print(json.load(sys.stdin)["access_token"])')
own=$(curl -sS -o /tmp/websec-own.json -w '%{http_code}' -H "Authorization: Bearer $token" "$base/api/users/1")
other=$(curl -sS -o /tmp/websec-other.json -w '%{http_code}' -H "Authorization: Bearer $token" "$base/api/users/2")
bad_count=$(curl -fsS --get --data-urlencode "q=' OR '1'='1" "$base/api/products" | python3 -c 'import json,sys; print(len(json.load(sys.stdin)))')
good_count=$(curl -fsS --get --data-urlencode 'q=lamp' "$base/api/products" | python3 -c 'import json,sys; print(len(json.load(sys.stdin)))')
headers=$(curl -skI "https://127.0.0.1:${SHOPLAB_HTTPS_PORT:-8443}/")
test "$own" = 200
test "$other" = 403
test "$bad_count" -eq 0
test "$good_count" -eq 1
grep -qi '^content-security-policy:' <<<"$headers"
grep -qi '^x-content-type-options:' <<<"$headers"
compose --profile core exec -T api sh -c 'grep -q '"'"'"event":"authorization","result":"denied"'"'"' /var/log/websec/app.jsonl'
printf '[PASS] remédiation: own=%s other=%s sql_bad=%s sql_good=%s headers=PASS logs=PASS\n' "$own" "$other" "$bad_count" "$good_count"
rm -f /tmp/websec-own.json /tmp/websec-other.json
