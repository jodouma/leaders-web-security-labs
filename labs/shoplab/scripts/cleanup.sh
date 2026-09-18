#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"

compose --profile core --profile security --profile observe down -v --remove-orphans
rm -rf -- "$STATE_DIR"
printf '[PASS] ressources Compose, volumes et état local jetable supprimés\n'
