# Dev layout: sticky agent pane (left 50%) + tool windows (status-bar tabs)
#   review   — tuicr
#   explorer — nvim (or layout.editor from ~/.config/agentic-tmux/config.toml)
#   terminal — shell
# Agent is a pane joined to the active tool window (not a tab).
#
# Usage:
#   wt_dev_layout_create <session> <workdir>
#   wt_dev_layout_apply [<workdir>] [<session>]
#   wt_dev_select_tab <agent|review|explorer|terminal> [<workdir>] [<session>]
#   wt_dev_focus_agent [<session>]
#   wt_dev_on_window_select                         — hook: keep agent attached

[[ -n "${WT_DEV_LAYOUT_LOADED:-}" ]] && return 0
WT_DEV_LAYOUT_LOADED=1
WT_DEV_LAYOUT_VERSION=2

# shellcheck disable=SC1091
[[ -r "${HOME}/.config/agentic-tmux/config-reader.sh" ]] \
  && source "${HOME}/.config/agentic-tmux/config-reader.sh"

_wt_dev_agent_cmd() {
  if declare -F agentic_tmux_agent_command >/dev/null 2>&1; then
    agentic_tmux_agent_command
  else
    printf '%s' "agent"
  fi
}

_wt_dev_editor() {
  if declare -F agentic_tmux_layout_editor >/dev/null 2>&1; then
    agentic_tmux_layout_editor
  else
    printf '%s' "${EDITOR:-nvim}"
  fi
}

_wt_dev_normalize_tab() {
  case "${1:-review}" in
    review|explorer|terminal) printf '%s' "$1" ;;
    *) printf '%s' review ;;
  esac
}

_wt_dev_session_name() {
  local session_name="${1:-}"
  if [[ -z "$session_name" ]]; then
    if [[ -n "$TMUX" ]]; then
      session_name=$(tmux display-message -p '#{session_name}')
    else
      session_name=$(tmux display-message -p '#{session_name}' 2>/dev/null) || return 1
    fi
  fi
  printf '%s' "$session_name"
}

_wt_dev_workdir() {
  local session_name="$1"
  local workdir="${2:-}"
  if [[ -z "$workdir" ]]; then
    workdir=$(tmux show-options -v -t "$session_name" @wt-dev-workdir 2>/dev/null) || true
  fi
  printf '%s' "${workdir:-$PWD}"
}

_wt_dev_window_exists() {
  local session_name="$1"
  local window_name="$2"
  tmux list-windows -t "$session_name" -F '#{window_name}' 2>/dev/null \
    | grep -qx "$window_name"
}

_wt_dev_tool_shell_command() {
  local window_name="$1"
  local editor
  editor="$(_wt_dev_editor)"
  case "$window_name" in
    review)
      printf '%s' "tuicr; exec bash -li"
      ;;
    explorer)
      printf '%s' "${editor} .; exec bash -li"
      ;;
    terminal)
      printf '%s' "clear; exec bash -li"
      ;;
    *)
      return 1
      ;;
  esac
}

_wt_dev_has_agent_pane() {
  local session_name="$1"
  local pane
  pane=$(tmux show-options -v -t "$session_name" @wt-dev-agent-pane 2>/dev/null) || return 1
  tmux display-message -p -t "$pane" '#{pane_id}' &>/dev/null
}

_wt_dev_agent_pane() {
  local session_name="$1"
  local pane
  pane=$(tmux show-options -v -t "$session_name" @wt-dev-agent-pane 2>/dev/null) || return 1
  if tmux display-message -p -t "$pane" '#{pane_id}' &>/dev/null; then
    printf '%s' "$pane"
    return 0
  fi
  return 1
}

_wt_dev_tool_pane() {
  local session_name="$1"
  local window_name="$2"
  local agent_pane="${3:-}"
  local pane

  [[ -n "$agent_pane" ]] || agent_pane=$(_wt_dev_agent_pane "$session_name") || true

  while IFS= read -r pane; do
    if [[ -z "$agent_pane" || "$pane" != "$agent_pane" ]]; then
      printf '%s' "$pane"
      return 0
    fi
  done < <(tmux list-panes -t "$session_name:$window_name" -F '#{pane_id}')

  return 1
}

