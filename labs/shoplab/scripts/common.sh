#!/usr/bin/env bash
set -euo pipefail

LAB_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
COMPOSE_FILE="$LAB_ROOT/docker-compose.yml"
STATE_DIR="$LAB_ROOT/.state"
project_seed="shoplab-${USER:-student}-$(basename "$(dirname "$LAB_ROOT")")"
COMPOSE_PROJECT_NAME=${SHOPLAB_PROJECT:-$(printf '%s' "$project_seed" | tr -cd '[:alnum:]_-' | tr '[:upper:]' '[:lower:]')}
export COMPOSE_PROJECT_NAME

mkdir -p "$STATE_DIR/nginx" "$STATE_DIR/tls"

current_mode() {
  if [[ -f "$STATE_DIR/mode" ]]; then
    tr -d '[:space:]' < "$STATE_DIR/mode"
  else
    printf '%s' vulnerable
  fi
}

compose() {
  LAB_MODE=$(current_mode) docker compose --project-name "$COMPOSE_PROJECT_NAME" -f "$COMPOSE_FILE" "$@"
}

prepare_mode() {
  local mode=${1:-vulnerable}
  case "$mode" in vulnerable|corrected) ;; *) printf '[FAIL] mode invalide: %s\n' "$mode" >&2; return 2 ;; esac
  printf '%s\n' "$mode" > "$STATE_DIR/mode"
  cp "$LAB_ROOT/nginx/$mode.conf" "$STATE_DIR/nginx/default.conf"
}

openssl_bin() {
  # macOS ships its own TLS tooling; the classroom bootstrap installs
  # Homebrew OpenSSL 3 so the same -addext command works as on Linux.
  if [[ "$(uname -s)" == "Darwin" ]] && command -v brew >/dev/null 2>&1; then
    local candidate
    candidate="$(brew --prefix openssl@3 2>/dev/null)/bin/openssl"
    if [[ -x "$candidate" ]]; then
      printf '%s' "$candidate"
      return
    fi
  fi
  command -v openssl
}

prepare_tls() {
  if [[ ! -s "$STATE_DIR/tls/lab.crt" || ! -s "$STATE_DIR/tls/lab.key" ]]; then
    local openssl_cmd
    openssl_cmd=$(openssl_bin)
    "$openssl_cmd" req -x509 -newkey rsa:2048 -nodes -days 30 \
      -subj '/CN=websec.local/O=Leaders University Lab' \
      -addext 'subjectAltName=DNS:websec.local,DNS:localhost,IP:127.0.0.1' \
      -keyout "$STATE_DIR/tls/lab.key" -out "$STATE_DIR/tls/lab.crt" >/dev/null 2>&1
  fi
  # Rootless Docker maps the Nginx process to an unprivileged host identity.
  # This disposable lab-only key must therefore be readable through the bind
  # mount. It is generated locally, ignored by Git and never used elsewhere.
  chmod 644 "$STATE_DIR/tls/lab.key"
}
