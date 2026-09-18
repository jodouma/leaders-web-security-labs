#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"

mode=${1:-}
prepare_mode "$mode"
prepare_tls
compose --profile core up -d --force-recreate api proxy

for _ in $(seq 1 45); do
  actual=$(curl -kfsS "https://127.0.0.1:${SHOPLAB_HTTPS_PORT:-8443}/api/health" 2>/dev/null | python3 -c 'import json,sys; print(json.load(sys.stdin).get("mode", ""))' 2>/dev/null || true)
  if [[ "$actual" == "$mode" ]]; then printf '[PASS] mode %s actif\n' "$mode"; exit 0; fi
  sleep 2
done
printf '[FAIL] mode %s non confirmé\n' "$mode" >&2
exit 1
