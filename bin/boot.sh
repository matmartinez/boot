#!/bin/zsh

source boot-scripting.sh
source boot-dates.sh

(
  # Enable 0-based arrays in ZSH
  setopt KSH_ARRAYS
  
  ##
  ## Functions
  ##
  
  # Text as ASCII art:
  print_blocky(){
    local hostname="$1"
    
    declare -A ASCII_ART=(
      ["0"]=" ▗▄▖ ▗▄▄▖  ▗▄▄▖▗▄▄▄ ▗▄▄▄▖▗▄▄▄▖ ▗▄▄▖▗▖ ▗▖▗▄▄▄▖   ▗▖▗▖ ▗▖▗▖   ▗▖  ▗▖▗▖  ▗▖ ▗▄▖ ▗▄▄▖ ▗▄▄▄▖ ▗▄▄▖  ▗▄▄▖▗▄▄▄▖▗▖ ▗▖▗▖  ▗▖▗▖ ▗▖▗▖  ▗▖▗▖  ▗▖▗▄▄▄▄▖"
      ["1"]="▐▌ ▐▌▐▌ ▐▌▐▌   ▐▌  █▐▌   ▐▌   ▐▌   ▐▌ ▐▌  █     ▐▌▐▌▗▞▘▐▌   ▐▛▚▞▜▌▐▛▚▖▐▌▐▌ ▐▌▐▌ ▐▌▐▌ ▐▌ ▐▌ ▐▌▐▌     █  ▐▌ ▐▌▐▌  ▐▌▐▌ ▐▌ ▝▚▞▘  ▝▚▞▘    ▗▞▘"
      ["2"]="▐▛▀▜▌▐▛▀▚▖▐▌   ▐▌  █▐▛▀▀▘▐▛▀▀▘▐▌▝▜▌▐▛▀▜▌  █     ▐▌▐▛▚▖ ▐▌   ▐▌  ▐▌▐▌ ▝▜▌▐▌ ▐▌▐▛▀▘ ▐▌ ▐▌ ▐▛▀▚▖ ▝▀▚▖  █  ▐▌ ▐▌▐▌  ▐▌▐▌ ▐▌  ▐▌    ▐▌   ▗▞▘  "
      ["3"]="▐▌ ▐▌▐▙▄▞▘▝▚▄▄▖▐▙▄▄▀▐▙▄▄▖▐▌   ▝▚▄▞▘▐▌ ▐▌▗▄█▄▖▗▄▄▞▘▐▌ ▐▌▐▙▄▄▖▐▌  ▐▌▐▌  ▐▌▝▚▄▞▘▐▌   ▐▙▄▟▙▖▐▌ ▐▌▗▄▄▞▘  █  ▝▚▄▞▘ ▝▚▞▘ ▐▙█▟▌▗▞▘▝▚▖  ▐▌  ▐▙▄▄▄▖"
    )
    
    # Define widths for a-z: 5 = normal, 6 = wide
    #            ABCDEFGHIJKLMNOPQRSTUVWXYZ
    #                        **  *    * ***
    CHAR_WIDTHS="55555555555566556555565666" # M, N, Q, V, X, Y, Z are wide
    
    # Initialize cumulative offsets array for a-z
    CUMULATIVE_OFFSETS=()
    offset=0
    
    # Compute cumulative offsets
    for ((i=0; i<26; i++)); do
      width=${CHAR_WIDTHS:$i:1}          # Extract width for this character
      CUMULATIVE_OFFSETS[$i]=$offset     # Store cumulative offset
      offset=$((offset + width))         # Increment offset
    done
    
    # Get the hostname
    hostname=$(echo "$hostname" | tr '[:upper:]' '[:lower:]') # Convert to lowercase for consistency
    
    # Print ASCII art line by line
    for line in {0..3}; do
      output_line=""
      
      for ((i=0; i<${#hostname}; i++)); do
        char="${hostname:$i:1}"         # Current character
        ascii_val=$(printf "%d" "'$char") # ASCII value
    
        # Validate character: only 'a-z' allowed
        if [[ $ascii_val -ge 97 && $ascii_val -le 122 ]]; then
          index=$((ascii_val - 97))        # Normalize to 0-based index for 'a'
    
          # Retrieve the precomputed offset and width
          start_offset=${CUMULATIVE_OFFSETS[$index]}
          width=${CHAR_WIDTHS:$index:1}
    
          # Extract and append the substring for this character
          output_line+="${ASCII_ART[$line]:$start_offset:$width} "
        fi
      done
      echo "$output_line"
    done
  }
  
  # Row and header support
  add_row() {
    columns_1+=("$1")
    columns_2+=("$2")
    is_header+=(0) # Regular row
  }
  
  add_header() {
    local emoji="$1"
    local title="$2"
    columns_1+=("${emoji} ${title}") # Add the header content to the first column
    columns_2+=("")                  # No second column for headers
    is_header+=(1)                   # Mark as a header
  }
  
  print_rows() {
    local max_width=0
    
    # Determine the maximum width needed for the first column
    for item in "${columns_1[@]}"; do
        local len=${#item}
        (( len > max_width )) && max_width=$len
    done
  
    # Print rows with headers styled differently
    for (( i=0; i<${#columns_1[@]}; i++ )); do
        if [[ ${is_header[i]} -eq 1 ]]; then
            # Print header
            printf "\n${TEXT_BOLD}${TEXT_DARK_GRAY}%s${TEXT_RESET}\n" "${columns_1[i]}"
        else
            # Print regular row
            printf "${TEXT_LIGHT_GRAY}%${max_width}s${TEXT_RESET} %s\n" "${columns_1[i]}" "${columns_2[i]}"
        fi
    done
    
    reset_rows
  }
  
  reset_rows() {
    columns_1=()
    columns_2=()
    headers=()
    is_header=()
  }
  
  ##
  ## Motd functions
  ##
  
  # About:
  
  add_about(){
    add_header "💣" "ABOUT"
    
    # Uptime
    local current_epoch=$(date +%s)
    local uptime_epoch=$(($(sysctl -n kern.boottime | awk '{print $4}' | tr -d ',')))
    local uptime_seconds=$((current_epoch - uptime_epoch))
    local human_uptime=$(seconds_to_readable_duration uptime_seconds)
    
    add_row "Uptime" "${human_uptime}"
    
    # Capture the hardware report from system_profiler
    info=$(system_profiler SPHardwareDataType)
    
    # Extract the Chip (e.g., "Apple M2")
    chip="$(echo "$info" | awk -F': ' '/Chip:/ {print $2}')"
    
    # Extract the Processor Name (e.g., "6-Core Intel Core i5")
    processor="$(echo "$info" | awk -F': ' '/Processor Name:/ {print $2}')"
    
    # If chip is empty, fallback to processor
    if [ -n "$chip" ]; then
        add_row "Chip" "$chip"
    else
        add_row "Processor" "$processor"
    fi
    
    # Extract the Memory (e.g., "64 GB")
    add_row "Memory" "$(echo "$info" | awk -F': ' '/Memory:/ {print $2}')"
    
    # Get macOS version and build:
    add_row "macOS" "$(sw_vers -productVersion) ($(sw_vers -buildVersion))"
  }
  
  # Network:
  
  add_network(){
    add_header "🌎" "NET"
    
    # Get a list of all network services and handle names with spaces
    SERVICES=$(networksetup -listallnetworkservices | tail -n +2)
    
    # Loop through each service and display its status
    while IFS= read -r SERVICE; do
        # Retrieve the IP address for the service
        IP=$(networksetup -getinfo "$SERVICE" 2>/dev/null | grep '^IP address:' | awk '{print $3}')
        
        # Retrieve the router IP for the service
        ROUTER=$(networksetup -getinfo "$SERVICE" 2>/dev/null | grep '^Router:' | awk '{print $2}')
    
        # Check if IP and Router exist, otherwise mark as Disconnected
        if [ -n "$IP" ] && [ "$IP" != "none" ]; then
            add_row "$SERVICE" "$IP, Router: $ROUTER"
        else
            add_row "$SERVICE" "Unplugged"
        fi
    done <<< "$SERVICES"
  }
  
  # Tailscale:
  
  add_tailscale(){
    add_header "🎲" "TAILSCALE"
    
    # Check if Tailscale is installed
    if ! command -v tailscale &> /dev/null; then
        # Fallback to the macOS Tailscale binary if available
        if [[ -x "/Applications/Tailscale.app/Contents/MacOS/Tailscale" ]]; then
            alias tailscale="/Applications/Tailscale.app/Contents/MacOS/Tailscale"
        else
            add_row "Status" "Tailscale is not installed as CLI."
            return 1 # Exit the function here
        fi
    fi
    
    # Check if jq is installed
    if ! command -v jq &> /dev/null; then
      add_row "Status" "jq is not installed. Please install it first."
      return 1 # Exit the function here
    fi
    
    # Extract status info:
    TAILSCALE_DNSNAME=$(tailscale status --json | jq -r '.Self.DNSName')
    TAILSCALE_IPS=$(tailscale status --json | jq -r '.Self.TailscaleIPs | join(", ")')
    
    add_row "DNS name" "$TAILSCALE_DNSNAME"
    add_row "IPs"  "$TAILSCALE_IPS"
  }
  
  # Title:
  
  print_title() {
    # Hostname:
    print_blocky $(hostname | sed 's/\.local$//') # Remove .local if present
  }
  
  print_progress(){
    printf "\n${TEXT_LIGHT_GRAY}%s${TEXT_RESET}\n" "Thinking…" # Print a new line and the progress message
  }
  
  clear_progress(){
    tput cuu1        # Move the cursor up one line (to the progress line)
    tput el          # Clear the entire line
    tput cuu1        # Move up again (to the blank line)
    tput el          # Clear that line as well
  }
  
  # Main:
  motd_main(){
    print_title
    print_progress
    
    # Compose every section:
    add_about
    add_network
    add_tailscale
    
    # Clear progress:
    clear_progress
    
    # Print rows:
    print_rows
  }
  
  motd_main

)
