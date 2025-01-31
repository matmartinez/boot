#!/bin/zsh

#
# A script to supervise Time Machine backups remotely via SSH.
#

source boot-scripting.sh
source boot-dates.sh

# Grab basename
script_name=$(basename "$0")

# Function to display usage instructions
usage() {
    echo "💬 Monitor Time Machine backup age remotely via SSH."
    echo
    echo "Usage:"
    echo "  $script_name <host1> <host2> ... --max-age <time>"
    echo
    echo "Options:"
    echo "  --max-age <time>  Maximum acceptable backup age (e.g., '2d', '3h', '30m')."
    echo "  --help            Show this help message."
    echo
    echo "Examples:"
    echo "  $script_name mac-mini mac-pro --max-age 2d"
    echo
    echo "Notes:"
    echo "  - Hosts must be accessible via SSH."
    echo "  - Backup age is calculated based on the latest Time Machine snapshot."
    exit 1
}

# Check for help flag
if [[ "$1" == "--help" ]]; then
    usage
fi
# If no arguments are provided, just display usage and exit
if [[ $# -eq 0 ]]; then
    usage
fi

# Separate hosts and --max-age argument
hosts=()
max_age_provided=0
max_age_seconds=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --max-age)
            shift
            if [[ -z "$1" ]]; then
                echo "Error: --max-age requires a time value."
                usage
            fi
            
            max_age_seconds=$(duration_to_seconds "$1")
            
            if [[ $? -ne 0 ]]; then
              echo "Failed to convert --max-age to seconds. Exiting." >&2
              exit 1
            fi
            
            max_age_provided=1
            shift
            ;;
        *)
            hosts+=("$1")
            shift
            ;;
    esac
done

# Check if hosts were provided but --max-age was missing
if [[ ${#hosts[@]} -gt 0 && $max_age_provided -eq 0 ]]; then
    echo "Error: Missing --max-age argument."
    usage
fi

# Check if --max-age was provided but no hosts
if [[ ${#hosts[@]} -eq 0 && $max_age_provided -eq 1 ]]; then
    echo "Error: No hosts provided."
    usage
fi

current_epoch=$(date "+%s")

# Loop through each host and check the latest backup
for host in "${hosts[@]}"; do
    echo "Checking ${TEXT_BOLD}$host${TEXT_RESET}..."

    # Retrieve the latest backup date via SSH
    latest_backup=$(ssh "$host" "tmutil latestbackup 2>/dev/null")

    if [[ -z "$latest_backup" ]]; then
        echo "  ${TEXT_RED}[FAILED]${TEXT_RESET} Could not retrieve Time Machine backup."
        continue
    fi

    # Extract backup date (removing .backup suffix)
    backup_date_raw=$(basename "$latest_backup" | sed -E 's/\.backup//')
    backup_date=$(echo "$backup_date_raw" | tr '-' ' ')

    # Convert backup timestamp to epoch time
    backup_epoch=$(date -j -f "%Y %m %d %H%M%S" "$backup_date" "+%s" 2>/dev/null)
    
    if [[ -z "$backup_epoch" ]]; then
        echo "  ${TEXT_RED}[FAILED]${TEXT_RESET} Invalid backup timestamp format."
        continue
    fi

    # Calculate elapsed time since the last backup
    elapsed_seconds=$((current_epoch - backup_epoch))
    elapsed_string=$(epoch_to_readable_time "$backup_epoch")

    # Determine pass/fail status
    local status_string
    if [[ $elapsed_seconds -lt $max_age_seconds ]]; then
        status_string="${TEXT_GREEN}[PASSED]${TEXT_RESET}"
    else
        status_string="${TEXT_RED}[FAILED]${TEXT_RESET}"
    fi

    # Format and display the result
    formatted_date=$(date -j -f "%Y %m %d %H%M%S" "$backup_date" "+%A, %B %d, %Y at %I:%M %p")
    echo "  $status_string $formatted_date ($elapsed_string)"
done
