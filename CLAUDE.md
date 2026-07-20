# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Personal dotfiles + dev-env provisioner. Bash scripts that copy configs into `$XDG_CONFIG_HOME` and `$HOME`, plus per-tool installer scripts. Not an application — no build, no tests.

For a user-facing overview see `README.md`.

## Required environment variables

Both must be exported before running any script:

- `DEV_ENV` — absolute path to this repo
- `WS` — workstation kind, one of: `mac`, `linux`, `server`, `waiv`, `etri`, `q`

`XDG_CONFIG_HOME` defaults to `$HOME/.config` if unset.

## Common commands

```bash
./init                    # init git submodules (nvim lives at env/base/.config/nvim)
./dev-env --dry           # preview what will be copied (no changes)
./dev-env                 # apply dotfiles for $WS
./run                     # run all installer scripts in runs/
./run tmux                # substring-filter: only basenames matching "tmux"
./run --dry               # preview
./run _brew               # mac bootstrap: install Homebrew if missing
shellcheck dev-env init run runs/*    # lint
```

## Architecture

### Layered overlay model (since the restructure)

`env/` is composed from layers. `dev-env` reads `$WS`, looks up an ordered
layer list in the `WS_LAYERS` map, and applies them in order via
`apply_layer`. Later layers overwrite earlier ones.

```
env/
  base/              # ALWAYS applied; bare-server safe
  desktop/
    common/          # GUI shared by mac + linux personal (sioyek, cava)
    mac/             # mac-only GUI (aerospace, karabiner, yabai, ...)
    linux/           # linux-only GUI (i3, picom, rofi, ...)
  host/
    server/  waiv/  etri/  q/    # per-headless-host overrides
```

`WS_LAYERS` is the **single source of truth** for what gets applied where:

```bash
declare -A WS_LAYERS=(
  [mac]="base desktop/common desktop/mac"
  [linux]="base desktop/common desktop/linux"
  [server]="base host/server"
  [waiv]="base host/waiv"
  [etri]="base host/etri"
  [q]="base host/q"
)
```

For `WS=q`, the script appends `$DEV_ENV/workdev/env` (an external
private-creds repo) as a final layer when the directory exists. `dev-env`
errors loud if `$DEV_ENV/workdev` is missing.

### Copy semantics inside `apply_layer`

Two strategies, both logged per file with the owning layer name so the
provenance of any installed file is greppable:

- **`.config/<tool>/`** — wipe-and-replace the whole tool dir. Each tool
  dir is owned by exactly one layer. Atomic — no stale files.
- **Everything else** — file-level mirror at arbitrary depth, layers
  compose. Used for top-level dotfiles, `.local/scripts/*`, and deeply
  nested singletons like `.oh-my-zsh/custom/<theme>`.

`.gitkeep` files are filtered from the mirror so empty host layers (q)
don't leak files into `$HOME`.

### etri is special — use `dev-env-etri`, not `dev-env`

`etri` is a **shared multi-user box**. Its dotfiles must NOT land in `$HOME`
(not ours to fill) and must be **symlinks**, not copies. So etri is
provisioned by a separate script:

```bash
DEV_ENV=... ./dev-env-etri --dry   # preview
DEV_ENV=... ./dev-env-etri         # apply
```

Differences from `dev-env`:

- Target is `$DOTHOME` (defaults to `$ZDOTDIR`, i.e. `~/.trungdt-config`),
  not `$HOME`. The login shell sets `ZDOTDIR=$DOTHOME` so zsh reads
  `$DOTHOME/.zshrc` etc.
- Symlinks (`ln -sfn`) not copies — edits in the repo are live.
- `env/host/etri/.zshenv` sets `XDG_CONFIG_HOME=$ZDOTDIR/.config`,
  `DEV_ENV`, and `ZSH_CUSTOM=$ZDOTDIR/.oh-my-zsh/custom` **before** the rc
  files run. Base `.zshrc`/`.zsh_profile` therefore use
  `${ZDOTDIR:-$HOME}` and `${VAR:-default}` so they resolve on both etri
  and normal hosts.
- `~/.oh-my-zsh` is shared; the custom theme is isolated under
  `$ZSH_CUSTOM/themes/` and shared plugins are symlinked back in.

`WS=etri` still exists in `WS_LAYERS` for completeness, but running plain
`dev-env` on etri would copy into `$HOME` — don't; use `dev-env-etri`.

### Safety rails

- `set -euo pipefail` everywhere.
- `safe_rm` helper inside `dev-env` refuses to remove empty / `/` / `$HOME`.
- All paths quoted (shellcheck-clean apart from one expected `SC1091` in
  `runs/docker`).

### `runs/` is platform-dispatched

Every `runs/*` script branches on `uname -s`:

- Linux → apt or static-binary download (sudo-free where possible since
  remote servers may lack sudo).
- Darwin → `brew install` (or `brew install --cask`). Mac branches in
  scripts other than `_brew` assume Homebrew is on `PATH` — run
  `./run _brew` first on a fresh mac.
- Desktop-only tools (`i3`, `rofi`) exit 0 with a `[skip]` message on mac.

`runs/_brew` sorts first alphabetically (leading underscore) so `./run`
without a filter installs Homebrew before any mac branch needs it.

## Conventions

- **Adding a workstation kind**: add a key to `WS_LAYERS` in `dev-env`.
  Create `env/host/<ws>/` with the overrides you need. No other code edit.
- **Adding a new installer**: drop an executable script in `runs/`. Picked
  up automatically by `./run`.
- **Adding new dotfiles**: drop the file in the appropriate layer mirroring
  its `$HOME` path (`env/base/.zshrc` → `$HOME/.zshrc`).
- **Editing dotfiles**: edit in the repo, then re-run `./dev-env`. Direct
  edits in `$HOME` are deliberately throwaway — copy strategy is
  source-of-truth-in-repo. This is intentional (avoids accidental commits,
  survives repo move / editor write-via-rename / cross-filesystem).
- The `./run` grep filter is **substring**, not exact — `./run zsh` runs
  both `runs/zsh` and `runs/zsh_plugins`. Intentional.
- `.gitignore` only carries `env/base/.config/tmp/` (local scratch).

## Things to know before touching `dev-env`

- The `tmp/` subdir under `env/base/.config/` is local scratch, gitignored.
  Don't track contents — `apply_layer` will still copy it to
  `$XDG_CONFIG_HOME/tmp` since the dir exists locally.
- The nvim submodule lives at `env/base/.config/nvim` (was
  `env/.config/nvim` pre-restructure; both `.gitmodules` and `.git/config`
  reflect the new path).
- `host/waiv/` carries a copy of `.gitconfig.local` rather than reusing
  the server's via symlink. Kept simple — file is tiny.
- `host/etri/` and `host/q/` are empty real layers with `.gitkeep` so
  per-host configs can be added later without code changes. `apply_layer`
  no-ops on empty layers.
