#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=lib/common.sh
source "$ROOT/lib/common.sh"
# shellcheck source=lib/detect.sh
source "$ROOT/lib/detect.sh"
# shellcheck source=lib/deps.sh
source "$ROOT/lib/deps.sh"
# shellcheck source=lib/config.sh
source "$ROOT/lib/config.sh"
# shellcheck source=lib/shell-rc.sh
source "$ROOT/lib/shell-rc.sh"
# shellcheck source=lib/uninstall.sh
source "$ROOT/lib/uninstall.sh"
# shellcheck source=lib/help.sh
source "$ROOT/lib/help.sh"

parse_install_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help)
        show_help
        exit 0
        ;;
      -y|--yes)
        YES=1
        shift
        ;;
      *)
        die "unknown option: $1 (try --help)"
        ;;
    esac
  done
}

main() {
  parse_install_args "$@"

  log "agentic-tmux-setup v${AGENTIC_TMUX_VERSION}"
  info "os: $(detect_os)/$(detect_arch) shell: $(detect_shell_name)"
  is_omarchy && info "omarchy detected"

  install_dependencies
  deploy_configs
  if ! install_shell_integration; then
    warn "shell integration was not installed — run 'agentic-tmux update' after resolving conflicts"
  fi
  show_summary
}

main "$@"
