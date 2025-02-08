#!/bin/zsh

# Request sudo access at the start of the script
ensure_sudo() {
  echo "This script requires sudo privileges. Please enter your password."
  sudo -v || { echo "Error: Sudo privileges are required. Exiting."; exit 1; }
  
  # Keep sudo alive until the script ends
  while true; do
    sudo -n true
    sleep 60
    kill -0 "$$" || exit
  done 2>/dev/null &
}

# Function to check if UID or GID is already in use
check_uid_gid() {
  local uid_gid="$1"

  # Check if the UID already exists
  if dscl . -list /Users UniqueID | awk '{print $2}' | grep -q "^$uid_gid$"; then
    echo "Error: UID '$uid_gid' is already in use. Exiting."
    exit 1
  fi

  # Check if the GID already exists
  if dscl . -list /Groups PrimaryGroupID | awk '{print $2}' | grep -q "^$uid_gid$"; then
    echo "Error: GID '$uid_gid' is already in use. Exiting."
    exit 1
  fi
}

create_home_folder() {
  local name="$1"     # Account name (e.g., "_minecraft")
  local home_dir="/Users/$name"

  echo "Checking home directory for user '$name'..."

  if [[ -d "$home_dir" ]]; then
    echo "Home directory '$home_dir' already exists. Fixing permissions..."
  else
    echo "Home directory does not exist. Creating..."
    # Attempt to use createhomedir
    if sudo createhomedir -u "$name" -c > /dev/null 2>&1; then
      echo "Home directory created successfully using 'createhomedir'."
    else
      echo "'createhomedir' failed. Creating home directory manually..."
      sudo mkdir -p "$home_dir"
      echo "Manual home directory created at '$home_dir'."
    fi
  fi

  # Fix ownership and permissions
  echo "Ensuring ownership and permissions for '$home_dir'..."
  sudo chown -R "$name:$name" "$home_dir"
  sudo chmod 755 "$home_dir"
}

create_daemon_account() {
  local uid_gid="$1"  # Unique ID and Group ID (numerical, e.g., 300)
  local name="$2"     # Account name (e.g., "_minecraft")

  # Derived variables
  local home_dir="/Users/$name"
  local shell="/bin/bash"

  # Safety checks
  if [[ -z "$uid_gid" || -z "$name" ]]; then
    echo "Error: Missing parameters. UID/GID and name are required."
    echo "Usage: $0 <uid/gid> <name>"
    exit 1
  fi

  # Check for existing UID/GID
  check_uid_gid "$uid_gid"

  # Check if the user already exists
  if dscl . -list /Users | grep -q "^$name$"; then
    echo "User '$name' already exists. Exiting."
    return 1
  fi

  # Step 1: Create the group
  echo "Creating group '$name' with GID $uid_gid..."
  sudo dscl . create /Groups/$name
  sudo dscl . create /Groups/$name PrimaryGroupID $uid_gid
  sudo dscl . create /Groups/$name RealName "$name"

  # Step 2: Create the user
  echo "Creating user '$name' with UID $uid_gid..."
  sudo dscl . create /Users/$name
  sudo dscl . create /Users/$name UniqueID $uid_gid
  sudo dscl . create /Users/$name PrimaryGroupID $uid_gid
  sudo dscl . create /Users/$name UserShell $shell
  sudo dscl . create /Users/$name NFSHomeDirectory $home_dir
  sudo dscl . create /Users/$name RealName "$name"

  # Step 3: Append the user to the group
  echo "Adding user '$name' to group '$name'..."
  sudo dscl . append /Groups/$name GroupMembership $name

  # Step 4: Remove authentication authority and set password to "*"
  echo "Setting password to '*' and removing authentication authority..."
  sudo dscl . delete /Users/$name AuthenticationAuthority
  sudo dscl . create /Users/$name Password "*"

  # Step 5: Create the home directory
  create_home_folder "$name"

  echo "Daemon account '$name' with UID/GID $uid_gid created successfully."
}

# Main Execution
if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <uid/gid> <name>"
  echo "Example: $0 300 _minecraft"
  exit 1
fi

ensure_sudo
create_daemon_account "$1" "$2"
