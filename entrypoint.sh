#!/bin/bash
set -e

# Start usbmuxd2 (creates /var/run/usbmuxd by default)
# If it ever changes, you can point LibiMobileDevice at the socket via USBMUXD_SOCKET_ADDRESS
usbmuxd2 &

# Export for good measure (libusbmuxd honors this)
export USBMUXD_SOCKET_ADDRESS=/var/run/usbmuxd

# Cron schedule (default every 15 minutes)
CRON_SCHEDULE="${CRON_SCHEDULE:-*/15 * * * *}"
echo "$CRON_SCHEDULE root /usr/local/bin/backup.sh >> /var/log/cron.log 2>&1" > /etc/cron.d/device-backup
chmod 0644 /etc/cron.d/device-backup
crontab /etc/cron.d/device-backup
echo "[Device Backup] Installed job: $CRON_SCHEDULE"

# Start cron in foreground
cron -f
