#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"

profile=${1:-core}
if [[ ! -f "$STATE_DIR/mode" ]]; then prepare_mode vulnerable; else prepare_mode "$(current_mode)"; fi
prepare_tls

case "$profile" in
  # Compose builds a missing local image automatically. Avoid forcing a second
  # registry metadata lookup when the caller has just run the build target.
  core) compose --profile core up -d ;;
  observe) compose --profile core --profile observe up -d ;;
  *) printf 'Usage: %s [core|observe]\n' "$0" >&2; exit 2 ;;
esac

for _ in $(seq 1 60); do
  if curl -kfsS "https://127.0.0.1:${SHOPLAB_HTTPS_PORT:-8443}/api/health" >/dev/null 2>&1; then
    printf '[PASS] core prêt en mode %s\n' "$(current_mode)"
    if [[ "$profile" == observe ]]; then
      # Grafana's first local SQLite migration can take longer than the core
      # startup. Wait for all five observation components, without Internet.
      for _ in $(seq 1 120); do
        if "$(dirname "$0")/health-check.sh" observe >/dev/null 2>&1; then
          "$(dirname "$0")/health-check.sh" observe
          exit 0
        fi
        sleep 3
      done
      "$(dirname "$0")/health-check.sh" observe || true
      printf '[FAIL] timeout du profil observe\n' >&2
      exit 1
    fi
    exit 0
  fi
  sleep 2
done

compose --profile core --profile observe ps
compose logs --tail=80 api proxy >&2 || true
printf '[FAIL] timeout au démarrage\n' >&2
exit 1
