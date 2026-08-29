# dev

Personal dotfiles + dev-environment provisioner. Bash-only — no application
code, no build, no tests.

## Required environment variables

Both must be exported before running anything:

| Var          | Meaning                                  |
| ------------ | ---------------------------------------- |
| `DEV_ENV`    | Absolute path to this repo.              |
| `WS`         | Workstation kind: `mac`, `linux`, `server`, `waiv`, `waiv_workstation`, `etri`, `q`. |

`XDG_CONFIG_HOME` defaults to `$HOME/.config` if unset.

## Quickstart

Fresh box (Ubuntu):

```bash
sudo apt update && sudo apt install -y git
git clone https://github.com/bomcon123456/dev "$HOME/personal/dev"
cd "$HOME/personal/dev"

export DEV_ENV="$(pwd)"
export WS=linux          # or mac / server / waiv / waiv_workstation / etri / q

./init                   # init nvim submodule
./dev-env --dry          # preview what will be copied
./dev-env                # apply

./run _brew              # mac only — bootstrap Homebrew
./run                    # install all CLI tools
./run fonts              # install fonts referenced by configs
./run tmux               # filter: run only scripts whose basename matches
```

## Architecture

Three layers, composed by `WS`:

```
env/
  base/              # ALWAYS applied; safe on a bare server
    .config/         # nvim, tmux, yazi, btop, lazygit, ...
    .local/scripts/
    .zshrc, .gitconfig, .tmux.conf, .zsh_aliases, ...
    .oh-my-zsh/custom/robbyrussell.zsh-theme

  desktop/
    common/          # GUI shared between mac and linux personal (sioyek, cava)
    mac/             # mac-only GUI (aerospace, karabiner, sketchybar, yabai, ...)
    linux/           # linux-only GUI (i3, picom, rofi, dunst, cava, ghostty)

  host/              # per-host tweaks
    server/  waiv/  etri/  q/       # headless boxes
    waiv_workstation/               # Hyprland/Wayland desktop — NOT headless
                                    # (hypr, waybar, rofi, mako, ghostty)
```

Workstation → ordered layer list is the single source of truth at the top
of `dev-env`:

```bash
declare -A WS_LAYERS=(
  [mac]="base desktop/common desktop/mac"
  [linux]="base desktop/common desktop/linux"
  [server]="base host/server"
  [waiv]="base host/waiv"
  [waiv_workstation]="base desktop/common host/waiv_workstation"
  [etri]="base host/etri"
  [q]="base host/q"
)
```

Later layers overwrite earlier ones for any colliding file. Q appends its
external `$DEV_ENV/workdev/env` (a separate private-creds repo) as a final
layer when present.

### Copy semantics

`apply_layer` uses two different strategies, both logged per file with the
owning layer:

| Source path        | Strategy                                                                 |
| ------------------ | ------------------------------------------------------------------------ |
| `.config/<tool>/`  | **Wipe-and-replace** the whole tool dir. One layer owns the tool.        |
| Everything else    | **File-level mirror** at arbitrary depth. Layers compose; last wins.     |

The second case covers top-level dotfiles, `.local/scripts/*`, and deeply
nested singletons like `.oh-my-zsh/custom/<theme>`.

### Safety rails

- `set -euo pipefail` in every script.
- `safe_rm` refuses empty, `/`, or `$HOME` targets.
- All paths quoted (shellcheck-clean).

## Adding things

| Task                                | Steps                                                                                        |
| ----------------------------------- | -------------------------------------------------------------------------------------------- |
| New CLI tool installer              | Drop an executable script in `runs/`. Picked up automatically.                               |
| New workstation kind                | Add a key to `WS_LAYERS` in `dev-env`. Drop overrides in `env/host/<ws>/` if needed.         |
| New shared dotfile                  | Drop it in `env/base/` mirroring its `$HOME` path.                                           |
| New mac-only or linux-only config   | Drop it under `env/desktop/mac/` or `env/desktop/linux/` (also mirroring `$HOME`).           |
| New per-host override               | Drop it under `env/host/<ws>/` mirroring `$HOME`.                                            |

## `runs/` reference

