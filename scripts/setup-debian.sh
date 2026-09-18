#!/usr/bin/env bash
set -euo pipefail
mode=${1:---check}
pass(){ printf '[PASS] %s\n' "$*"; }
warn(){ printf '[WARN] %s\n' "$*" >&2; }
fail(){ printf '[FAIL] %s\n' "$*" >&2; exit 1; }
has(){ command -v "$1" >/dev/null 2>&1; }
[[ "$mode" == --check || "$mode" == --install ]] || fail 'usage: setup-debian.sh [--check|--install]'
[[ $(uname -s) == Linux ]] || fail 'script réservé à Linux/WSL2'
[[ -r /etc/os-release ]] || fail '/etc/os-release absent'
# shellcheck disable=SC1091
. /etc/os-release
case "${ID:-}" in ubuntu|debian|kali) pass "distribution ${ID} ${VERSION_ID:-rolling}";; *) fail "distribution ${ID:-inconnue} non supportée";; esac

if [[ "$mode" == --install ]]; then
  has apt-get || fail 'apt-get absent'
  sudo apt-get update
  sudo apt-get install -y ca-certificates curl git jq openssl python3 python3-venv
  if ! has docker; then sudo apt-get install -y docker.io; fi
  if ! docker compose version >/dev/null 2>&1; then
    if apt-cache show docker-compose-v2 >/dev/null 2>&1; then sudo apt-get install -y docker-compose-v2
    elif apt-cache show docker-compose-plugin >/dev/null 2>&1; then sudo apt-get install -y docker-compose-plugin
    else warn 'plugin Compose v2 absent des dépôts; suivre la documentation de la distribution'; fi
  fi
  if has systemctl && [[ ! -f /proc/sys/fs/binfmt_misc/WSLInterop ]]; then sudo systemctl enable --now docker || warn 'service Docker à démarrer manuellement'; fi
  if getent group docker >/dev/null && ! id -nG | tr ' ' '\n' | grep -qx docker; then
    sudo usermod -aG docker "${USER:?}"
    warn 'groupe docker ajouté; une nouvelle session est requise avant accès sans sudo'
  fi
fi

for cmd in git curl jq openssl python3 docker; do
  if has "$cmd"; then pass "$cmd présent"; else fail "$cmd absent; utiliser --install"; fi
done
if docker compose version >/dev/null 2>&1; then pass 'Compose v2 présent'; else fail 'Compose v2 absent'; fi
pass 'setup idempotent terminé; exécuter verify-host.sh'
