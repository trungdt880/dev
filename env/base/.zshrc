# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH
autoload -U +X compinit && compinit

# Path to your oh-my-zsh installation.
HISTFILE=~/.zsh_history
HISTSIZE=999999999
SAVEHIST=$HISTSIZE

export ZSH="$HOME/.oh-my-zsh"


ZSH_THEME="robbyrussell"
EDITOR="nvim"

plugins=(git zsh-autosuggestions fast-syntax-highlighting vi-mode zsh-ssh)
INSERT_MODE_INDICATOR="%F{yellow}+%f"
# handle tmux cursor in vimode
export VI_MODE_SET_CURSOR=true

source $ZSH/oh-my-zsh.sh

#####################
# ALIASES           #
#####################
source $HOME/.zsh_aliases

#####################
# FZF SETTINGS      #
#####################
zle -N fancy-ctrl-z
bindkey '^Z' fancy-ctrl-z
bindkey "ç" fzf-cd-widget
export FZF_DEFAULT_OPTS="
--ansi
--layout=default
--info=inline
--border=sharp
--height=50%
--multi
--preview-window=:hidden
--preview-window=right:50%
--preview-window=sharp
--preview-window=cycle
--preview '([[ -f {} ]] && (bat --style=numbers --color=always --theme=Dracula --line-range :500 {} || cat {})) || ([[ -d {} ]] && (tree -C {} | less)) || echo {} 2> /dev/null | head -200'
--bind '?:toggle-preview'
--prompt='λ -> '
--pointer='|>'
--marker='✓'
--color=fg:#908caa,bg:#232136,hl:#ea9a97
--color=fg+:#e0def4,bg+:#393552,hl+:#ea9a97
--color=border:#44415a,header:#3e8fb0,gutter:#232136
--color=spinner:#f6c177,info:#9ccfd8,separator:#44415a
--color=pointer:#c4a7e7,marker:#eb6f92,prompt:#908caa
--bind 'ctrl-v:execute(code {+})'"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_DEFAULT_COMMAND='rg --files --no-ignore --hidden --follow -g "!{.git,node_modules}/*" 2> /dev/null'
export FZF_ALT_C_COMMAND='fd --type directory'
# disable sort when completing `git checkout`
zstyle ':completion:*:git-checkout:*' sort false
# # set descriptions format to enable group support
# zstyle ':completion:*:descriptions' format '[%d]'
# preview directory's content with exa when completing cd
zstyle ':fzf-tab:complete:*:*' fzf-preview '([[ -f $realpath ]] && (bat --style=numbers --color=always --theme=Dracula --line-range :500 $realpath || cat $realpath)) || ([[ -d $realpath ]] && (tree -C $realpath | less)) || echo $realpath 2> /dev/null | head -200'
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'tree -C $realpath | less'
# switch group using `,` and `.`
# zstyle ':fzf-tab:*' switch-group ',' '.'

function yy() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}


ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=13'
source ~/.zsh_profile

eval "$(zoxide init zsh)"
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
