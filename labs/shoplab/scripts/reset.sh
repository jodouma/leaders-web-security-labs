#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"

compose --profile core --profile security --profile observe down -v --remove-orphans
prepare_mode vulnerable
prepare_tls
"$(dirname "$0")/lab-start.sh" core
"$(dirname "$0")/health-check.sh" core
printf '[PASS] reset complet en mode vulnerable\n'
