#!/usr/bin/env bash
# shellcheck shell=bash

uninstall_agentic_tmux() {
  info "uninstalling agentic-tmux-setup..."

  remove_marker_block "$(shell_rc_for bash)"
  remove_marker_block "$(shell_rc_for zsh)"

  if [[ -e "$LOCAL_BIN/agentic-tmux" ]]; then
    info "remove: $LOCAL_BIN/agentic-tmux"
    run rm -f "$LOCAL_BIN/agentic-tmux"
  fi

  if [[ -d "${HOME}/.local/share/agentic-tmux" ]]; then
    info "remove: ${HOME}/.local/share/agentic-tmux"
    run rm -rf "${HOME}/.local/share/agentic-tmux"
  fi

  if confirm "Remove ~/.config/agentic-tmux (includes config.toml)?"; then
    if [[ -e "$AGENTIC_TMUX_CONFIG_DIR" ]]; then
      info "remove: $AGENTIC_TMUX_CONFIG_DIR"
      run rm -rf "$AGENTIC_TMUX_CONFIG_DIR"
    fi
  else
    info "keeping user config: $AGENTIC_TMUX_USER_CONFIG"
    run rm -rf "$AGENTIC_TMUX_SHELL_DIR"
    run rm -f "$AGENTIC_TMUX_CONFIG_DIR/config-reader.sh"
  fi

  if confirm "Also remove tmux.conf and worktrunk configs we installed?"; then
    run rm -f "$TMUX_CONFIG_DIR/tmux.conf"
    run rm -f "$WORKTRUNK_CONFIG_DIR/dev-layout.sh"
    run rm -f "$WORKTRUNK_CONFIG_DIR/dev-layout-cmd.sh"
    if confirm "Remove worktrunk config.toml hooks too?"; then
      run rm -f "$WORKTRUNK_CONFIG_DIR/config.toml"
    fi
  fi

  log "uninstall complete"
}
