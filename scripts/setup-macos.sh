#!/usr/bin/env bash
set -euo pipefail
mode=${1:---check}
pass(){ printf '[PASS] %s\n' "$*"; }
warn(){ printf '[WARN] %s\n' "$*" >&2; }
fail(){ printf '[FAIL] %s\n' "$*" >&2; exit 1; }
has(){ command -v "$1" >/dev/null 2>&1; }
[[ "$mode" == --check || "$mode" == --install ]] || fail 'usage: setup-macos.sh [--check|--install]'
[[ $(uname -s) == Darwin ]] || fail 'script réservé à macOS'
has brew || fail 'Homebrew requis: https://brew.sh/'
if [[ "$mode" == --install ]]; then
  packages=(git curl jq openssl@3 colima docker docker-compose docker-buildx)
  for pkg in "${packages[@]}"; do brew list "$pkg" >/dev/null 2>&1 || brew install "$pkg"; done
  plugin_dir="${HOME:?}/.docker/cli-plugins"
  mkdir -p "$plugin_dir"
  prefix=$(brew --prefix)
  for plugin in docker-compose docker-buildx; do
    source_path="$prefix/lib/docker/cli-plugins/$plugin"
    [[ -e "$source_path" ]] && ln -sfn "$source_path" "$plugin_dir/$plugin"
  done
  colima status >/dev/null 2>&1 || colima start --cpu 2 --memory 4 --disk 20
fi
for cmd in git curl jq python3 docker colima; do
  if has "$cmd"; then pass "$cmd présent"; else fail "$cmd absent; utiliser --install"; fi
done
if colima status >/dev/null 2>&1; then pass 'Colima actif'; else fail 'Colima arrêté'; fi
if docker compose version >/dev/null 2>&1; then pass 'Compose v2 présent'; else fail 'Compose v2 absent'; fi
pass 'setup idempotent terminé; exécuter verify-host.sh'
