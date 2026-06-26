# agentic-tmux-setup shell integration (shared)
# Managed by agentic-tmux — do not edit; use ~/.config/agentic-tmux/config.toml

source "${HOME}/.config/worktrunk/dev-layout.sh"

worktree-dev() {
  local current_dir="${PWD}"
  local session_name
  session_name=$(_wt_generate_session_name "$current_dir")

  wt_dev_layout_create "$session_name" "$current_dir"

  if [[ -n "$TMUX" ]]; then
    tmux switch-client -t "$session_name"
  else
    tmux attach -t "$session_name"
  fi
}

unalias d 2>/dev/null || true
d() {
  [[ -z "$TMUX" ]] && { echo "You must be in tmux to use d."; return 1; }
  wt_dev_layout_apply "${PWD}"
}

alias dev='worktree-dev'

_wt_worktree_path_for_branch() {
  local branch="$1"
  wt list --format=json 2>/dev/null \
    | jq -r --arg branch "$branch" 'map(select(.branch == $branch)) | .[0].path'
}

_wt_branch_exists() {
  local branch="$1"
  git show-ref --verify --quiet "refs/heads/$branch" 2>/dev/null && return 0
  git ls-remote --exit-code --heads origin "$branch" >/dev/null 2>&1
}

_wt_default_branch() {
  local default_branch
  default_branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|^refs/remotes/origin/||')
  [[ -z "$default_branch" ]] && default_branch="main"
  printf '%s' "$default_branch"
}

_wt_handle_same_branch_worktree() {
  local branch="$1"
  local current_branch repo_root default_branch existing_worktree worktree_dir

  current_branch=$(git branch --show-current 2>/dev/null)
  [[ "$branch" == "$current_branch" ]] || return 1

  repo_root=$(git rev-parse --show-toplevel 2>/dev/null)
  default_branch=$(_wt_default_branch)

  echo "Current worktree is on '$branch'. Moving to '$default_branch' first..."

  existing_worktree=$(git worktree list 2>/dev/null \
    | grep "\[$branch\]" | grep -v "^$repo_root " | awk '{print $1}' | head -1)

  if [[ -n "$existing_worktree" ]]; then
    git switch "$default_branch"
    _wt_attach_tmux "$existing_worktree"
    return 0
  fi

  if ! git switch "$default_branch" 2>/dev/null; then
    echo "Cannot switch to '$default_branch'. Commit or stash changes first."
    return 1
  fi

  worktree_dir="${repo_root}.${branch}"
  if git worktree add "$worktree_dir" "$branch" 2>/dev/null; then
    _wt_attach_tmux "$worktree_dir"
    return 0
  fi

  echo "Failed to create worktree. It may already exist."
  return 1
}

_wt_switch_or_create() {
  local branch="$1"
  if _wt_branch_exists "$branch"; then
    wt switch "$branch"
  else
    wt switch --create "$branch" --base=@
  fi
}

wtc() {
  local branch="$1"
  local current_dir new_path

  current_dir=$(pwd)

  if [[ -z "$branch" ]]; then
    branch=$(git branch --show-current 2>/dev/null)
    if [[ -z "$branch" ]]; then
      echo "Could not determine current branch. Are you in a git repository?"
      return 1
    fi
  fi

  if _wt_handle_same_branch_worktree "$branch"; then
    cd "$current_dir"
    return 0
  fi

  _wt_switch_or_create "$branch"

  new_path=$(_wt_worktree_path_for_branch "$branch")
  [[ -z "$new_path" || "$new_path" == "null" ]] && new_path=$(pwd)

  _wt_attach_tmux "$new_path"
  cd "$current_dir"
}

wts() {
  local branch="$1"

  if [[ -z "$branch" ]]; then
    branch=$(wt list --format=json 2>/dev/null | jq -r '.[].branch' | fzf --header="Select worktree:" --tiebreak=index)
    [[ -z "$branch" ]] && { echo "No worktree selected"; return 1; }
  fi

  local worktree_path
  worktree_path=$(_wt_worktree_path_for_branch "$branch")

  if [[ -z "$worktree_path" || "$worktree_path" == "null" ]]; then
    echo "Worktree not found: $branch"
    return 1
  fi

  _wt_attach_tmux "$worktree_path"
}

_wt_attach_tmux() {
  local worktree_path="$1"
  local session_name
  session_name=$(_wt_generate_session_name "$worktree_path")

  wt_dev_layout_create "$session_name" "$worktree_path"

  if [[ -n "$TMUX" ]]; then
    tmux switch-client -t "$session_name"
  else
    tmux attach -t "$session_name"
  fi
}

_wt_generate_session_name() {
  local worktree_path="$1"
  local worktree_name repo_name branch

  worktree_name=$(basename "$worktree_path")

  if [[ "$worktree_name" == *.* ]]; then
    repo_name=$(echo "$worktree_name" | sed 's/\.[a-zA-Z0-9_-]*$//' | awk '{print toupper(substr($0,1,1)) tolower(substr($0,2))}')
    branch=$(echo "$worktree_name" | sed 's/^[^.]*\.//' | awk '{print toupper(substr($0,1,1)) tolower(substr($0,2))}')
  else
    repo_name=$(echo "$worktree_name" | awk '{print toupper(substr($0,1,1)) tolower(substr($0,2))}')
    branch=$(cd "$worktree_path" && git branch --show-current 2>/dev/null | awk '{print toupper(substr($0,1,1)) tolower(substr($0,2))}')
  fi

  echo "${repo_name}_${branch}"
}

wtd() {
  local branch="$1"

  if [[ -z "$branch" ]]; then
    branch=$(git branch --show-current 2>/dev/null)
    [[ -z "$branch" ]] && { echo "Usage: wtd <branch-name>"; return 1; }
  fi

  local worktree_path session_name repo_root
  worktree_path=$(_wt_worktree_path_for_branch "$branch")
  if [[ -z "$worktree_path" || "$worktree_path" == "null" ]]; then
    echo "Worktree not found: $branch"
    return 1
  fi

  session_name=$(_wt_generate_session_name "$worktree_path")

  repo_root=$(git rev-parse --show-toplevel 2>/dev/null)
  [[ -n "$repo_root" ]] && cd "$repo_root"

  wt remove "$branch" --force

  if tmux has-session -t "$session_name" 2>/dev/null; then
    tmux kill-session -t "$session_name"
  fi
}

alias wt.='wts'
