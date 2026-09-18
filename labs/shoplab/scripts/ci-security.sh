#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"
: > "$STATE_DIR/security-gate.txt"

compose --profile security build security-tools
compose --profile security run --rm security-tools python -m pytest -q -p no:cacheprovider
set +e
compose --profile security run --rm security-tools bandit -q -r /workspace/app -f json -o /tmp/bandit.json
bandit_rc=$?
set -e
if [[ "$bandit_rc" -gt 1 ]]; then printf '[FAIL] Bandit execution\n' >&2; exit "$bandit_rc"; fi
if [[ "$bandit_rc" -eq 1 ]]; then printf '[WARN] Bandit a produit des findings à trier\n' >&2; fi
set +e
audit_output=$(compose --profile security run --rm security-tools pip-audit --requirement requirements.txt --progress-spinner off --cache-dir /tmp/pip-audit 2>&1)
audit_rc=$?
set -e
printf '%s\n' "$audit_output"
if [[ "$audit_rc" -ne 0 ]] && ! grep -Eq '^Found [0-9]+ known vulnerabilit' <<<"$audit_output"; then
  printf '[FAIL] pip-audit execution\n' >&2
  exit "$audit_rc"
fi
if [[ "$audit_rc" -ne 0 ]]; then printf '[WARN] pip-audit a produit des findings à trier\n' >&2; fi
compose --profile security run --rm gitleaks detect --source=/workspace --no-git --redact --exit-code=1 --config=/workspace/labs/shoplab/.gitleaks.toml
if [[ "$bandit_rc" -eq 0 && "$audit_rc" -eq 0 ]]; then
  state=PASS
else
  state=WARN
fi
printf '[%s] security gate: pytest=0, Bandit=%s, pip-audit=%s, Gitleaks=0\n' "$state" "$bandit_rc" "$audit_rc" | tee "$STATE_DIR/security-gate.txt"
