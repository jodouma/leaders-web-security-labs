#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"

result="$STATE_DIR/lifecycle.txt"
: > "$result"
step() { printf '[PASS] %s\n' "$1" | tee -a "$result"; }
fail() { printf '[FAIL] %s\n' "$1" | tee -a "$result" >&2; exit 1; }
cleanup_on_exit() {
  rc=$?
  if [[ $rc -ne 0 ]]; then printf '[FAIL] runtime-test exit=%s\n' "$rc" >> "$result"; fi
  "$(dirname "$0")/cleanup.sh" >/dev/null 2>&1 || true
  exit "$rc"
}
trap cleanup_on_exit EXIT INT TERM

# A lifecycle test owns only this named Compose project. Begin from a clean,
# reproducible lab state so a previously interrupted container cannot mask bugs.
compose --profile core --profile security --profile observe down -v --remove-orphans >/dev/null 2>&1 || true

compose --profile core build || fail build
step '1 build core'

prepare_mode vulnerable
prepare_tls
compose --profile core up -d || fail start
"$(dirname "$0")/lab-start.sh" core >/dev/null || fail start_wait
step '2 start core vulnerable'

"$(dirname "$0")/health-check.sh" core >/dev/null || fail health
step '3 health check core'

"$(dirname "$0")/verify-vulnerability.sh" | tee -a "$result"
step '4 vulnerability demonstrated (BOLA + SQLi)'

"$(dirname "$0")/verify-remediation.sh" | tee -a "$result"
step '5 correction applied and retest passed'

"$(dirname "$0")/lab-start.sh" observe >/dev/null || fail observe_start
"$(dirname "$0")/health-check.sh" observe >/dev/null || fail observe_health
curl -sS -o /dev/null -H 'Authorization: Bearer invalid.lab.token' "http://127.0.0.1:${SHOPLAB_HTTP_PORT:-8080}/api/users/2" || true

metric_ok=0
log_ok=0
for _ in $(seq 1 40); do
  if curl -fsS "http://127.0.0.1:${SHOPLAB_PROM_PORT:-9090}/api/v1/query?query=websec_http_requests_total" | grep -q 'websec_http_requests_total'; then metric_ok=1; fi
  if curl -G -fsS --data-urlencode 'query={service="websec-api"}' --data-urlencode 'limit=20' "http://127.0.0.1:${SHOPLAB_LOKI_PORT:-3100}/loki/api/v1/query_range" | grep -q 'websec-api'; then log_ok=1; fi
  if [[ "$metric_ok" -eq 1 && "$log_ok" -eq 1 ]]; then break; fi
  sleep 3
done
[[ "$metric_ok" -eq 1 ]] || fail prometheus_query
[[ "$log_ok" -eq 1 ]] || fail loki_query
step '6 logs and metrics queried; OpenTelemetry/Grafana stack healthy'

"$(dirname "$0")/reset.sh" >/dev/null || fail reset
mode=$(curl -fsS "http://127.0.0.1:${SHOPLAB_HTTP_PORT:-8080}/api/health" | python3 -c 'import json,sys; print(json.load(sys.stdin)["mode"])')
[[ "$mode" == vulnerable ]] || fail reset_mode
step '7 reset restored vulnerable mode'

compose --profile core --profile security --profile observe down -v --remove-orphans >/dev/null || fail cleanup
remaining=$(compose --profile core --profile security --profile observe ps -q | wc -l | tr -d ' ')
[[ "$remaining" -eq 0 ]] || fail cleanup_remaining
step '8 cleanup removed running websec containers'

printf 'Résumé: PASS=8 FAIL=0\n' | tee -a "$result"
