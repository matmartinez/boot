#!/usr/bin/env zsh
set -e

echo "    ____  ____  ____  ______"
echo "   / __ )/ __ \/ __ \/_  __/"
echo "  / __  / / / / / / / / /   "
echo " / /_/ / /_/ / /_/ / / /    "
echo "/_____/\____/\____/ /_/     "
echo ""                

load_brew_env() {
  if command -v brew &>/dev/null; then
    return 0
  fi

  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi

  command -v brew &>/dev/null
}

ensure_brew() {
  if load_brew_env; then
    echo "Homebrew is already installed ($(brew --version | head -1))."
    echo "Skipping Homebrew installation."
    return 0
  fi

  read "?Homebrew not found. Would you like to install it? [y/N] " install_brew
  case "$install_brew" in
    [yY]*)
      echo "Installing Homebrew..."
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      ;;
    *)
      echo "Homebrew is required to install the shell tools. Exiting."
      exit 1
      ;;
  esac

  if ! load_brew_env; then
    echo "Homebrew installed, but brew is not on PATH."
    echo "Add Homebrew to PATH and re-run this installer."
    exit 1
  fi
}

# Check/Install Homebrew (required for shell tooling).
ensure_brew

# Install shell

# Prompt user for shell installation
read "?Install shell tools? This is required to use Boot. [y/N] " install_shell

case "$install_shell" in
  [yY]*)
    if ! command -v zsh &>/dev/null; then
      echo "Installing zsh (required)..."
      brew install zsh
    fi

    echo "Installing tools tap..."
    brew tap matmartinez/tools
    brew install blocksay
    
    echo "Installing shell..."
    brew install starship fzf
    ;;
  *)
    echo "Shell installation is required to proceed. Exiting."
    exit 1
    ;;
esac

# Determine the absolute path to the directory containing this repo.
# In zsh, "${0:A:h}" gives the absolute path to the repo's directory.
SCRIPT_DIR=${0:A:h}

echo "Boot repository path is ${SCRIPT_DIR}"

# Backup any existing ~/.zshrc to ~/.zshrc.bak (if it exists).
if [[ -f ~/.zshrc ]]; then
  mv ~/.zshrc ~/.zshrc.bak
  echo "Backed up existing ~/.zshrc to ~/.zshrc.bak"
fi

# Create a symbolic link from ~/.zshrc to the local 'zshrc' file.
echo "Symlinking ~/.zshrc to zshrc inside the repository..."

ln -s "${SCRIPT_DIR}/zshrc" ~/.zshrc

echo "Success! ~/.zshrc now points to ${SCRIPT_DIR}/zshrc"

# Set up ~/.boot folder
BOOT_DIR="$HOME/.boot"

# Check if the file exists and is a symlink
if [[ -L "$BOOT_DIR" ]]; then
  echo "Removing previous symlink: $BOOT_DIR"
  rm "$BOOT_DIR"
fi

# Set up alias
echo "Symlinking the boot repository at ${SCRIPT_DIR} to $BOOT_DIR ..."
ln -s "$SCRIPT_DIR" "$BOOT_DIR"

echo "Done! Don't forget to restart your terminal!"
