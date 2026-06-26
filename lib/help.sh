#!/usr/bin/env bash
# shellcheck shell=bash

show_help() {
  cat <<EOF
agentic-tmux-setup v${AGENTIC_TMUX_VERSION}

Install:
  curl -fsSL https://tmux.simoncrypta.dev/install.sh | bash
  curl -fsSL https://tmux.simoncrypta.dev/install.sh | bash -s -- --yes

install.sh options:
  -h, --help   Show this help
  -y, --yes    Non-interactive (skip agent prompt; use existing/default config)

Post-install CLI (agentic-tmux):
  help          This help
  doctor        Check dependencies and integration
  update        Re-sync configs from latest release
  reconfigure   Re-prompt agent command
  dry-run       Show planned actions without changes
  uninstall     Remove marker block and managed files

Shell commands:
  dev           Dev layout for current directory (attach or switch session)
  wtc [branch]  Create worktree + new tmux session
  wts [branch]  Switch to existing worktree (fzf if no branch)
  wtd [branch]  Remove worktree + kill tmux session
  d             Apply dev layout in current tmux window

Layout:
  Left 50%: agent pane (sticky) — command from ~/.config/agentic-tmux/config.toml
  Tabs: review (tuicr), explorer (nvim), terminal (shell)

Tmux keys:
  prefix+D      Apply dev layout in current session
  prefix+1        Focus agent pane
  prefix+2/3/4    review / explorer / terminal
  Alt+1/2/3       Same tab switching without prefix
  prefix+q        Reload tmux config

Config:
  ~/.config/agentic-tmux/config.toml   agent command + editor
  ~/.config/tmux/tmux.conf
  ~/.config/worktrunk/dev-layout.sh
  ~/.config/worktrunk/config.toml      worktrunk hooks
EOF
}

show_summary() {
  log ""
  log "agentic-tmux-setup installed (v${AGENTIC_TMUX_VERSION})"
  log ""
  log "Agent command: $(read_agent_command 2>/dev/null || echo agent)"
  log "Config: ${AGENTIC_TMUX_USER_CONFIG}"
  log ""
  log "Try: dev"
  log "Help: agentic-tmux help"
  log ""
}
