# ---------- Builder ----------
FROM ubuntu:22.04 as builder
ENV DEBIAN_FRONTEND=noninteractive

# Build dependencies
RUN apt-get update && apt-get install -y \
  build-essential autoconf automake libtool pkg-config git \
  clang \
  libssl-dev libusb-1.0-0-dev libplist-dev libcurl4-openssl-dev \
  libavahi-client-dev libavahi-common-dev \
  ca-certificates curl \
  && rm -rf /var/lib/apt/lists/*

# libplist
RUN git clone https://github.com/libimobiledevice/libplist.git /tmp/libplist \
  && cd /tmp/libplist && ./autogen.sh && make -j"$(nproc)" && make install && ldconfig \
  && rm -rf /tmp/libplist

# libimobiledevice-glue
RUN git clone https://github.com/libimobiledevice/libimobiledevice-glue.git /tmp/glue \
  && cd /tmp/glue && ./autogen.sh && make -j"$(nproc)" && make install && ldconfig \
  && rm -rf /tmp/glue

# libusbmuxd (client library; env var support for USBMUXD_SOCKET_ADDRESS)
RUN git clone https://github.com/libimobiledevice/libusbmuxd.git /tmp/libusbmuxd \
  && cd /tmp/libusbmuxd && ./autogen.sh && make -j"$(nproc)" && make install && ldconfig \
  && rm -rf /tmp/libusbmuxd

# libtatsu
RUN git clone https://github.com/libimobiledevice/libtatsu.git /tmp/libtatsu \
  && cd /tmp/libtatsu && ./autogen.sh && make -j"$(nproc)" && make install && ldconfig \
  && rm -rf /tmp/libtatsu

# libimobiledevice (tools: idevicebackup2, idevice_id, idevicepair, etc.)
RUN git clone https://github.com/libimobiledevice/libimobiledevice.git /tmp/libimobiledevice \
  && cd /tmp/libimobiledevice && ./autogen.sh && make -j"$(nproc)" && make install && ldconfig \
  && rm -rf /tmp/libimobiledevice

# libgeneral (dependency for usbmuxd2)
RUN git clone https://github.com/tihmstar/libgeneral.git /tmp/libgeneral \
  && cd /tmp/libgeneral && ./autogen.sh && ./configure --prefix=/usr/local \
  && make -j"$(nproc)" && make install && ldconfig \
  && rm -rf /tmp/libgeneral

# usbmuxd2 (fosple fork with direct IP support)
RUN git clone https://github.com/fosple/usbmuxd2.git /tmp/usbmuxd2 \
  && cd /tmp/usbmuxd2 && ./autogen.sh && ./configure --prefix=/usr/local CC=clang CXX=clang++ \
  && make -j"$(nproc)" && make install && ldconfig \
  && cp /usr/local/sbin/usbmuxd2 /usr/local/bin/usbmuxd \
  && rm -rf /tmp/usbmuxd2

# ---------- Runtime ----------
FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
  avahi-utils cron \
  && rm -rf /var/lib/apt/lists/*

# Copy built libs + tools
COPY --from=builder /usr/local /usr/local

# Make sure runtime linker knows about new libs
RUN echo "/usr/local/lib" > /etc/ld.so.conf.d/libimobiledevice.conf && ldconfig

# Scripts
COPY backup.sh /usr/local/bin/backup.sh
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /usr/local/bin/backup.sh /entrypoint.sh

CMD ["/entrypoint.sh"]
