#!/usr/bin/env zsh
set -e

echo "    ____  ____  ____  ______"
echo "   / __ )/ __ \/ __ \/_  __/"
echo "  / __  / / / / / / / / /   "
echo " / /_/ / /_/ / /_/ / / /    "
echo "/_____/\____/\____/ /_/     "
echo ""                

# Check/Install Homebrew
# (by looking for `brew`). If found, skip the install automatically.

if command -v brew &>/dev/null; then
  echo "Homebrew is already installed ($(brew --version | head -1))."
  echo "Skipping Homebrew installation."
else
  read "?Homebrew not found. Would you like to install it? [y/N] " install_brew
  case "$install_brew" in
    [yY]*)
      echo "Installing Homebrew..."
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      # -- After installing, you might need to add brew to PATH (especially on Apple Silicon).
      # For Apple Silicon, Homebrew installs to /opt/homebrew.
      # For Intel, /usr/local/homebrew is typical.
      # Usually the Homebrew install script will show you what to add to your PATH.
      ;;
    *)
      echo "Skipping Homebrew installation."
      ;;
  esac
fi

# Check/Install Oh My Zsh
# (by looking for ~/.oh-my-zsh). If found, skip the install automatically.

if [[ -d "$HOME/.oh-my-zsh" ]]; then
  echo "Oh My Zsh is already installed at $HOME/.oh-my-zsh."
  echo "Skipping Oh My Zsh installation."
else
  # Prompt user for Oh My Zsh installation
  read "?Would you like to install Oh My Zsh? [y/N] " install_ohmyzsh

  case "$install_ohmyzsh" in
    [yY]*)
      echo "Installing Oh My Zsh..."
      
      # Run with --unattended for a non-interactive install
      sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
      ;;
    *)
      echo "Skipping Oh My Zsh installation."
      ;;
  esac
fi

# Determine the absolute path to the directory containing this repo.
# In zsh, "${0:A:h}" gives the absolute path to the repo's directory.
SCRIPT_DIR=${0:A:h}

echo "Boot repo path is ${SCRIPT_DIR}"

# Backup any existing ~/.zshrc to ~/.zshrc.bak (if it exists).
if [[ -f ~/.zshrc ]]; then
  mv ~/.zshrc ~/.zshrc.bak
  echo "Backed up existing ~/.zshrc to ~/.zshrc.bak"
fi

# Create a symbolic link from ~/.zshrc to the local 'zshrc' file.
ln -s "${SCRIPT_DIR}/zshrc" ~/.zshrc

echo "Success! ~/.zshrc now points to ${SCRIPT_DIR}/zshrc"

# Set up ~/.boot folder
BOOT_DIR="$HOME/.boot"
BOOT_BIN="$BOOT_DIR/bin"
BOOT_ALIASES_FILE="$BOOT_DIR/aliases"

# **Destructive**: Remove ~/.boot if it exists
if [[ -e "$BOOT_DIR" ]]; then
  echo "Removing existing $BOOT_DIR (and all contents)..."
  rm -rf "$BOOT_DIR"
fi

# Re-create a fresh ~/.boot (and subfolders)
mkdir -p "$BOOT_DIR"

# Symlink the repo scripts folder
LOCAL_BIN_DIR="${SCRIPT_DIR}/bin"

echo "Symlinking the bin folder from the repo to $BOOT_BIN ..."
ln -s "$LOCAL_BIN_DIR" "$BOOT_BIN"

# Aliases

echo "Symlinking the aliases file from the repo to $BOOT_DIR ..."

# Create or update ~/.boot/aliases
LOCAL_ALIASES="${SCRIPT_DIR}/aliases.sh"

ln -s "$LOCAL_ALIASES" "$BOOT_ALIASES_FILE"

echo "Done! Don't forget to restart your terminal!"
