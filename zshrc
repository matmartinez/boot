export BOOT="$HOME/.boot"
export XDG_CONFIG_HOME="$BOOT/config"
export STARSHIP_CONFIG="$XDG_CONFIG_HOME/starship.toml"
export PATH="$BOOT/bin:$PATH" # Ensure Boot scripts are in your $PATH

export HISTSIZE=1000000000
export SAVEHIST="$HISTSIZE"

setopt EXTENDED_HISTORY
setopt autocd

# Enable interactive completion menu & case-insensitive matching + 1-typo fuzzy matching
autoload -U compinit
compinit -C

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}' 'r:|?=**'

eval "$(fzf --zsh)"
eval "$(starship init zsh)"

blocksay "${HOST%%.*}"
