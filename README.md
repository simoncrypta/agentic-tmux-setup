# agentic-tmux-setup

Shareable tmux + worktrunk dev layout for agentic coding workflows. Works on **Omarchy** (Linux) and **macOS**.

## Quick install

```bash
curl -fsSL https://tmux.simoncrypta.dev/install.sh | bash
```

Non-interactive (skip agent prompt):

```bash
curl -fsSL https://tmux.simoncrypta.dev/install.sh | bash -s -- --yes
```

From a local clone:

```bash
cd /path/to/agentic-tmux-setup
./install.sh
```

## What you get

- **tmux layout**: sticky agent pane (left) + tabs for review (`tuicr`), explorer (`nvim`), terminal
- **Shell commands**: `dev`, `wtc`, `wts`, `wtd`, `d`
- **worktrunk hooks**: auto-create/kill tmux sessions on worktree start/remove
- **Config**: `~/.config/agentic-tmux/config.toml` (agent command + editor)

### First-run prompt

On install you'll pick the agent pane command:

1. `agent`
2. `codex`
3. `opencode`
4. `claude`
5. custom

Saved to `~/.config/agentic-tmux/config.toml`. Change later with `agentic-tmux reconfigure`.

## Shell commands

| Command | Description |
|---------|-------------|
| `dev` | Dev layout for current directory |
| `wtc [branch]` | Create worktree + new tmux session |
| `wts [branch]` | Switch to existing worktree (fzf picker) |
| `wtd [branch]` | Remove worktree + kill tmux session |
| `d` | Apply layout in current tmux window |

## Tmux keys

| Key | Action |
|-----|--------|
| `prefix+D` | Apply dev layout |
| `prefix+1` | Focus agent pane |
| `prefix+2/3/4` | review / explorer / terminal |
| `Alt+1/2/3` | Same tabs without prefix |
| `prefix+q` | Reload tmux config |

Prefix is `Ctrl-Space` (fallback `Ctrl-b`).

## Post-install CLI

```bash
agentic-tmux help         # full reference
agentic-tmux doctor       # check deps + integration
agentic-tmux update       # re-sync configs
agentic-tmux reconfigure  # change agent command
agentic-tmux dry-run      # preview changes
agentic-tmux uninstall    # remove integration
```

## Dependencies

Installed only if missing (brew or system packages — **no mise required**):

- tmux, git, worktrunk (`wt`), fzf, jq, tuicr
- nvim with [LazyVim](https://www.lazyvim.org/) and neo-tree (explorer tab)
- lazygit (used from LazyVim or standalone)

## Files installed

```
~/.config/agentic-tmux/config.toml
~/.config/agentic-tmux/shell/agentic-tmux.{sh,zsh,inc.sh}
~/.config/tmux/tmux.conf
~/.config/worktrunk/dev-layout.{sh,cmd.sh}
~/.config/worktrunk/config.toml   (only if not already present)
~/.local/bin/agentic-tmux
~/.local/share/agentic-tmux/lib/  (for CLI)
```

Shell rc gets a fenced marker block in `~/.bashrc` and/or `~/.zshrc`.

## Cloudflare hosting

Static site on Cloudflare Pages (`tmux.simoncrypta.dev`). Deploy from this repo — no GitHub Actions deploy step.

1. Create the Pages project in Cloudflare (or use an existing one named `agentic-tmux-setup`)
2. Authenticate once: `npx wrangler login`
3. Deploy:

```bash
npm install
npm run deploy
```

`npm run deploy` runs `wrangler pages deploy` using `wrangler.toml` at the repo root (`pages_build_output_dir = "."`).

Custom domain: set `tmux.simoncrypta.dev` on the Pages project in the Cloudflare dashboard.

GitHub Actions only runs shellcheck (`.github/workflows/ci.yml`).

## Development

```bash
# optional contributor tooling
mise install

shellcheck install.sh lib/*.sh bin/agentic-tmux config/shell/agentic-tmux.inc.sh
./install.sh --help
agentic-tmux dry-run
npm run deploy   # publish to Cloudflare Pages
```

## License

MIT — see [LICENSE](LICENSE).
