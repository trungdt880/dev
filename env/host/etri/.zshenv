. "$HOME/.cargo/env"

# etri is a shared multi-user box: dotfiles live under $ZDOTDIR
# (/home/zeyi/.trungdt-config), not $HOME. These overrides make the
# base rc files resolve to the right tree.
export XDG_CONFIG_HOME="$ZDOTDIR/.config"
export DEV_ENV="/home/zeyi/trungdt/personal/dev"

# ~/.oh-my-zsh is shared with other users; keep our custom theme isolated
# under $ZDOTDIR. dev-env-etri symlinks shared plugins back in.
export ZSH_CUSTOM="$ZDOTDIR/.oh-my-zsh/custom"
