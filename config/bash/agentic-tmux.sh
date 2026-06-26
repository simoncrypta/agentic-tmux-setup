# agentic-tmux-setup shell integration (bash)
# Managed by agentic-tmux — do not edit; use ~/.config/agentic-tmux/config.toml

source "${HOME}/.config/agentic-tmux/shell/agentic-tmux.inc.sh"

if command -v wt >/dev/null 2>&1; then
  eval "$(command wt config shell init bash)"
fi
