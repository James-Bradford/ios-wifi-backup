#!/bin/bash
set -e

BACKUP_BASE="/backups"
PAIR_DIR="/pairing"
KEEP_COUNT="${KEEP_COUNT:-7}"

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
  TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
  DEVICE_DIR="$BACKUP_BASE/$DEVICE_ID/$TIMESTAMP"
  mkdir -p "$DEVICE_DIR"

  DAY_OF_WEEK=$(date +%u) # 1=Mon, 7=Sun
  if [ "$DAY_OF_WEEK" -eq 7 ]; then
    EXTRA_ARGS="--full"
    echo "[Device Backup] Sunday detected, running FULL backup for $DEVICE_ID."
  else
    EXTRA_ARGS=""
    echo "[Device Backup] Running incremental backup for $DEVICE_ID."
  fi

  echo "[Device Backup] Backing up device $DEVICE_ID to $DEVICE_DIR..."
  if idevicebackup2 -u "$DEVICE_ID" backup $EXTRA_ARGS --encrypt --password "$BACKUP_PASSWORD" "$DEVICE_DIR"; then
    echo "[Device Backup] ✅ Backup for $DEVICE_ID succeeded at $(date)."
  else
    echo "[Device Backup] ❌ Backup for $DEVICE_ID failed at $(date)."
  fi

  # Rotate backups per device
  echo "[Device Backup] Rotating backups for $DEVICE_ID, keeping last $KEEP_COUNT copies..."
  cd "$BACKUP_BASE/$DEVICE_ID"
  ls -1dt */ | tail -n +$((KEEP_COUNT+1)) | xargs -r rm -rf
  echo
done
