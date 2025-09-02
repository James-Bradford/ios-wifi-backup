#!/bin/bash
set -e

# Dedicated socket path to avoid clashes with host usbmuxd
SOCKET_PATH="/var/run/usbmuxd2.sock"
export USBMUXD_SOCKET_ADDRESS="$SOCKET_PATH"

# Make sure the run directory exists
mkdir -p /var/run

# Start usbmuxd2 with Wi-Fi support + debug logs
echo "[Entrypoint] Starting usbmuxd (direct IP=$DEVICE_IP, pair=$PAIR_RECORD_ID)..."
/usr/local/sbin/usbmuxd --debug --allow-heartless-wifi -v -c "$DEVICE_IP" --pair-record-id "$PAIR_RECORD_ID" \
  >> /var/log/usbmuxd.log 2>&1 &
USBMUXD_PID=$!

# Give usbmuxd a moment to start
sleep 2

# Check if usbmuxd died already
if ! kill -0 "$USBMUXD_PID" 2>/dev/null; then
  echo "[Entrypoint] ❌ usbmuxd failed to start. Check /var/log/usbmuxd.log for details."
  exit 1
fi

# Install cron job for backup.sh
CRON_SCHEDULE="${CRON_SCHEDULE:-0 * * * *}"   # default: hourly
echo "$CRON_SCHEDULE root /usr/local/bin/backup.sh >> /var/log/cron.log 2>&1" > /etc/cron.d/device-backup
chmod 0644 /etc/cron.d/device-backup
crontab /etc/cron.d/device-backup
echo "[Entrypoint] Installed cron job: $CRON_SCHEDULE"

# Start cron
service cron start

# Run one backup immediately on startup (non-blocking)
echo "[Entrypoint] Triggering one immediate backup..."
/usr/local/bin/backup.sh >> /var/log/cron.log 2>&1 &

# Keep both processes running
echo "[Entrypoint] Container ready. usbmuxd PID=$USBMUXD_PID (socket: $SOCKET_PATH)"
# Tail logs so docker logs shows both cron and usbmuxd activity
tail -F /var/log/cron.log /var/log/usbmuxd.log &

# Wait on usbmuxd (this keeps the container alive)
wait $USBMUXD_PID
