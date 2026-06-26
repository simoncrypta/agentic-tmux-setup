#!/usr/bin/env bash
# Thin tmux run-shell entrypoint for dev-layout functions.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/dev-layout.sh"

cmd="$1"
shift
"$cmd" "$@"
