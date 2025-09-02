#!/bin/bash
set -e

# Config: IP + Pair Record ID must be passed in
DEVICE_IP="${DEVICE_IP:?You must set DEVICE_IP env var}"
PAIR_ID="${PAIR_ID:?You must set PAIR_ID env var}"

# Dedicated socket path
SOCKET_PATH="/var/run/usbmuxd2.sock"
export USBMUXD_SOCKET_ADDRESS="$SOCKET_PATH"

mkdir -p /var/run

# Start usbmuxd2 in direct-IP mode
echo "[Entrypoint] Starting usbmuxd2 for $DEVICE_IP with pair record $PAIR_ID..."
/usr/local/bin/usbmuxd2 \
  --debug \
  --allow-heartless-wifi \
  --no-usb \
  -c "$DEVICE_IP" \
  --pair-record-id "$PAIR_ID" \
  -l /var/log/usbmuxd2.log &
USBMUXD_PID=$!

sleep 2

if ! kill -0 "$USBMUXD_PID" 2>/dev/null; then
  echo "[Entrypoint] ❌ usbmuxd2 failed to start. Check /var/log/usbmuxd2.log."
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

echo "[Entrypoint] Container ready. usbmuxd2 PID=$USBMUXD_PID (socket: $SOCKET_PATH)"

# Tail logs for visibility
exec tail -F /var/log/cron.log /var/log/usbmuxd2.log
