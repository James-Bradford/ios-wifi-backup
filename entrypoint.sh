#!/bin/bash
set -e

# Export env so libimobiledevice uses the usbmuxd2 socket
export USBMUXD_SOCKET_ADDRESS=/var/run/usbmuxd

# Start usbmuxd2 in the foreground with verbose logging
echo "[Entrypoint] Starting usbmuxd2..."
/usr/local/bin/usbmuxd2 -f -v &
USBMUXD_PID=$!

# Give usbmuxd2 a moment to create the socket
sleep 2

# Install cron job for backup.sh
CRON_SCHEDULE="${CRON_SCHEDULE:-0 3 * * *}"   # default: nightly at 3am
echo "$CRON_SCHEDULE root /usr/local/bin/backup.sh >> /var/log/cron.log 2>&1" > /etc/cron.d/device-backup
chmod 0644 /etc/cron.d/device-backup
crontab /etc/cron.d/device-backup
echo "[Entrypoint] Installed cron job: $CRON_SCHEDULE"

# Start cron
service cron start

# Keep both processes running
echo "[Entrypoint] Container ready. usbmuxd2 PID=$USBMUXD_PID"
# Tail cron logs so docker logs shows activity
tail -F /var/log/cron.log &

# Wait on usbmuxd2 (this keeps the container alive)
wait $USBMUXD_PID
