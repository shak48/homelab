#!/bin/bash
set -euo pipefail

SWAP_VOL="rpool/swap"
SWAP_DEV="/dev/zvol/${SWAP_VOL}"
SWAP_SIZE="64G"

echo "Creating ZFS swap volume..."
zfs create -V ${SWAP_SIZE} \
  -b 4096 \
  -o compression=off \
  -o logbias=throughput \
  -o sync=always \
  -o primarycache=metadata \
  "${SWAP_VOL}"

echo "Formatting swap..."
mkswap "${SWAP_DEV}"

echo "Activating swap..."
swapon "${SWAP_DEV}"

echo "Making swap persistent in /etc/fstab..."
grep -q "${SWAP_DEV}" /etc/fstab || echo "${SWAP_DEV} none swap defaults 0 0" >> /etc/fstab

echo "Verifying swap status..."
swapon --show

echo "ZFS swap setup complete."
