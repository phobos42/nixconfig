#! /usr/bin/env nix-shell
#! nix-shell -i bash -p bash pv

# ZFS Dataset Replication Script
# Replicates multiple ZFS datasets to a remote server
# Usage: ./replicate-datasets.sh

set -e  # Exit on error

# Configuration
REMOTE_USER="box"
REMOTE_HOST="192.168.1.15"
REMOTE_POOL="tank"  # Adjust if the remote pool name is different

# Datasets to replicate
DATASETS=(
    "tank/services"
    "tank/shack/cloud/immich"
    "tank/shack/cloud/nextcloud"
    "tank/shack/cloud/syncthing"
    "tank/shack/cloud/vaultwarden"
)

echo "Starting ZFS dataset replication to ${REMOTE_USER}@${REMOTE_HOST}"
echo "=================================================="

# Function to replicate a single dataset
replicate_dataset() {
    local dataset=$1
    echo ""
    echo "Replicating: $dataset"
    
    # Create initial full snapshot if it doesn't exist on remote
    local snapshot_name="${dataset}@initial-$(date +%s)"
    
    echo "Creating snapshot: $snapshot_name"
    sudo zfs snapshot -r "$snapshot_name"
    
    # Ensure parent datasets exist on remote
    local parent_dataset="${dataset%/*}"
    while [ "$parent_dataset" != "tank" ] && [ -n "$parent_dataset" ]; do
        local remote_parent="${REMOTE_POOL}/${parent_dataset#tank/}"
        if ! ssh "${REMOTE_USER}@${REMOTE_HOST}" "zfs list \"$remote_parent\" > /dev/null 2>&1"; then
            echo "Creating parent dataset: $remote_parent"
            ssh "${REMOTE_USER}@${REMOTE_HOST}" "zfs create -p \"$remote_parent\""
        fi
        parent_dataset="${parent_dataset%/*}"
    done
    
    echo "Sending to remote server..."
    # Get the size of the snapshot to show progress
    local snapshot_size=$(sudo zfs list -Hp -o used "$snapshot_name" 2>/dev/null || echo "0")
    
    if [ "$snapshot_size" -gt 0 ]; then
        sudo zfs send -R "$snapshot_name" | pv -s "$snapshot_size" | ssh "${REMOTE_USER}@${REMOTE_HOST}" "zfs receive -F -u ${REMOTE_POOL}/${dataset#tank/}"
    else
        sudo zfs send -R "$snapshot_name" | pv | ssh "${REMOTE_USER}@${REMOTE_HOST}" "zfs receive -F -u ${REMOTE_POOL}/${dataset#tank/}"
    fi
    
    if [ $? -eq 0 ]; then
        echo "✓ Successfully replicated $dataset"
    else
        echo "✗ Failed to replicate $dataset"
        return 1
    fi
}

# Replicate each dataset
failed_datasets=()
for dataset in "${DATASETS[@]}"; do
    if ! replicate_dataset "$dataset"; then
        failed_datasets+=("$dataset")
    fi
done

echo ""
echo "=================================================="
echo "Replication Summary"
echo "=================================================="

if [ ${#failed_datasets[@]} -eq 0 ]; then
    echo "✓ All datasets replicated successfully!"
else
    echo "✗ The following datasets failed to replicate:"
    printf '%s\n' "${failed_datasets[@]}"
    exit 1
fi
