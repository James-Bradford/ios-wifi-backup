#!/bin/bash
set -euo pipefail

# ---- single-run lock ----
LOCKFILE="/tmp/backup.lock"
exec 9>"$LOCKFILE"
if ! flock -n 9; then
  echo "[Device Backup] Another backup is already running, exiting at $(date)."
  exit 0
fi

# ---- config ----
BACKUP_BASE="/backups"
PAIR_DIR="/var/lib/lockdown"   # host lockdown (read-only mount)
export LOCKDOWN_PATH="$PAIR_DIR"

TODAY="$(date +%F)"
DOW="$(date +%u)"  # 1=Mon ... 7=Sun

# Prefer network (Wi-Fi) discovery via usbmuxd2
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
  MARKER="$DEVICE_DIR/.last_successful"
  mkdir -p "$DEVICE_DIR"

  # If today's backup already completed, skip.
  if [ -f "$MARKER" ] && grep -qx "$TODAY" "$MARKER"; then
    echo "[Device Backup] $DEVICE_ID already backed up successfully today ($TODAY). Skipping."
    echo
    continue
  fi

  # Sunday = force full backup, and start from clean slate to avoid stale state.
  if [ "$DOW" -eq 7 ]; then
    echo "[Device Backup] Sunday detected — forcing FULL backup for $DEVICE_ID."
    # Clean out the dir for a truly fresh full backup
    rm -rf "$DEVICE_DIR"/*
    FULL_FLAG="--full"
  else
    FULL_FLAG=""
    # If a prior run left a failed status, warn (we’ll retry incrementally until success)
    if [ -f "$DEVICE_DIR/Status.plist" ] && grep -q "Failed" "$DEVICE_DIR/Status.plist"; then
      echo "[Device Backup] Note: previous run left a failed state for $DEVICE_ID; retrying incrementally."
    fi
  fi

  echo "[Device Backup] Backing up $DEVICE_ID to $DEVICE_DIR..."
  if idevicebackup2 -n -u "$DEVICE_ID" backup $FULL_FLAG "$DEVICE_DIR"; then
    echo "$TODAY" > "$MARKER"
    echo "[Device Backup] ✅ Backup for $DEVICE_ID succeeded at $(date)."
  else
    echo "[Device Backup] ❌ Backup for $DEVICE_ID failed at $(date). Will retry on next cron tick."
  fi

  echo
done
