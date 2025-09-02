#!/bin/bash
set -e

BACKUP_BASE="/backups"
PAIR_DIR="/var/lib/lockdown"   # use host’s lockdown directory
KEEP_COUNT=1                   # no rotation needed, we only keep latest

export LOCKDOWN_PATH="$PAIR_DIR"

DEVICE_IDS=$(idevice_id -l)

if [ -z "$DEVICE_IDS" ]; then
  echo "[Device Backup] No devices detected at $(date). Skipping."
  exit 0
fi

echo "[Device Backup] Devices detected at $(date):"
for ID in $DEVICE_IDS; do
  echo "  - $ID"
done
echo

for DEVICE_ID in $DEVICE_IDS; do
  DEVICE_DIR="$BACKUP_BASE/$DEVICE_ID/latest"

  echo "[Device Backup] Preparing backup directory for $DEVICE_ID..."
  rm -rf "$DEVICE_DIR"
  mkdir -p "$DEVICE_DIR"

  DAY_OF_WEEK=$(date +%u) # 1=Mon, 7=Sun
  if [ "$DAY_OF_WEEK" -eq 7 ]; then
    EXTRA_ARGS="--full"
    echo "[Device Backup] Sunday detected, running FULL backup for $DEVICE_ID."
  else
    EXTRA_ARGS=""
    echo "[Device Backup] Running incremental-style backup for $DEVICE_ID (will overwrite latest)."
  fi

  echo "[Device Backup] Ensuring encryption is enabled for $DEVICE_ID..."
  if ! idevicebackup2 -u "$DEVICE_ID" encryption on "$BACKUP_PASSWORD"; then
    echo "[Device Backup] ⚠️ Failed to enable encryption for $DEVICE_ID (it may already be set)."
  fi

  echo "[Device Backup] Backing up device $DEVICE_ID to $DEVICE_DIR..."
  if idevicebackup2 -u "$DEVICE_ID" backup $EXTRA_ARGS "$DEVICE_DIR"; then
    echo "[Device Backup] ✅ Backup for $DEVICE_ID succeeded at $(date)."
  else
    echo "[Device Backup] ❌ Backup for $DEVICE_ID failed at $(date)."
  fi

  echo
done
