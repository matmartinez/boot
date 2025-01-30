#!/bin/zsh

# Check if the required file exists
if [[ ! -f "motd.sh" ]]; then
  echo "Error: 'motd.sh' not found in the current directory."
  exit 1
fi

# Check if a parameter is provided
if [[ -z "$1" ]]; then
  echo "Usage: $0 <user@host | host>"
  exit 1
fi

# Parse the parameter
remote="$1"
destination_path="~/.motd.sh"

# Copy the file to the remote server
echo "Copying 'motd.sh' to $remote:$destination_path ..."
scp motd.sh "${remote}:${destination_path}"

# Check if the copy was successful
if [[ $? -eq 0 ]]; then
  echo "File successfully copied to $remote:$destination_path"
else
  echo "Error: Failed to copy the file."
fi
