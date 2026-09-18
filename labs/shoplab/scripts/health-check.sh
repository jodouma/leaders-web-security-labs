#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"

profile=${1:-core}
pass=0
fail=0
report="$STATE_DIR/last-health.txt"
: > "$report"

check() {
  local label=$1; shift
  if "$@" >/dev/null 2>&1; then
    printf '[PASS] %s\n' "$label" | tee -a "$report"; pass=$((pass+1))
  else
    printf '[FAIL] %s\n' "$label" | tee -a "$report"; fail=$((fail+1))
  fi
}

api_non_root() {
  local uid
  uid=$(compose --profile core exec -T api id -u | tr -d '\r')
  [[ "$uid" != 0 ]]
}

api_read_only() {
  local cid
  cid=$(compose --profile core ps -q api)
  [[ -n "$cid" ]] && [[ $(docker inspect "$cid" --format '{{.HostConfig.ReadonlyRootfs}}') == true ]]
}

check 'Compose config core' compose --profile core config -q
check 'réseau core internal' bash -c "docker network inspect '${COMPOSE_PROJECT_NAME}_core' --format '{{.Internal}}' | grep -qx true"
check 'API health via HTTP' curl -fsS "http://127.0.0.1:${SHOPLAB_HTTP_PORT:-8080}/api/health"
check 'proxy TLS local' curl -kfsS "https://127.0.0.1:${SHOPLAB_HTTPS_PORT:-8443}/api/health"
check 'frontend' curl -fsS "http://127.0.0.1:${SHOPLAB_HTTP_PORT:-8080}/"
check 'PostgreSQL healthy' compose --profile core exec -T db pg_isready -U websec -d websec
check 'API non-root' api_non_root
check 'API rootfs read-only' api_read_only
check 'log applicatif présent' compose --profile core exec -T api sh -c 'test -s /var/log/websec/app.jsonl'

if [[ "$profile" == observe ]]; then
  check 'Prometheus ready' curl -fsS "http://127.0.0.1:${SHOPLAB_PROM_PORT:-9090}/-/ready"
  check 'Loki ready' curl -fsS "http://127.0.0.1:${SHOPLAB_LOKI_PORT:-3100}/ready"
  check 'Grafana health' curl -fsS "http://127.0.0.1:${SHOPLAB_GRAFANA_PORT:-3000}/api/health"
  check 'OpenTelemetry running' bash -c "test -n \"$(compose --profile observe ps -q otel-collector)\""
  check 'Alloy running' bash -c "test -n \"$(compose --profile observe ps -q alloy)\""
fi

printf 'Résumé: PASS=%d FAIL=%d mode=%s profil=%s\n' "$pass" "$fail" "$(current_mode)" "$profile" | tee -a "$report"
test "$fail" -eq 0
