# Higly inspired from https://www.youtube.com/watch?v=ud7YxC33Z3w&t=231s

export EDITOR='nvim'
export PATH=$PATH:~/.local/scripts/
export PATH=$PATH:~/.volta/bin/

# Set Zinit path 
zstyle ':zinit:plugin:*' cdclear 'no'
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Dowload Zinit if not installed
if [ ! -d "$ZINIT_HOME" ]; then
  mkdir -p "$(dirname $ZINIT_HOME)"
  git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# enable Zinit
source "${ZINIT_HOME}/zinit.zsh"

# History setup (moved up to be available immediately)
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space # ignore commands with space at the beginning, useful if credentials are in the prompt
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# Load essential aliases first
[[ -f ~/.zsh_aliases ]] && source ~/.zsh_aliases

# Keybindings for completions (moved earlier)
bindkey '^a' beginning-of-line
bindkey '^e' end-of-line
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward

skip_global_compinit=1
autoload -Uz compinit
if [[ -n ${ZDOTDIR}/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi

zstyle ':completion:*' rehash true
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path $ZSH_CACHE_DIR

zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}' # completion match lower and upper case
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no


zinit ice wait'2' atload'_zsh_autosuggest_start' lucid
zinit light zsh-users/zsh-autosuggestions

# Bind key for autosuggestions after it's loaded
bindkey '^y' autosuggest-accept

# Syntax highlighting (load with higher wait time)
zinit ice wait'2' atinit'zpcompinit; zpcdreplay' lucid
zinit light zsh-users/zsh-syntax-highlighting
zinit ice wait'2' lucid
zinit light zsh-users/zsh-completions
zinit light Aloxaf/fzf-tab
zstyle ':fzf-tab:completion:cd:*' fzf-preview 'ls --color $realpath'

zinit ice wait'3' lucid
zinit light MichaelAquilina/zsh-you-should-use

zinit snippet OMZP::git

zinit ice wait'2' lucid
zinit snippet OMZP::docker

zinit ice wait'2' lucid
zinit snippet OMZP::mvn

zinit ice wait'2' lucid
zinit snippet OMZP::ubuntu


[[ -f ~/.zsh_local ]] && source ~/.zsh_local

if command -v fzf >/dev/null 2>&1; then
    source <(fzf --zsh)
fi

if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
  export STARSHIP_CONFIG=~/.config/starship/starship.toml
fi

if [ -f ~/.sdkman/bin/sdkman-init.sh ]; then
  source "$HOME/.sdkman/bin/sdkman-init.sh"
else
  echo "sdkman is not installed, you should install it!"
fi

# Deferred zinit cdreplay for better startup
zinit cdreplay -q

# Compile completion dump
{
  # Compile zcompdump, if modified, to increase startup speed
  zcompdump="${ZDOTDIR:-$HOME}/.zcompdump"
  if [[ -s "$zcompdump" && (! -s "${zcompdump}.zwc" || "$zcompdump" -nt "${zcompdump}.zwc") ]]; then
    zcompile "$zcompdump"
  fi
} &!

if [ ! -f ~/.zshrc.zwc -o ~/.zshrc -nt ~/.zshrc.zwc ]; then
  zcompile ~/.zshrc
fi

# opencode
export PATH=/home/jo-pouradier/.opencode/bin:$PATH