| Script         | Linux                        | Mac                            |
| -------------- | ---------------------------- | ------------------------------ |
| `_brew`        | skip                         | install Homebrew if missing    |
| `conda`        | Miniconda x86_64 / aarch64   | Miniconda x86_64 / arm64       |
| `docker`       | apt (idempotent)             | `brew install --cask docker`   |
| `fonts`        | Nerd Fonts + standalone fonts to `~/.local/share/fonts` | same to `~/Library/Fonts` |
| `fzf`          | `git clone` + install        | same                           |
| `ghostty`      | upstream installer           | `brew install --cask ghostty`  |
| `hyprland`     | apt: hyprland + waybar + rofi + mako + session tools | skip     |
| `keyd`         | apt + /etc/keyd/default.conf (Caps: tap=Esc, hold=Ctrl) | skip |
| `i3`           | apt                          | skip                           |
| `libs`         | apt: ripgrep jq tldr ...     | brew: ripgrep jq tldr          |
| `node`         | nvm + lts                    | same                           |
| `rofi`         | apt                          | skip                           |
| `tmux`         | apt                          | brew                           |
| `tools`        | static binaries from GitHub releases (no sudo) | brew installs everything |
| `zsh`          | apt + chsh                   | chsh (built-in)                |
| `zsh_plugins`  | oh-my-zsh + plugins          | same                           |

## Hyprland desktop (`WS=waiv_workstation`)

Ubuntu 26.04 Wayland desktop. Everything comes from Ubuntu `universe` — no
PPA, no source build.

```bash
./run hyprland                        # apt-install compositor, bar, launcher
export WS=waiv_workstation
./dev-env                             # install the configs
# log out -> gear menu at the login screen -> "Hyprland"
```

GNOME is left completely alone and stays the default session; Hyprland is just
an extra entry at login.

**Pick "Hyprland (uwsm-managed)" at the login screen, not plain "Hyprland".**
The plain entry never activates `graphical-session.target` (that target refuses
manual start and must be pulled in by a session unit), so the desktop portals
never come up properly and the first GTK app of each session hangs for 120s on
a D-Bus activation timeout. uwsm binds the target correctly.

| Piece         | Tool            | Config                                    |
| ------------- | --------------- | ----------------------------------------- |
| compositor    | Hyprland        | `.config/hypr/hyprland.conf`              |
| bar           | waybar          | `.config/waybar/{config.jsonc,style.css}` |
| launcher      | rofi 2.0        | `.config/rofi/config.rasi` + `themes/`    |
| notifications | mako            | `.config/mako/config`                     |
| lock          | hyprlock        | `.config/hypr/hyprlock.conf`              |
| idle          | hypridle        | `.config/hypr/hypridle.conf`              |
| wallpaper     | swaybg          | `.config/hypr/wallpaper.png`              |
| polkit        | hyprpolkitagent | started from `hyprland.conf`              |
| terminal      | ghostty         | `.config/ghostty/config`                  |

**Keybinds mirror `desktop/mac`'s aerospace config** so muscle memory carries
between the mac and this box: `SUPER` (where `cmd` is on the mac) drives focus
`hjkl`, workspaces `1`–`0` and launching; `ALT` drives window ops — `alt-w`
close, `alt-f` fullscreen, `alt-t` float, `alt-a` back-and-forth, `alt -/=`
resize, `alt-g` gaps, `alt-m` the move-all submap.

Two things worth knowing:

- **This layer skips `desktop/linux` on purpose.** That layer is the X11/i3
  setup — i3, picom, `.xprofile`, and an old rofi theme pack — none of which
  applies under Wayland. It carries its own ghostty config instead, the same
  way `desktop/mac` does. Wayland-native replacements: mako for dunst,
  hyprpolkitagent for mate-polkit, grim/slurp for maim, wl-clipboard for xclip.
- **The GPU is pinned.** This box has an Intel iGPU and an RTX 5090, and the
  display hangs off the NVIDIA card, so `hyprland.conf` sets `AQ_DRM_DEVICES`
  to the NVIDIA DRM node via its stable `/dev/dri/by-path/` symlink — `cardN`
  numbering is not stable across boots.

## Migrating an old clone

If you're pulling onto a machine that had the pre-restructure layout
(`env/.config/`, `env/.config.mac/`, etc.), run:

```bash
DEV_ENV="$(pwd)" ./migrate-legacy
```

It pulls, removes the stale nvim submodule worktree at the old path,
re-inits it at `env/base/.config/nvim`, and cleans up empty leftover
dirs. Idempotent — safe to re-run.

## Linting

```bash
shellcheck dev-env init run runs/*
```

The only expected finding is `SC1091` in `runs/docker` — shellcheck can't
statically follow `/etc/os-release`. False positive; ignore.
