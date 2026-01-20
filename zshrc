export BOOT="$HOME/.boot"
export STARSHIP_CONFIG="$BOOT/config/starship.toml"
export PATH="$BOOT/bin:$PATH" # Ensure Boot scripts are in your $PATH

export HISTSIZE=1000000000
export SAVEHIST=$HISTSIZE

setopt EXTENDED_HISTORY
setopt autocd
autoload -U compinit; compinit

# Enable interactive completion menu & case-insensitive matching + 1-typo fuzzy matching
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}' 'r:|?=**'

source <(fzf --zsh)

eval "$(starship init zsh)"

blocksay $(hostname | sed 's/\.local$//') # Remove .local if present
