#!/bin/bash
set -e

# Config
DEVICE_IP="${DEVICE_IP:?Must set DEVICE_IP env var (iPhone IP)}"
PAIR_ID="${PAIR_ID:?Must set PAIR_ID env var (device UDID / plist name)}"
SOCKET_PATH="/var/run/usbmuxd2.sock"
export USBMUXD_SOCKET_ADDRESS="$SOCKET_PATH"

# Make sure the run directory exists
mkdir -p /var/run

# Start usbmuxd (fosple fork) with Wi-Fi direct IP support
echo "[Entrypoint] Starting usbmuxd for $DEVICE_IP with pair record $PAIR_ID..."
/usr/local/bin/usbmuxd \
  --debug --allow-heartless-wifi --no-usb \
  -c "$DEVICE_IP" \
  --pair-record-id "$PAIR_ID" \
  -l /var/log/usbmuxd.log &

USBMUXD_PID=$!

# Give usbmuxd a moment to start
sleep 2
if ! kill -0 "$USBMUXD_PID" 2>/dev/null; then
  echo "[Entrypoint] ❌ usbmuxd failed to start. Check /var/log/usbmuxd.log."
  exit 1
fi

# Install cron job for backup.sh
CRON_SCHEDULE="${CRON_SCHEDULE:-0 3 * * *}"   # default: nightly at 3am
echo "$CRON_SCHEDULE root /usr/local/bin/backup.sh >> /var/log/cron.log 2>&1" > /etc/cron.d/device-backup
chmod 0644 /etc/cron.d/device-backup
crontab /etc/cron.d/device-backup
echo "[Entrypoint] Installed cron job: $CRON_SCHEDULE"

# Start cron
service cron start

# Keep both processes running
echo "[Entrypoint] Container ready. usbmuxd PID=$USBMUXD_PID (socket: $SOCKET_PATH)"
tail -F /var/log/cron.log /var/log/usbmuxd.log &
wait $USBMUXD_PID
