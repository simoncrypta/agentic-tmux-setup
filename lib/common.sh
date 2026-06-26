#!/usr/bin/env bash
# shellcheck shell=bash
set -euo pipefail

AGENTIC_TMUX_VERSION="${AGENTIC_TMUX_VERSION:-0.1.0}"
AGENTIC_TMUX_MARKER_START="# >>> agentic-tmux-setup"
AGENTIC_TMUX_MARKER_END="# <<< agentic-tmux-setup"

AGENTIC_TMUX_CONFIG_DIR="${HOME}/.config/agentic-tmux"
AGENTIC_TMUX_SHELL_DIR="${AGENTIC_TMUX_CONFIG_DIR}/shell"
AGENTIC_TMUX_USER_CONFIG="${AGENTIC_TMUX_CONFIG_DIR}/config.toml"
TMUX_CONFIG_DIR="${HOME}/.config/tmux"
WORKTRUNK_CONFIG_DIR="${HOME}/.config/worktrunk"
LOCAL_BIN="${HOME}/.local/bin"

DRY_RUN=0
YES=0
FORCE=0

log() { printf '%s\n' "$*"; }
info() { printf '→ %s\n' "$*"; }
warn() { printf 'warning: %s\n' "$*" >&2; }
die() { printf 'error: %s\n' "$*" >&2; exit 1; }

run() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    info "[dry-run] $*"
  else
    "$@"
  fi
}

confirm() {
  local prompt="$1"
  if [[ "$YES" -eq 1 ]]; then
    return 0
  fi
  printf '%s [y/N] ' "$prompt"
  local reply
  read -r reply
  [[ "$reply" =~ ^[Yy]$ ]]
}

ensure_dir() {
  run mkdir -p "$1"
}

copy_file() {
  local src="$1" dest="$2"
  ensure_dir "$(dirname "$dest")"
  if [[ -f "$dest" ]] && cmp -s "$src" "$dest" 2>/dev/null; then
    info "unchanged: $dest"
    return 0
  fi
  info "install: $dest"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    info "[dry-run] cp $src -> $dest"
    return 0
  fi
  cp "$src" "$dest"
}

script_dir() {
  local src="${BASH_SOURCE[1]:-${BASH_SOURCE[0]}}"
  while [[ -L "$src" ]]; do
    local dir
    dir="$(cd -P "$(dirname "$src")" && pwd)"
    src="$(readlink "$src")"
    [[ "$src" != /* ]] && src="$dir/$src"
  done
  cd -P "$(dirname "$src")" && pwd
}

install_src_dir() {
  if [[ -n "${INSTALL_SRC:-}" ]]; then
    printf '%s' "$INSTALL_SRC"
    return 0
  fi
  local dir
  dir="$(cd "$(script_dir)/.." && pwd)"
  if [[ -f "$dir/install.sh" && -d "$dir/config" ]]; then
    printf '%s' "$dir"
    return 0
  fi
  printf '%s' "https://tmux.simoncrypta.dev"
}

fetch_file() {
  local rel="$1" dest="$2"
  local base
  base="$(install_src_dir)"
  if [[ -d "$base" ]]; then
    copy_file "$base/$rel" "$dest"
    return 0
  fi
  ensure_dir "$(dirname "$dest")"
  local url="${base%/}/$rel"
  info "download: $url"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    return 0
  fi
  curl -fsSL "$url" -o "$dest"
}
