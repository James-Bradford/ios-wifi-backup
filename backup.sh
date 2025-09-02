#!/bin/bash
set -e

LOCKFILE="/tmp/backup.lock"
exec 9>"$LOCKFILE"
if ! flock -n 9; then
  echo "[Device Backup] Another backup is already running, exiting at $(date)."
  exit 0
fi

BACKUP_BASE="/backups"
PAIR_DIR="/var/lib/lockdown"   # host lockdown (read-only mount)
export LOCKDOWN_PATH="$PAIR_DIR"

DEVICE_IDS="$(idevice_id -n || true)"

if [ -z "$DEVICE_IDS" ]; then
  echo "[Device Backup] No Wi-Fi devices detected at $(date). Skipping."
  exit 0
fi

echo "[Device Backup] Devices detected at $(date):"
for DEVICE_ID in $DEVICE_IDS; do
  echo "  - $DEVICE_ID"
done
echo

for DEVICE_ID in $DEVICE_IDS; do
  DEVICE_DIR="$BACKUP_BASE/$DEVICE_ID"
  mkdir -p "$DEVICE_DIR"

  # Decide full vs incremental
  DAY_OF_WEEK=$(date +%u) # 1=Mon … 7=Sun
  FULL_FLAG=""
  if [ "$DAY_OF_WEEK" -eq 7 ]; then
    echo "[Device Backup] Sunday detected → clearing $DEVICE_DIR for FULL backup."
    rm -rf "$DEVICE_DIR"/*
    FULL_FLAG="--full"
  fi

  echo "[Device Backup] Ensuring encryption is enabled for $DEVICE_ID..."
  if ! idevicebackup2 -n -u "$DEVICE_ID" encryption on "$BACKUP_PASSWORD"; then
    echo "[Device Backup] ⚠️ Encryption already enabled (ok)."
  fi

  echo "[Device Backup] Backing up device $DEVICE_ID to $DEVICE_DIR..."
  if idevicebackup2 -n -u "$DEVICE_ID" backup $FULL_FLAG "$DEVICE_DIR"; then
    echo "[Device Backup] ✅ Backup for $DEVICE_ID succeeded at $(date)."
  else
    echo "[Device Backup] ❌ Backup for $DEVICE_ID failed at $(date). Cleaning up..."
    rm -rf "$DEVICE_DIR"/*
  fi

  echo
done
