#!/bin/bash
set -e

BACKUP_BASE="/backups"
PAIR_DIR="/pairing"
KEEP_COUNT="${KEEP_COUNT:-7}"

export LOCKDOWN_PATH="$PAIR_DIR"

# Check for connected devices (USB or Wi-Fi)
DEVICE_ID=$(idevice_id -l | head -n1)

if [ -z "$DEVICE_ID" ]; then
  echo "[Device Backup] No device detected at $(date). Skipping."
  exit 0
fi

# Create a new timestamped backup dir
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
BACKUP_DIR="$BACKUP_BASE/$TIMESTAMP"
mkdir -p "$BACKUP_DIR"

# Decide whether to force a full backup (every Sunday)
DAY_OF_WEEK=$(date +%u) # 1=Mon, 7=Sun
if [ "$DAY_OF_WEEK" -eq 7 ]; then
  EXTRA_ARGS="--full"
  echo "[Device Backup] Sunday detected, running FULL backup."
else
  EXTRA_ARGS=""
  echo "[Device Backup] Running incremental backup."
fi

echo "[Device Backup] Found device $DEVICE_ID at $(date). Starting backup into $BACKUP_DIR..."
if idevicebackup2 backup $EXTRA_ARGS --encrypt --password "$BACKUP_PASSWORD" "$BACKUP_DIR"; then
  echo "[Device Backup] Backup succeeded at $(date)."
else
  echo "[Device Backup] Backup failed at $(date)."
fi

# Rotate old backups
echo "[Device Backup] Rotating backups, keeping last $KEEP_COUNT copies..."
cd "$BACKUP_BASE"
ls -1dt */ | tail -n +$((KEEP_COUNT+1)) | xargs -r rm -rf
