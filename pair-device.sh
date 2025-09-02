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

case "$OS" in
  Linux)
    echo "[Pairing Script] Detected Linux."
    install_linux_deps
    echo "Plug in your iPhone, unlock it, and tap 'Trust this computer' if prompted."
    idevicepair pair
    echo
    echo "[Pairing Script] Pairing complete."
    echo "Pairing records are stored here: /var/lib/lockdown/"
    echo "Copy those files into your server's 'pairing' folder if needed."
    ;;
    
  Darwin)
    echo "[Pairing Script] Detected macOS."
    install_macos_deps
    echo "Plug in your iPhone, unlock it, and tap 'Trust this computer' if prompted."
    echo
    echo "[Pairing Script] Pairing complete."
    echo "Pairing records are stored here: ~/Library/Lockdown/"
    echo "Copy those files into your server's 'pairing' folder if needed."
    ;;
    
  *)
    echo "[Pairing Script] Unsupported OS: $OS"
    echo "On Windows, use iTunes/Finder to pair your device, then copy the Lockdown records manually."
    exit 1
    ;;
esac

echo
echo "[Pairing Script] Done."
