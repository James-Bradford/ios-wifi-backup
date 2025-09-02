#!/bin/bash
set -e

# Default: run every hour
CRON_SCHEDULE="${CRON_SCHEDULE:-0 * * * *}"

# Write cron job
echo "$CRON_SCHEDULE root /usr/local/bin/backup.sh >> /var/log/cron.log 2>&1" > /etc/cron.d/device-backup
chmod 0644 /etc/cron.d/device-backup

# Apply cron job
crontab /etc/cron.d/device-backup

echo "[Device Backup] Installed job: $CRON_SCHEDULE"

# Start cron in foreground
cron -f
