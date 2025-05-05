#!/bin/bash
set -euo pipefail

# === Configuration ===
DISK1="/dev/sdX"  # TODO: Replace with actual device (e.g., /dev/sdb)
DISK2="/dev/sdY"  # TODO: Replace with actual device (e.g., /dev/sdc)
POOL="tankmirror"
DATASETS=("share" "backup")

# === Confirm ===
echo "WARNING: This will wipe ALL data on $DISK1 and $DISK2!"
read -rp "Type YES to continue: " CONFIRM
if [[ "$CONFIRM" != "YES" ]]; then
  echo "Aborted."
  exit 1
fi

# === Check for ZFS ===
if ! command -v zpool >/dev/null; then
  echo "ZFS not installed. Aborting."
  exit 1
fi

# === Wipe old partition tables (use with caution) ===
echo "Wiping partition tables on $DISK1 and $DISK2..."
sudo wipefs -a "$DISK1"
sudo wipefs -a "$DISK2"

# === Create ZFS RAID1 Pool ===
echo "Creating ZFS pool: $POOL (mirror)..."
sudo zpool create -f -o ashift=12 "$POOL" mirror "$DISK1" "$DISK2"

# === Create datasets ===
for ds in "${DATASETS[@]}"; do
  echo "Creating dataset: $POOL/$ds"
  sudo zfs create "$POOL/$ds"
done

# === Set permissions ===
sudo chmod 770 /$POOL/{share,backup}
sudo chown root:root /$POOL/{share,backup}

# === Done ===
echo "ZFS RAID1 pool '$POOL' and datasets '${DATASETS[*]}' are ready."
zpool status "$POOL"
zfs list
