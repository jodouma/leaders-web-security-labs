#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"

# Keep every student-facing Compose command on the same computed project as
# lab-start/reset/cleanup, including when SHOPLAB_PROJECT is overridden.
compose "$@"
