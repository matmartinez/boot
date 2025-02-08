#!/bin/zsh

# Color control codes definitions.
#
# Example Usage:
#   echo "Puedo comer ${TEXT_RED}${TEXT_BOLD}vidrio${TEXT_RESET}."
#  
TEXT_GREEN=$(tput setaf 2)      # Green attribute
TEXT_RED=$(tput setaf 1)        # Red attribute
TEXT_YELLOW=$(tput setaf 3)     # Yellow attribute
TEXT_DARK_GRAY=$(tput setaf 8)  # Dark Gray attribute
TEXT_LIGHT_GRAY=$(tput setaf 7) # Light Gray attribute
TEXT_BOLD=$(tput bold)          # Bold attribute
TEXT_RESET=$(tput sgr0)         # Reset all attributes (color, bold, etc.)

# confirm
# Prompts the user for a yes/no confirmation with a default option.
#
# Arguments:
#   $1 - The prompt message to display.
#   $2 - The default response ('Y' for Yes, 'N' for No). Defaults to 'N' if not provided.
#
# Behavior:
#   - Displays the prompt with the default option in bold.
#   - Waits for user input; if empty, uses the default response.
#   - Returns 0 (success) if the user confirms (Yes), 1 (failure) otherwise.
#
# Example Usage:
#   if confirm "Proceed with installation?" "Y"; then
#     echo "Installation started..."
#   else
#     echo "Installation aborted."
#   fi
confirm() {
  local prompt default reply bold_start bold_end

  prompt="$1"
  default="$2"

  if [[ "$default" == "Y" || "$default" == "y" ]]; then
    prompt="$prompt ${TEXT_DARK_GRAY}[${TEXT_RESET}${TEXT_BOLD}Y${TEXT_RESET}${TEXT_DARK_GRAY}/n]${TEXT_RESET} "
    default="Y"
  else
    prompt="$prompt ${TEXT_DARK_GRAY}[y/${TEXT_RESET}${TEXT_BOLD}N${TEXT_RESET}${TEXT_DARK_GRAY}]${TEXT_RESET} "
    default="N"
  fi

  read -r "?$prompt" reply
  reply=${reply:-$default}

  [[ "$reply" =~ ^[Yy]$ ]]
}

# ensure_sudo
# Ensures the user has active sudo privileges
#
# This function repeatedly prompts the user for their password if they do not
# have an active sudo session. It verifies sudo access using `sudo -v`, which
# refreshes or initializes the timestamp for sudo authentication.
#
# If the password is incorrect, the user is prompted again until successful.
# Error messages from `sudo -v` are suppressed for a cleaner user experience.
#
# Example Usage:
#   ensure_sudo
#   sudo shutdown -h now  # Now runs without additional password prompt
#
ensure_sudo() {
  while ! sudo -v; do
    echo "${TEXT_YELLOW}Incorrect password or sudo access denied. Please try again.${TEXT_RESET}"
  done
}

# print_with_bullets
# Prints each item in the input as a bulleted list.
# 
# Arguments:
#   $1 - The list of strings to be printed as a bulleted list.
#
# Example Usage:
#   cities=(
#     talca
#     paris
#     london
#   )
#   print_with_bullets $cities
# 
# Output:
#   - talca
#   - paris
#   - london
#
print_list_with_bullets() {
  for item in "$@"; do
    echo "  ${TEXT_DARK_GRAY}-${TEXT_RESET} $item"
  done
}
