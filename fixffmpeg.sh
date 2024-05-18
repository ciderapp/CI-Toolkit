#!/bin/bash
# This script is intended to fix the ffmpeg issue on Cider-Bot-Private
# It will install the correct ffmpeg version and the necessary dependencies
# It will also install the correct GPU drivers for Intel QuickSync
# Copyright (C) 2024 Cider Collective

# Install debug tools / dependencies
apt update
apt install -y wget gnupg vainfo gpg-agent libllvm11

# Exchange the default ffmpeg deb with the one from HTTP and install it, link it to /usr/bin/ffmpeg
wget https://cdn.cider.sh/jellyfin-ffmpeg6_6.0.1-6-bullseye_amd64.deb
dpkg -i jellyfin-ffmpeg6_6.0.1-6-bullseye_amd64.deb
apt --fix-missing install
ln -s /usr/lib/jellyfin-ffmpeg/ffmpeg /usr/bin/ffmpeg

# Install i965 driver (default gpu driver, uncomment if you have <9th gen CPU)
# apt install i965-va-driver-shaders

# Install iHD driver (iHD quicksync driver, better performance cf https://www.reddit.com/r/jellyfin/comments/r5pur8/best_transcoding_settings_for_synology_ds920/ only if you have a >9th gen CPU)
wget -qO - https://repositories.intel.com/graphics/intel-graphics.key | apt-key add -
echo 'deb [arch=amd64] https://repositories.intel.com/graphics/ubuntu focal main' >> /etc/apt/sources.list
apt update
apt install -y intel-media-va-driver-non-free