_wt_dev_start_agent_pane() {
  local session_name="$1"
  local workdir="$2"
  local tool_pane="$3"
  local agent_pane agent_cmd

  agent_cmd="$(_wt_dev_agent_cmd)"
  agent_pane=$(tmux split-window -h -b -p 50 -t "$tool_pane" -c "$workdir" -P -F '#{pane_id}' bash -li)
  sleep 0.2
  tmux send-keys -t "$agent_pane" "$agent_cmd" Enter
  tmux set-option -t "$session_name" @wt-dev-agent-pane "$agent_pane"
}

_wt_dev_attach_agent() {
  local session_name="$1"
  local window_name="$2"
  local agent_pane tool_pane agent_win target_win

  agent_pane=$(_wt_dev_agent_pane "$session_name") || return 1
  tool_pane=$(_wt_dev_tool_pane "$session_name" "$window_name" "$agent_pane") || return 1

  agent_win=$(tmux display-message -p -t "$agent_pane" '#{window_index}')
  target_win=$(tmux display-message -p -t "$session_name:$window_name" '#{window_index}')

  if [[ "$agent_win" == "$target_win" ]]; then
    return 0
  fi

  tmux join-pane -h -b -l 50% -s "$agent_pane" -t "$tool_pane"
}

_wt_dev_ensure_window() {
  local session_name="$1"
  local window_name="$2"
  local workdir="$3"
  local shell_cmd="${4:-}"

  if _wt_dev_window_exists "$session_name" "$window_name"; then
    return 0
  fi

  [[ -n "$shell_cmd" ]] || shell_cmd=$(_wt_dev_tool_shell_command "$window_name")
  tmux new-window -t "$session_name" -c "$workdir" -n "$window_name" \
    bash -li -c "$shell_cmd"
  tmux set-window-option -t "$session_name:$window_name" automatic-rename off
}

_wt_dev_migrate_legacy_layout() {
  local session_name="$1"
  local workdir="$2"
  local window_target right_pane agent_pane tab

  window_target=""
  while IFS= read -r line; do
    local target=${line#* }
    if tmux show-options -w -v -t "$target" @wt-dev-right-pane &>/dev/null; then
      window_target=$target
      break
    fi
  done < <(tmux list-windows -t "$session_name" -F '#{window_name} #{session_name}:#{window_index}')

  if [[ -n "$window_target" ]]; then
    right_pane=$(tmux show-options -w -v -t "$window_target" @wt-dev-right-pane 2>/dev/null) || true
    agent_pane=$(tmux list-panes -t "$window_target" -F '#{pane_id}' | head -1)
    if [[ -n "$right_pane" && "$right_pane" != @* ]]; then
      tmux kill-pane -t "$right_pane" 2>/dev/null || true
    fi
    tmux unset-window-option -t "$window_target" @wt-dev-right-pane 2>/dev/null || true
    tmux rename-window -t "$window_target" review 2>/dev/null || true
    tmux set-option -t "$session_name" @wt-dev-agent-pane "$agent_pane"
    tmux set-window-option -t "$window_target" automatic-rename off
  fi

  if _wt_dev_window_exists "$session_name" agent && ! _wt_dev_has_agent_pane "$session_name"; then
    agent_pane=$(tmux list-panes -t "$session_name:agent" -F '#{pane_id}' | head -1)
    tmux set-option -t "$session_name" @wt-dev-agent-pane "$agent_pane"
    _wt_dev_ensure_window "$session_name" review "$workdir"
    _wt_dev_attach_agent "$session_name" review
    tmux kill-window -t "$session_name:agent" 2>/dev/null || true
  fi

  if _wt_dev_has_agent_pane "$session_name"; then
    tab=$(tmux show-options -v -t "$session_name" @wt-dev-tab 2>/dev/null) || tab=review
    tab=$(_wt_dev_normalize_tab "$tab")
    if _wt_dev_window_exists "$session_name" "$tab"; then
      _wt_dev_attach_agent "$session_name" "$tab"
    fi
  fi
}

_wt_dev_maybe_migrate() {
  local session_name="$1"
  local workdir="$2"
  local version

  version=$(tmux show-options -v -t "$session_name" @wt-dev-layout-version 2>/dev/null) || version=0
  [[ "$version" -ge "$WT_DEV_LAYOUT_VERSION" ]] && return 0

  _wt_dev_migrate_legacy_layout "$session_name" "$workdir"
  tmux set-option -t "$session_name" @wt-dev-layout-version "$WT_DEV_LAYOUT_VERSION"
}

_wt_dev_layout_ensure() {
  local session_name="$1"
  local workdir="$2"
  local tool_pane

  _wt_dev_maybe_migrate "$session_name" "$workdir"
  tmux set-option -t "$session_name" @wt-dev-workdir "$workdir"

  _wt_dev_ensure_window "$session_name" review "$workdir"
  _wt_dev_ensure_window "$session_name" explorer "$workdir"
  _wt_dev_ensure_window "$session_name" terminal "$workdir"

  if ! _wt_dev_has_agent_pane "$session_name"; then
    tool_pane=$(_wt_dev_tool_pane "$session_name" review) || return 1
    _wt_dev_start_agent_pane "$session_name" "$workdir" "$tool_pane" >/dev/null
    _wt_dev_attach_agent "$session_name" review
  fi
}

wt_dev_focus_agent() {
  local session_name
  session_name=$(_wt_dev_session_name "${1:-}") || return 1
  local agent_pane tab

  _wt_dev_layout_ensure "$session_name" "$(_wt_dev_workdir "$session_name")" || return 1
  agent_pane=$(_wt_dev_agent_pane "$session_name") || return 1

  tab=$(tmux show-options -v -t "$session_name" @wt-dev-tab 2>/dev/null) || tab=review
  tab=$(_wt_dev_normalize_tab "$tab")

  _wt_dev_attach_agent "$session_name" "$tab"
  tmux select-window -t "$session_name:$tab"
  tmux select-pane -t "$agent_pane"
}

wt_dev_select_tab() {
  local tab="$1"
  local workdir="${2:-}"
  local session_name
  session_name=$(_wt_dev_session_name "${3:-}") || return 1
  workdir=$(_wt_dev_workdir "$session_name" "$workdir")

  local window_name tool_pane
  case "$tab" in
    agent|a|0)
      wt_dev_focus_agent "$session_name"
      return 0
      ;;
    review|r|1) window_name=review ;;
    explorer|e|2) window_name=explorer ;;
    terminal|t|3|4) window_name=terminal ;;
    *)
      return 1
      ;;
  esac

  _wt_dev_layout_ensure "$session_name" "$workdir"
  _wt_dev_attach_agent "$session_name" "$window_name"

  tool_pane=$(_wt_dev_tool_pane "$session_name" "$window_name") || return 1
  tmux select-window -t "$session_name:$window_name"
  tmux select-pane -t "$tool_pane"
  tmux set-option -t "$session_name" @wt-dev-tab "$window_name"
}

