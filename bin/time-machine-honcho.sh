#!/bin/zsh

# Color codes
GREEN="\033[0;32m"
RED="\033[0;31m"
RESET="\033[0m"

# Usage function
usage() {
  echo "Usage: $0 <host1> <host2> ... --max-age <time>"
  echo "Example: $0 mac-mini mac-pro --max-age 2d"
  echo "  - Hosts: List of remote Mac hosts (via SSH)"
  echo "  - --max-age <time>: Maximum acceptable backup age (e.g., 2d, 3h, 30m)"
  exit 1
}

# Function to parse human-readable durations
parse_duration() {
  local duration=$1
  local seconds=0
  local days=0 hours=0 minutes=0

  if [[ $duration == *d* ]]; then
    days=${duration%%d*}
    duration=${duration#*d}
  fi
  if [[ $duration == *h* ]]; then
    hours=${duration%%h*}
    duration=${duration#*h}
  fi
  if [[ $duration == *m* ]]; then
    minutes=${duration%%m*}
  fi

  seconds=$((days * 86400 + hours * 3600 + minutes * 60))

  if [[ $seconds -le 0 ]]; then
    echo "Error: Invalid --max-age value. Use formats like '2d', '3h', or '45m'."
    usage
  fi

  echo $seconds
}

# Ensure at least 3 arguments are provided (host + --max-age + time)
if [[ $# -lt 3 ]]; then
  echo "Error: Missing arguments."
  usage
fi

# Extract the hosts and --max-age argument
HOSTS=()
MAX_AGE_SECONDS=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --max-age)
      shift
      if [[ -z "$1" ]]; then
        echo "Error: --max-age requires a time value."
        usage
      fi
      MAX_AGE_SECONDS=$(parse_duration "$1")
      shift
      ;;
    *)
      HOSTS+=("$1")
      shift
      ;;
  esac
done

# Validate that at least one host was provided
if [[ ${#HOSTS[@]} -eq 0 ]]; then
  echo "Error: No hosts provided."
  usage
fi

CURRENT_EPOCH=$(date "+%s")

# Loop through each host and check the latest backup
for HOST in "${HOSTS[@]}"; do
  echo "Checking Time Machine backup for: $HOST"

  # Retrieve the latest backup date via SSH
  LATEST_BACKUP=$(ssh "$HOST" "tmutil latestbackup 2>/dev/null")

  if [[ -z "$LATEST_BACKUP" ]]; then
    echo "  ${RED}[FAILED]${RESET} Could not retrieve Time Machine backup."
    continue
  fi

  # Extract the backup date (removing .backup suffix)
  BACKUP_DATE_RAW=$(basename "$LATEST_BACKUP" | sed -E 's/\.backup//')
  BACKUP_DATE=$(echo "$BACKUP_DATE_RAW" | tr '-' ' ')

  # Convert backup time to epoch
  BACKUP_EPOCH=$(date -j -f "%Y %m %d %H%M%S" "$BACKUP_DATE" "+%s")
  ELAPSED_SECONDS=$((CURRENT_EPOCH - BACKUP_EPOCH))

  # Convert elapsed time to human-readable format
  DAYS=$((ELAPSED_SECONDS / 86400))
  HOURS=$(( (ELAPSED_SECONDS % 86400) / 3600 ))
  MINUTES=$(( (ELAPSED_SECONDS % 3600) / 60 ))

  ELAPSED_STRING=""
  [[ $DAYS -gt 0 ]] && ELAPSED_STRING="$DAYS day(s)"
  [[ $HOURS -gt 0 ]] && ELAPSED_STRING="$ELAPSED_STRING $HOURS hour(s)"
  [[ $MINUTES -gt 0 ]] && ELAPSED_STRING="$ELAPSED_STRING $MINUTES minute(s)"

  # Check if the backup is recent enough
  if [[ $ELAPSED_SECONDS -lt $MAX_AGE_SECONDS ]]; then
    STATUS="${GREEN}[PASSED]${RESET}"
  else
    STATUS="${RED}[FAILED]${RESET}"
  fi

  # Format and display the result
  FORMATTED_DATE=$(date -j -f "%Y %m %d %H%M%S" "$BACKUP_DATE" "+%A, %B %d, %Y at %I:%M %p")
  echo "  $STATUS Latest backup: $FORMATTED_DATE ($ELAPSED_STRING ago)"
done
