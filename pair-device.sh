#!/bin/bash
set -e

echo "[Pairing Script] Starting…"

OS=$(uname -s)

install_linux_deps() {
  if command -v apt &>/dev/null; then
    sudo apt update
    sudo apt install -y libimobiledevice-utils usbmuxd
  elif command -v dnf &>/dev/null; then
    sudo dnf install -y libimobiledevice usbmuxd
  elif command -v pacman &>/dev/null; then
    sudo pacman -Sy --noconfirm libimobiledevice usbmuxd
  else
    echo "Unsupported package manager. Please install libimobiledevice + usbmuxd manually."
    exit 1
  fi
}

install_macos_deps() {
  if ! command -v brew &>/dev/null; then
    echo "Homebrew not found. Please install Homebrew first: https://brew.sh/"
    exit 1
  fi
  brew install libimobiledevice usbmuxd
}

LOCKDOWN_DIR=""
case "$OS" in
  Linux)
    echo "[Pairing Script] Detected Linux."
    install_linux_deps
    LOCKDOWN_DIR="/var/lib/lockdown"
    ;;
  Darwin)
    echo "[Pairing Script] Detected macOS."
    install_macos_deps
    LOCKDOWN_DIR="/var/db/lockdown"
    ;;
  *)
    echo "[Pairing Script] Unsupported OS: $OS"
    echo "On Windows, use iTunes/Finder to pair your device."
    echo "Pairing records will be under: %ProgramData%\\Apple\\Lockdown\\<UDID>.plist"
    exit 1
    ;;
esac

echo
echo "➡️  Plug in your iPhone with a USB cable."
echo "➡️  Unlock it and tap 'Trust this computer' if prompted."
read -n1 -r -p "Press any key once you've done this to continue..."
echo

echo "[Pairing Script] Running idevicepair pair..."
idevicepair pair || true
echo "[Pairing Script] Finished pairing attempt."

echo
echo "[Pairing Script] Checking for connected devices..."
DEVICE_ID=$(idevice_id -l | head -n1)

if [ -z "$DEVICE_ID" ]; then
  echo "⚠️  No device detected. Make sure the phone is connected, unlocked, and trusted."
else
  echo "✅ Device detected: $DEVICE_ID"
  echo "Pairing record should be here: $LOCKDOWN_DIR/$DEVICE_ID.plist"
fi

echo
echo "[Pairing Script] Done."
