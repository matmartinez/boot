#!/bin/zsh

# Function to retrieve passphrase
get_passphrase() {
    local disk="$1"
    local passphrase

    # Debug messages go to stderr
    echo "Attempting to retrieve passphrase for $disk..." >&2
    passphrase=$(security find-generic-password -a "$USER" -s "unlockVolume_$disk" -w 2>/dev/null)
    
    if [[ -z "$passphrase" ]]; then
        echo "No saved passphrase for $disk. Please use the '--save-passphrase' option to save the passphrase." >&2
        return 1
    fi

    # Only echo the passphrase to stdout
    echo "$passphrase"
    return 0
}

# Function to unlock disk on remote machine
unlock_disk_remote() {
    local remote_host="$1"
    local disk="$2"
    local passphrase="$3"

    echo "Unlocking $disk on $remote_host..."
    
    ssh "$remote_host" "diskutil apfs unlockVolume \"$disk\" -passphrase \"$passphrase\""
}

# Main script
if [[ "$#" -lt 2 ]]; then
    echo "Usage: $0 <remote_host> <disk1> [disk2] ..."
    echo "       or: $0 --save-passphrase <disk>"
    exit 1
fi

# Check for --save-passphrase option
if [[ "$1" == "--save-passphrase" ]]; then
    if [[ -z "$2" ]]; then
        echo "Usage: $0 --save-passphrase <disk>"
        exit 1
    fi
    disk="$2"
    echo -n "Enter passphrase for $disk: "
    read -s passphrase
    echo
    echo "Saving passphrase to Keychain for $disk..."
    security add-generic-password -a "$USER" -s "unlockVolume_$disk" -w "$passphrase" > /dev/null
    echo "Passphrase saved."
    exit 0
fi

# Otherwise, process disks
remote_host="$1"
shift
disks=("$@")

for disk in "${disks[@]}"; do
    echo "Processing disk: $disk"

    # Get passphrase
    passphrase=$(get_passphrase "$disk") || {
        echo "Skipping disk: $disk due to missing passphrase."
        continue
    }

    # Unlock disk remotely
    unlock_disk_remote "$remote_host" "$disk" "$passphrase"
done

echo "All specified disks have been processed."
