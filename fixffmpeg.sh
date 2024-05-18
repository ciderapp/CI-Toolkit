#!/bin/bash

# Install debug tools
apt update
apt install -y wget gnupg vainfo gpg-agent

# Upgrade jellyfin-ffmpeg to latest version 4.4.1-4-bullseye (increases transcoding perfs a lot)
echo "deb http://http.us.debian.org/debian stable main contrib non-free" | tee -a /etc/apt/sources.list
apt update
apt install -y -u jellyfin-ffmpeg

# Install i965 driver (default gpu driver, uncomment if you have <9th gen CPU)
# apt install i965-va-driver-shaders

# Install iHD driver (iHD quicksync driver, better performance cf https://www.reddit.com/r/jellyfin/comments/r5pur8/best_transcoding_settings_for_synology_ds920/ only if you have a >9th gen CPU)
wget -qO - https://repositories.intel.com/graphics/intel-graphics.key | apt-key add -
echo 'deb [arch=amd64] https://repositories.intel.com/graphics/ubuntu focal main' >> /etc/apt/sources.list
apt update
apt install -y intel-media-va-driver-non-free
