# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Personal dotfiles + dev-env provisioner. Bash scripts that copy configs into `$XDG_CONFIG_HOME` and `$HOME`, plus per-tool installer scripts. Not an application — no build, no tests.

For a user-facing overview see `README.md`.

## Required environment variables

Both must be exported before running any script:

- `DEV_ENV` — absolute path to this repo
- `WS` — workstation kind, one of: `mac`, `linux`, `server`, `waiv`,
  `waiv_workstation`, `etri`, `q`

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
    waiv_workstation/            # Hyprland/Wayland desktop (NOT headless;
                                 # hypr, waybar, rofi, mako, ghostty)
```

`WS_LAYERS` is the **single source of truth** for what gets applied where:

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

### waiv_workstation is the Hyprland desktop

`WS=waiv_workstation` is the Ubuntu 26.04 Wayland box (hostname `waicv`).

```bash
[waiv_workstation]="base desktop/common host/waiv_workstation"
```

Installed by `runs/hyprland` — plain apt, the whole stack is in Ubuntu 26.04
universe. GNOME is left alone and stays the default session; the hyprland
package drops session files into `/usr/share/wayland-sessions`, so Hyprland is
just an extra entry at login.

**It deliberately skips `desktop/linux`.** That layer is the X11/i3 setup —
`i3`, `picom` (an X11 compositor, meaningless under Wayland), `.xprofile`, and
an unmaintained adi1090x rofi theme pack. None of it applies here. The one
thing worth keeping from it was ghostty, so this layer carries its own copy;
`desktop/mac` already does the same, so per-layer ghostty configs are the
established pattern rather than an exception.

The Wayland-native choices, and what each replaces:

| This layer | Replaces | Why |
| ---------- | -------- | --- |
| mako | dunst | dunst is X11-era and merely tolerates Wayland. (swaync is the other common pick but is not packaged for 26.04.) |
| hyprpolkitagent | mate-polkit | Hyprland ships its own agent now. |
| rofi 2.0 | the adi1090x pack | rofi 2.0 is Wayland-native; no `rofi-wayland` fork needed. |
| hyprlock / hypridle | betterlockscreen | ecosystem-native. |
| swaybg | feh --bg-fill | hyprpaper 0.8.3 in Ubuntu 26.04 is broken: it never reads its config (no error even on `-c /nonexistent`) and draws nothing, leaving an empty background layer. swaybg is packaged and works. |
| keyd | `setxkbmap -option caps:escape` | XKB can do Caps-as-Escape *or* Caps-as-Ctrl, never tap-vs-hold. See `runs/keyd`. |
| grim + slurp + swappy | maim + xclip | X11 tools have no Wayland equivalent path. |
| wl-clipboard | xclip | `.zshrc.local`'s `pcat` uses `wl-copy` here. |

**Log in with "Hyprland (uwsm-managed)", not the plain "Hyprland" entry.**
Both start the compositor, but only the uwsm one gives you a working systemd
graphical session, and the difference is not cosmetic:

`graphical-session.target` sets `RefuseManualStart`, so a compositor cannot
start it itself — it has to be pulled in by a session unit. The plain session
has no such unit, so the target never activates. Consequences:
`xdg-desktop-portal-hyprland` never starts, the Settings portal is left with no
backend, and the first GTK app of the session (ghostty, nautilus) blocks on
D-Bus trying to autostart the GTK portal until systemd's 120s activation
timeout expires — which presents as "my terminal takes minutes to open", once
per login. uwsm's `wayland-session@.target` declares
`BindsTo=graphical-session.target` and fixes it properly.

`hyprland.conf` still runs correctly under both, and the AccountsService
session id for the uwsm entry is `hyprland-uwsm` (the plain one is
`hyprland`).

Five things to keep in mind when editing:

- **`.zshrc.local` must set `WS=waiv_workstation`.** It applies after `base`,
  so it is the layer that wins over `desktop`'s `WS=linux`. (nvm is handled
  once for every host in `env/base/.zsh_profile`, because `runs/node`'s
  installer appends it to `~/.zshrc.local` in `$HOME`, where the next
  `./dev-env` would overwrite it.)
- **Keybinds mirror `env/desktop/mac/.config/aerospace/aerospace.toml`, but
  everything is on SUPER.** aerospace splits between cmd and alt only because
  macOS reserves some cmd combos; that does not apply here, so the alt half is
  folded onto SUPER (`SUPER+W` close, `SUPER+F` fullscreen, `SUPER+M` move-all
  submap, `SUPER+G` gaps). Two consequences worth remembering: `SUPER+L` is
  focus-right, so lock lives on `SUPER+CTRL+L` (matching the old i3
  `$mod+Ctrl+l`); and the scratchpad is on `SUPER+grave`, not `SUPER+S`, so
  `SUPER+SHIFT+S` can be the region screenshot.
- **`runs/keyd` is the one thing here that is not per-user.** keyd is a system
  daemon and `/etc/keyd/default.conf` applies to every user on the box. There
  is no per-user way to get tap-vs-hold, so this is a deliberate trade-off;
  the script backs up any pre-existing config it did not write.
- **`misc:disable_autoreload = true` is load-bearing, not a preference.**
  Hyprland watches `hyprland.conf` and reloads on change, while `apply_layer`
  installs `.config/<tool>` by wipe-and-replace — so during every `./dev-env`
  run the file briefly does not exist. The watcher fires on the delete, reloads
  an absent config and drops to ZERO keybinds, and never re-fires when the file
  reappears (the watch was on the deleted inode). The symptom is the entire
  SUPER layer going dead right after running dev-env: `SUPER+2` just types "2".
  With autoreload off the live config survives the wipe and `hyprctl reload`
  (SUPER+SHIFT+C) picks up changes, which is the documented workflow anyway.
  If the binds ever do go dead, `hyprctl reload` restores them; check with
  `hyprctl binds | grep -c '^bind'` (96 is healthy, 0 means this bit you).
- **A window parked on `special:magic` looks exactly like broken workspace
  switching** — the scratchpad floats above every workspace, so switching
  appears to do nothing. waybar's workspace module sets `show-special` so it is
  visible when occupied. To rescue one:
  `hyprctl dispatch movetoworkspace "1,address:$(hyprctl clients -j | jq -r '.[]|select(.workspace.name=="special:magic")|.address')"`.

The compositor is pinned to the NVIDIA GPU via `AQ_DRM_DEVICES`, because the
box has an Intel iGPU too and only the NVIDIA card has a display attached.

**It must be the real `/dev/dri/cardN` node, not a `/dev/dri/by-path/` symlink.**
Aquamarine matches the value against the device nodes it enumerated from udev,
so a symlink never matches and it fails hard instead of falling back:
`drm: Explicit device ... not found` → `drm: Found no gpus to use, cannot
continue` → `CBackend::create() failed!`, which at the greeter looks like the
login flashing and returning to the login screen with no error. The trade-off
is that `cardN` numbering can shift if the GPU or driver set changes, so
`runs/hyprland` warns when the pinned node no longer matches
`readlink -f /dev/dri/by-path/pci-0000:02:00.0-card`.

Four things that already bit once, in order of how much time they cost:

- **Hyprland config syntax drifts between releases. Always run
  `Hyprland --verify-config` after editing `hyprland.conf`** — it prints
  file:line for every bad option and is the only reliable check. Config errors
  do not stop Hyprland from starting, they just silently drop the setting, so
  they are easy to miss. 0.53 in particular moved window rules from
  `windowrule = <rule>, <matcher>` one-liners to `windowrule { match:class = … }`
  blocks, replaced the `gestures {}` block with the `gesture = <fingers>, <dir>,
  <action>` keyword, and dropped `misc:new_window_takes_over_fullscreen`.
  `/usr/share/hypr/hyprland.conf` is the shipped reference for the installed
  version — read it, not the wiki, when they disagree.
- **The Ubuntu packages ship globally-enabled systemd user units** for waybar,
  mako, hypridle, hyprpaper and hyprpolkitagent (symlinked into
  `/etc/systemd/user/graphical-session.target.wants/`). They are only
  `WantedBy=graphical-session.target` with no compositor condition, so they also
  start inside GNOME and fail there. A user-scope `systemctl --user disable`
  cannot override a global enable — `runs/hyprland` masks them instead, and
  `hyprland.conf` starts each binary via `exec-once`.
- **Hyprland stops logging once the config loads**, so `hyprland.log` is 0 bytes
  and the crash report's "Log tail" cuts off long before the real failure —
  which makes an early crash look like it happened much earlier than it did.
  `debug:disable_logs = false` is set in `hyprland.conf` to keep logs; don't
  remove it without a reason. To test the compositor without touching the
  display, `AQ_BACKENDS=headless Hyprland -c <file>` runs it in isolation, and
  `Hyprland` launched from inside another Wayland session runs nested rather
  than on DRM — neither exercises the GPU path, so neither can reproduce a
  backend failure.
- **Selecting a session in the GDM greeter is not what makes it stick.** GDM
  reads the user's session from AccountsService; the gear menu only writes it on
  a successful login. Check with
  `busctl get-property org.freedesktop.Accounts /org/freedesktop/Accounts/User$(id -u) org.freedesktop.Accounts.User Session`
  and set it with the matching `SetSession s hyprland` call (no sudo needed —
  polkit allows changing your own user data from an active local session).

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
