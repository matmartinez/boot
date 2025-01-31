#!/bin/zsh

# epoch_to_readable_time $input_epoch → $output_readable_time
# Converts an epoch timestamp into a human-readable relative time format.
# $input_epoch: A single argument representing an epoch timestamp.
# $output_readable_time: Returns a human-friendly string such as "just now", "2 hours ago", or "in 3 days".
epoch_to_readable_time() {
  local input_epoch=$1
  local current_epoch=$(date +%s)
  local diff=$((input_epoch - current_epoch))
  local abs_diff=${diff#-} # Absolute value of difference
  
  local minutes=$((abs_diff / 60 % 60))
  local hours=$((abs_diff / 3600 % 24))
  local days=$((abs_diff / 86400))
  local result=""
  
  if [[ $diff -eq 0 ]]; then
    echo "just now"
    return
  fi
  
  if [[ $days -gt 0 ]]; then
    result+="$days day"; [[ $days -gt 1 ]] && result+="s"
    [[ $hours -gt 0 || $minutes -gt 0 ]] && result+=", "
  fi
  
  if [[ $hours -gt 0 ]]; then
    result+="$hours hour"; [[ $hours -gt 1 ]] && result+="s"
    [[ $minutes -gt 0 ]] && result+=", "
  fi
  
  if [[ $minutes -gt 0 ]]; then
    result+="$minutes minute"; [[ $minutes -gt 1 ]] && result+="s"
  fi
  
  if [[ -z "$result" ]]; then
    result="less than a minute"
  fi
  
  if [[ $diff -lt 0 ]]; then
    echo "$result ago"
  else
    echo "in $result"
  fi
}

# duration_to_seconds $input_string → $output_seconds
# Converts a human-readable time format (e.g., "2d", "3h", "30m") into total seconds.
# $input_string: A string containing one or more time units (days `d`, hours `h`, minutes `m`).
# $output_seconds: Returns the total duration in seconds.
# Note: Returns an error message and exit code `1` for invalid input.
duration_to_seconds() {
  local duration=$1
  local seconds=0
  local days=0 hours=0 minutes=0
  local valid=0  # A flag to check if at least one valid unit is found

  # Check for valid format (must contain at least one unit)
  if [[ ! "$duration" =~ [0-9]+[dhm] ]]; then
    echo "Error: Invalid format. Use numbers followed by d (days), h (hours), or m (minutes)." >&2
    return 1
  fi

  if [[ $duration == *d* ]]; then
    days=${duration%%d*}
    duration=${duration#*d}
    [[ $days =~ ^[0-9]+$ ]] || { echo "Error: Invalid days format." >&2; return 1; }
    valid=1
  fi

  if [[ $duration == *h* ]]; then
    hours=${duration%%h*}
    duration=${duration#*h}
    [[ $hours =~ ^[0-9]+$ ]] || { echo "Error: Invalid hours format." >&2; return 1; }
    valid=1
  fi

  if [[ $duration == *m* ]]; then
    minutes=${duration%%m*}
    [[ $minutes =~ ^[0-9]+$ ]] || { echo "Error: Invalid minutes format." >&2; return 1; }
    valid=1
  fi

  # Ensure at least one valid unit was found
  if [[ $valid -eq 0 ]]; then
    echo "Error: No valid time units found in input." >&2
    return 1
  fi

  seconds=$((days * 86400 + hours * 3600 + minutes * 60))

  echo $seconds
  return 0  # Success
}
