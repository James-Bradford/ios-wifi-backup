#!/bin/bash
set -e

# Dedicated socket path for container's usbmuxd2
SOCKET_PATH="/var/run/usbmuxd"
export USBMUXD_SOCKET_ADDRESS="$SOCKET_PATH"

# Make sure the run directory exists
mkdir -p /var/run

# Start usbmuxd2 with Wi-Fi support + daemon mode
echo "[Entrypoint] Starting usbmuxd2 (daemon mode) on $SOCKET_PATH..."
/usr/local/bin/usbmuxd2 --debug --allow-heartless-wifi -v --no-usb -d -l /var/log/usbmuxd2.log
USBMUXD_PID=$!

# Give usbmuxd2 a moment to start
sleep 2

# Check if usbmuxd2 is running
if ! kill -0 "$USBMUXD_PID" 2>/dev/null; then
  echo "[Entrypoint] ❌ usbmuxd2 failed to start. Check /var/log/usbmuxd2.log for details."
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

# Container ready
echo "[Entrypoint] Container ready. usbmuxd2 PID=$USBMUXD_PID (socket: $SOCKET_PATH)"

# Tail logs so `docker logs` shows activity
exec tail -F /var/log/cron.log /var/log/usbmuxd2.log
