#!/usr/bin/env bash
# shellcheck shell=bash

detect_os() {
  case "$(uname -s)" in
    Darwin) printf 'macos' ;;
    Linux) printf 'linux' ;;
    *) printf 'unknown' ;;
  esac
}

detect_arch() {
  uname -m
}

detect_shell_name() {
  basename "${SHELL:-/bin/bash}"
}

is_omarchy() {
  [[ -d "${HOME}/.local/share/omarchy" ]]
}

has_brew() {
  command -v brew >/dev/null 2>&1
}

brew_shellenv_snippet() {
  if [[ -x /opt/homebrew/bin/brew ]]; then
    printf '%s\n' 'eval "$(/opt/homebrew/bin/brew shellenv)"'
  elif [[ -x /usr/local/bin/brew ]]; then
    printf '%s\n' 'eval "$(/usr/local/bin/brew shellenv)"'
  elif [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
    printf '%s\n' 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"'
  fi
}

has_marker_block() {
  local file="$1"
  [[ -f "$file" ]] && grep -qF "$AGENTIC_TMUX_MARKER_START" "$file"
}

shell_rc_for() {
  local shell_name="$1"
  case "$shell_name" in
    zsh) printf '%s' "${HOME}/.zshrc" ;;
    bash) printf '%s' "${HOME}/.bashrc" ;;
    *) printf '%s' "${HOME}/.${shell_name}rc" ;;
  esac
}

detect_conflicts() {
  local rc="$1"
  [[ -f "$rc" ]] || return 0
  local conflicts=()
  if grep -qE 'worktree-dev\(\)|function worktree-dev' "$rc" \
    && ! grep -qF "$AGENTIC_TMUX_MARKER_START" "$rc"; then
    conflicts+=("existing worktree-dev() outside agentic-tmux marker")
  fi
  if grep -q 'source.*dev-layout\.sh' "$rc" \
    && ! grep -qF "$AGENTIC_TMUX_MARKER_START" "$rc"; then
    conflicts+=("existing dev-layout.sh source outside agentic-tmux marker")
  fi
  if ((${#conflicts[@]} > 0)); then
    printf '%s\n' "${conflicts[@]}"
    return 1
  fi
  return 0
}
