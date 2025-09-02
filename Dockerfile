FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    build-essential autoconf automake libtool pkg-config git \
    libssl-dev libplist-dev libusb-1.0-0-dev \
    avahi-utils ca-certificates curl \
    && rm -rf /var/lib/apt/lists/*

# libplist
RUN git clone https://github.com/libimobiledevice/libplist.git /tmp/libplist \
  && cd /tmp/libplist && ./autogen.sh && make -j && make install && ldconfig

# libimobiledevice-glue
RUN git clone https://github.com/libimobiledevice/libimobiledevice-glue.git /tmp/glue \
  && cd /tmp/glue && ./autogen.sh && make -j && make install && ldconfig

# libusbmuxd (client lib + tools like inetcat, iproxy with --network)
RUN git clone https://github.com/libimobiledevice/libusbmuxd.git /tmp/libusbmuxd \
  && cd /tmp/libusbmuxd && ./autogen.sh && make -j && make install && ldconfig

# libimobiledevice (idevicebackup2, idevice_id, idevicepair, etc.)
RUN git clone https://github.com/libimobiledevice/libimobiledevice.git /tmp/libimobiledevice \
  && cd /tmp/libimobiledevice && ./autogen.sh && make -j && make install && ldconfig

# optional: ifuse, usbmuxd daemon for USB mode (not required for Wi-Fi)
