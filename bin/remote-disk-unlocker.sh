#!/bin/zsh

#
# A script to unlock encrypted APFS disks remotely.
#

# Grab the basename
script_name=$(basename "$0")

# Function to retrieve passphrase
get_passphrase() {
    local disk="$1"
    local passphrase

    echo "Retrieving passphrase for $disk..." >&2
    passphrase=$(security find-generic-password -a "$USER" -s "unlockVolume_$disk" -w 2>/dev/null)
    
    if [[ -z "$passphrase" ]]; then
        echo "No saved passphrase for $disk. Use '--configure' to save it." >&2
        return 1
    fi

    echo "$passphrase"
    return 0
}

# Function to save passphrase
save_passphrase() {
    local disk="$1"

    echo -n "Enter passphrase for $disk: "
    read -s passphrase
    echo

    # Check if passphrase already exists
    if security find-generic-password -a "$USER" -s "unlockVolume_$disk" >/dev/null 2>&1; then
        echo "Updating existing passphrase for $disk..."
        security delete-generic-password -a "$USER" -s "unlockVolume_$disk" > /dev/null 2>&1
    else
        echo "Saving new passphrase for $disk..."
    fi

    security add-generic-password -a "$USER" -s "unlockVolume_$disk" -w "$passphrase" > /dev/null
    echo "Passphrase saved for $disk."
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
usage() {
    echo "💬 Unlock encrypted APFS disks remotely via SSH."
    echo
    echo "Usage:"
    echo "  $script_name --configure <disk1> [disk2] ...         Save passphrases for disks"
    echo "  $script_name --unlock    <host> <disk1> [disk2] ...  Unlock disks on a remote host"
    echo
    echo "Options:"
    echo "  --unlock <host>  Unlock specified disks on a remote machine via SSH."
    echo "  --configure      Save passphrases for the specified disks in Keychain."
    echo "  --help           Show this help message."
    echo
    echo "Examples:"
    echo "  $script_name --configure \"Dingus\""
    echo "  $script_name --unlock mac-mini.local \"Dingus\""
    exit 1
}

# Argument parsing
if [[ "$#" -lt 2 ]]; then
    usage
fi

action=""
remote_host=""
disks=()

while [[ "$#" -gt 0 ]]; do
    case "$1" in
        --unlock)
            [[ -n "$2" ]] || { echo "Error: Missing host for --unlock"; usage; }
            action="unlock"
            remote_host="$2"
            shift 2
            ;;
        --configure)
            action="configure"
            shift
            ;;
        --help)
            usage
            ;;
        *)
            disks+=("$1")
            shift
            ;;
    esac
done

[[ "${#disks[@]}" -eq 0 ]] && { echo "Error: No disks specified."; usage; }

# Perform the requested action
case "$action" in
    "unlock")
        [[ -z "$remote_host" ]] && { echo "Error: Missing remote host."; usage; }
        for disk in "${disks[@]}"; do
            passphrase=$(get_passphrase "$disk") || { echo "Skipping $disk due to missing passphrase."; continue; }
            unlock_disk_remote "$remote_host" "$disk" "$passphrase"
        done
        echo "All specified disks have been processed."
        ;;
    "configure")
        for disk in "${disks[@]}"; do
            save_passphrase "$disk"
        done
        ;;
    *)
        echo "Error: Invalid action."; usage
        ;;
esac
