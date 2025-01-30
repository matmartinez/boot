# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load.
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="steeef"

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git)

source $ZSH/oh-my-zsh.sh

# Path to your Boot installation.
export BOOT="$HOME/.boot"

# Ensure Boot scripts are in your $PATH
export PATH="$BOOT/bin:$PATH"

source $BOOT/aliases
source $BOOT/bin/boot.sh
