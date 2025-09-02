FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    libimobiledevice6 \
    libimobiledevice-utils \
    usbmuxd \
    cron \
    && rm -rf /var/lib/apt/lists/*

COPY backup.sh /usr/local/bin/backup.sh
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /usr/local/bin/backup.sh /entrypoint.sh

CMD ["/entrypoint.sh"]
