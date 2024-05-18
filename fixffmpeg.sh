#!/bin/bash
# This script is intended to fix the ffmpeg issue on Cider-Bot-Private
# It will install the correct ffmpeg version and the necessary dependencies
# It will also install the correct GPU drivers for Intel QuickSync
# Copyright (C) 2024 Cider Collective

# Install debug tools / dependencies
apt update
apt install -y wget gnupg vainfo gpg-agent libllvm11
apt remove -y ffmpeg

# Exchange the default ffmpeg deb with the one from HTTP and install it, link it to /usr/bin/ffmpeg
wget https://cdn.cider.sh/jellyfin-ffmpeg6_6.0.1-6-bullseye_amd64.deb
dpkg -i jellyfin-ffmpeg6_6.0.1-6-bullseye_amd64.deb
rm jellyfin-ffmpeg6_6.0.1-6-bullseye_amd64.deb

# Install i965 driver (default gpu driver, uncomment if you have <9th gen CPU)
# apt install i965-va-driver-shaders

apt update
apt install -y intel-media-va-driver-non-free

# Link and cleanup.

apt --fix-missing install -y
apt --fix-broken install -y
ln -s /usr/lib/jellyfin-ffmpeg/ffmpeg /usr/bin/ffmpeg
