#!/usr/bin/env bash
set -e

BOOT_REPO_URL="https://github.com/matmartinez/boot"
BOOT_DEFAULT_DIR="$HOME/.boot"
BOOT_INSTALL_DIR="${BOOT_INSTALL_DIR:-$BOOT_DEFAULT_DIR}"

print_logo() {
  echo "    ____  ____  ____  ______"
  echo "   / __ )/ __ \/ __ \/_  __/"
  echo "  / __  / / / / / / / / /   "
  echo " / /_/ / /_/ / /_/ / / /    "
  echo "/_____/\____/\____/ /_/     "
  echo "" 
}

log() {
  printf "%s\n" "$*"
}

die() {
  log "$*"
  exit 1
}

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
    log "Homebrew is already installed ($(brew --version | head -1))."
    log "Skipping Homebrew installation."
    return 0
  fi

  printf "Homebrew not found. Would you like to install it? [y/N] "
  read -r install_brew
  case "$install_brew" in
    [yY]*)
      log "Installing Homebrew..."
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      ;;
    *)
      die "Homebrew is required to install the shell tools."
      ;;
  esac

  if ! load_brew_env; then
    die "Homebrew installed, but brew is not on PATH. Add it and re-run."
  fi
}

detect_repo_dir() {
  local src
  src="${BASH_SOURCE[0]-}"
  if [[ -n "$src" && -f "$src" ]]; then
    local dir
    dir="$(cd -- "$(dirname -- "$src")" && pwd -P)"
    if [[ -f "$dir/zshrc" ]]; then
      printf "%s\n" "$dir"
      return 0
    fi
  fi
  return 1
}

ensure_repo() {
  local repo_dir="$1"

  if [[ -d "$repo_dir" && -f "$repo_dir/zshrc" ]]; then
    log "Using existing Boot repo at $repo_dir"
    return 0
  fi

  if [[ -e "$repo_dir" ]]; then
    die "Install path exists but does not look like Boot: $repo_dir"
  fi

  mkdir -p "$(dirname -- "$repo_dir")"

  if command -v git &>/dev/null; then
    log "Cloning Boot into $repo_dir"
    git clone "$BOOT_REPO_URL" "$repo_dir"
    return 0
  fi

  if ! command -v curl &>/dev/null; then
    die "curl is required to download Boot."
  fi
  if ! command -v tar &>/dev/null; then
    die "tar is required to extract Boot."
  fi

  log "Downloading Boot into $repo_dir"
  local tmpdir extracted_dir
  tmpdir="$(mktemp -d)"
  trap 'rm -rf "$tmpdir"' EXIT

  curl -fsSL "$BOOT_REPO_URL/archive/HEAD.tar.gz" -o "$tmpdir/boot.tar.gz"
  tar -xzf "$tmpdir/boot.tar.gz" -C "$tmpdir"

  for dir in "$tmpdir"/boot-*; do
    if [[ -d "$dir" ]]; then
      extracted_dir="$dir"
      break
    fi
  done

  if [[ -z "${extracted_dir-}" ]]; then
    die "Download failed; could not find extracted repo."
  fi

  mv "$extracted_dir" "$repo_dir"
  trap - EXIT
  rm -rf "$tmpdir"
}

main() {
  print_logo

  local repo_dir
  repo_dir="$(detect_repo_dir || true)"
  if [[ -z "$repo_dir" ]]; then
    repo_dir="$BOOT_INSTALL_DIR"
    ensure_repo "$repo_dir"
  fi

  ensure_brew

  printf "Install shell tools? This is required to use Boot. [y/N] "
  read -r install_shell
  case "$install_shell" in
    [yY]*)
      if ! command -v zsh &>/dev/null; then
        log "Installing zsh (required)..."
        brew install zsh
      fi

      log "Installing tools tap..."
      brew tap matmartinez/tools
      brew install blocksay

      log "Installing shell..."
      brew install starship fzf
      ;;
    *)
      die "Shell installation is required to proceed."
      ;;
  esac

  log "Boot repository path is ${repo_dir}"

  if [[ -f ~/.zshrc ]]; then
    mv ~/.zshrc ~/.zshrc.bak
    log "Backed up existing ~/.zshrc to ~/.zshrc.bak"
  fi

  log "Symlinking ~/.zshrc to zshrc inside the repository..."
  ln -s "${repo_dir}/zshrc" ~/.zshrc
  log "Success! ~/.zshrc now points to ${repo_dir}/zshrc"

  local boot_dir
  boot_dir="$HOME/.boot"

  if [[ "$repo_dir" != "$boot_dir" ]]; then
    if [[ -L "$boot_dir" ]]; then
      log "Removing previous symlink: $boot_dir"
      rm "$boot_dir"
    fi

    log "Symlinking the boot repository at ${repo_dir} to $boot_dir ..."
    ln -s "$repo_dir" "$boot_dir"
  fi

  log "Done! Don't forget to restart your terminal!"
}

main "$@"
