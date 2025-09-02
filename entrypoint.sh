#!/bin/bash
set -e

# Where pairing records live
PAIR_DIR="/var/lib/lockdown"
SOCKET_PATH="/var/run/usbmuxd.sock"
export USBMUXD_SOCKET_ADDRESS="$SOCKET_PATH"

# Ensure dirs exist
mkdir -p /var/run "$PAIR_DIR"

# Direct IP mode requires DEVICE_IP and PAIR_ID
if [[ -n "$DEVICE_IP" && -n "$PAIR_ID" ]]; then
  echo "[Entrypoint] Starting usbmuxd (direct IP=$DEVICE_IP, pair=$PAIR_ID)..."
  /usr/local/sbin/usbmuxd \
    --debug --allow-heartless-wifi --no-usb \
    -c "$DEVICE_IP" \
    --pair-record-id "$PAIR_ID" \
    -l /var/log/usbmuxd.log &
else
  echo "[Entrypoint] Starting usbmuxd (Avahi mode)..."
  /usr/local/sbin/usbmuxd \
    --debug --allow-heartless-wifi \
    -l /var/log/usbmuxd.log &
fi

USBMUXD_PID=$!
sleep 2

if ! kill -0 "$USBMUXD_PID" 2>/dev/null; then
  echo "[Entrypoint] ❌ usbmuxd failed to start. Check /var/log/usbmuxd.log"
  exit 1
fi

# Install cron job for backups
CRON_SCHEDULE="${CRON_SCHEDULE:-0 * * * *}" # Hourly by default
echo "$CRON_SCHEDULE root /usr/local/bin/backup.sh >> /var/log/cron.log 2>&1" > /etc/cron.d/device-backup
chmod 0644 /etc/cron.d/device-backup
crontab /etc/cron.d/device-backup
echo "[Entrypoint] Installed cron job: $CRON_SCHEDULE"

# Start cron
service cron start

echo "[Entrypoint] Triggering one immediate backup..."
/usr/local/bin/backup.sh >> /var/log/cron.log 2>&1 &

# Tail logs
tail -F /var/log/cron.log /var/log/usbmuxd.log &
TAIL_PID=$!

echo "[Entrypoint] Container ready. usbmuxd PID=$USBMUXD_PID"

# Keep container alive on usbmuxd
wait $USBMUXD_PID
