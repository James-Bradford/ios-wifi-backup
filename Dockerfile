# ---------- Builder ----------
FROM ubuntu:22.04 as builder

ENV DEBIAN_FRONTEND=noninteractive

# Build dependencies
RUN apt-get update && apt-get install -y \
    build-essential autoconf automake libtool pkg-config git \
    libssl-dev libusb-1.0-0-dev libplist-dev \
    ca-certificates curl \
    && rm -rf /var/lib/apt/lists/*

# libplist
RUN git clone https://github.com/libimobiledevice/libplist.git /tmp/libplist \
  && cd /tmp/libplist && ./autogen.sh && make -j$(nproc) && make install && ldconfig

# libimobiledevice-glue
RUN git clone https://github.com/libimobiledevice/libimobiledevice-glue.git /tmp/glue \
  && cd /tmp/glue && ./autogen.sh && make -j$(nproc) && make install && ldconfig

# libusbmuxd
RUN git clone https://github.com/libimobiledevice/libusbmuxd.git /tmp/libusbmuxd \
  && cd /tmp/libusbmuxd && ./autogen.sh && make -j$(nproc) && make install && ldconfig

# libtatsu (needed for libimobiledevice HEAD)
RUN git clone https://github.com/libimobiledevice/libtatsu.git /tmp/libtatsu \
  && cd /tmp/libtatsu && ./autogen.sh && make -j$(nproc) && make install && ldconfig

# libimobiledevice (backup tools, network support)
RUN git clone https://github.com/libimobiledevice/libimobiledevice.git /tmp/libimobiledevice \
  && cd /tmp/libimobiledevice && ./autogen.sh && make -j$(nproc) && make install && ldconfig

# ---------- Runtime ----------
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    avahi-utils cron \
    && rm -rf /var/lib/apt/lists/*

# Copy built libs + tools
COPY --from=builder /usr/local /usr/local

# Copy scripts
COPY backup.sh /usr/local/bin/backup.sh
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /usr/local/bin/backup.sh /entrypoint.sh

CMD ["/entrypoint.sh"]