wt_dev_on_window_select() {
  local session_name="${1:-}"
  local window_name="${2:-}"
  local tool_pane

  [[ -n "$session_name" ]] || session_name=$(_wt_dev_session_name) || return 0
  [[ -n "$window_name" ]] || window_name=$(tmux display-message -p -t "$session_name" '#{window_name}' 2>/dev/null) || return 0

  _wt_dev_has_agent_pane "$session_name" || return 0

  case "$window_name" in
    review|explorer|terminal) ;;
    *) return 0 ;;
  esac

  _wt_dev_attach_agent "$session_name" "$window_name"
  tool_pane=$(_wt_dev_tool_pane "$session_name" "$window_name") || return 0
  tmux select-pane -t "$tool_pane"
  tmux set-option -t "$session_name" @wt-dev-tab "$window_name"
}

wt_dev_layout_apply() {
  local workdir="${1:-$PWD}"
  local session_name
  session_name=$(_wt_dev_session_name "${2:-}") || return 1
  workdir=$(_wt_dev_workdir "$session_name" "$workdir")

  _wt_dev_layout_ensure "$session_name" "$workdir"
  wt_dev_select_tab review "$workdir" "$session_name"
}

wt_dev_layout_create() {
  local session_name="$1"
  local workdir="$2"

  if tmux has-session -t "$session_name" 2>/dev/null; then
    _wt_dev_layout_ensure "$session_name" "$workdir"
    return 0
  fi

  tmux new-session -d -s "$session_name" -c "$workdir" -n review \
    bash -li -c "tuicr; exec bash -li"
  tmux set-window-option -t "$session_name:review" automatic-rename off
  tmux set-option -t "$session_name" @wt-dev-workdir "$workdir"
  tmux set-option -t "$session_name" @wt-dev-tab review
  tmux set-option -t "$session_name" @wt-dev-layout-version "$WT_DEV_LAYOUT_VERSION"

  _wt_dev_layout_ensure "$session_name" "$workdir"
  wt_dev_select_tab review "$workdir" "$session_name"
}
