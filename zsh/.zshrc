# Higly inspired from https://www.youtube.com/watch?v=ud7YxC33Z3w&t=231s

export EDITOR='nvim'
export PATH=$PATH:~/.local/scripts/

# Set Zinit path 
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Dowload Zinit if not installed
if [ ! -d "$ZINIT_HOME" ]; then
  mkdir -p "$(dirname $ZINIT_HOME)"
  git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# enable Zinit
source "${ZINIT_HOME}/zinit.zsh"

# Add zsh plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab
zinit light MichaelAquilina/zsh-you-should-use
zinit snippet OMZP::git
zinit snippet OMZP::docker
zinit snippet OMZP::mvn
zinit snippet OMZP::ubuntu


# Plugins setup
autoload -U compinit && compinit
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}' # completion match lower and upper case
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no # to get fzf menu or history search
zstyle ':fzf-tab:completion:cd:*' fzf-preview 'ls --color $realpath'

zinit cdreplay -q

# Keybindings for completions
bindkey '^y' autosuggest-accept
bindkey '^a' beginning-of-line
bindkey '^e' end-of-line
# To search with prefix
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward

# History
HISTSIZE=5000 # ? To much ?
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space # ignore commands with space at the beginning, usefull if credentials are in the prompt
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# Aliases
[[ -f ~/.zsh_aliases ]] && source ~/.zsh_aliases

# A bit of FzF
# TODO: change depending on the OS
if [ -z fzf ]; then
  source <(fzf --zsh)
fi

# Java sdk management
if [ -f ~/.sdkman/bin/sdkman-init.sh ];then
  source "/Users/jopouradierduteil/.sdkman/bin/sdkman-init.sh"
else
  echo "sdkman is not installed, you should install it !"
fi


# Prompt with starship
eval "$(starship init zsh)"
export STARSHIP_CONFIG=~/.config/starship/starship.toml



# Local config that might defer between OS
[[ -f ~/.zsh_local ]] && source ~/.zsh_local

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
