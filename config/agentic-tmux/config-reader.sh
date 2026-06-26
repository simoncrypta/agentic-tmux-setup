# Read ~/.config/agentic-tmux/config.toml without external TOML parsers.

agentic_tmux_agent_command() {
  local config="${HOME}/.config/agentic-tmux/config.toml"
  local cmd="agent"
  if [[ -r "$config" ]]; then
    cmd="$(awk -F'"' '/^command[[:space:]]*=/ { print $2; exit }' "$config")"
  fi
  printf '%s' "${cmd:-agent}"
}

agentic_tmux_layout_editor() {
  local config="${HOME}/.config/agentic-tmux/config.toml"
  local editor="${EDITOR:-nvim}"
  if [[ -r "$config" ]]; then
    local from_config
    from_config="$(awk -F'"' '/^editor[[:space:]]*=/ { print $2; exit }' "$config")"
    [[ -n "$from_config" ]] && editor="$from_config"
  fi
  printf '%s' "$editor"
}
