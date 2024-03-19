#!/bin/bash

# Exit script on error
set -e

# Initialize variables
APP_VERSION=""
BASE_DIRECTORY=""
EXCLUDE_OS=""

# Function to display usage
usage() {
    echo "Cider Distribution Tool v1.0"
    echo "Requires: Authorized Butler install."
    echo "Usage: $0 -v <app_version> -d <directory> [-e <exclude_os>]"
    echo "  -v <app_version>    Specify the app version to upload."
    echo "  -d <directory>      Specify the directory containing the installers."
    echo "  -e <exclude_os>     Optional. Comma-separated list of OS to exclude (e.g., windows,macOS)."
    exit 1
}

# Parse command-line options
while getopts ":v:d:e:" opt; do
    case ${opt} in
        v)
            APP_VERSION=$OPTARG
            ;;
        d)
            BASE_DIRECTORY=$OPTARG
            ;;
        e)
            EXCLUDE_OS=$OPTARG
            ;;
        \?)
            echo "Invalid option: $OPTARG" 1>&2
            usage
            ;;
        :)
            echo "Invalid option: $OPTARG requires an argument" 1>&2
            usage
            ;;
    esac
done
shift $((OPTIND -1))

# Check if the app version and directory were set
if [ -z "$APP_VERSION" ] || [ -z "$BASE_DIRECTORY" ]; then
    usage
fi

# Convert excluded OS list into an array
IFS=',' read -r -a EXCLUDE_OS_ARRAY <<< "$EXCLUDE_OS"

# Start of the script
echo "======================="
echo "Starting upload process"
echo "Version: $APP_VERSION"
echo "Directory: $BASE_DIRECTORY"
[ ! -z "$EXCLUDE_OS" ] && echo "Excluding OS: $EXCLUDE_OS"
echo "======================="

# Define Itch.io user/project
ITCHIO_USERNAME="cidercollective"
ITCHIO_PROJECT_NAME="cider"

# Function to upload a file to Itch.io using Butler
upload_with_butler() {
    local file_path=$1
    local channel_name=$2

    echo "Uploading $file_path to channel $channel_name..."
    butler push "$file_path" "$ITCHIO_USERNAME/$ITCHIO_PROJECT_NAME:$channel_name"
}

# Check if an OS should be excluded
should_exclude() {
    local os=$1
    for exclude_os in "${EXCLUDE_OS_ARRAY[@]}"; do
        if [ "$os" == "$exclude_os" ]; then
            return 0
        fi
    done
    return 1
}

# Find and display files to process
echo "Files to be processed:"
find "$BASE_DIRECTORY" -type f \( -name "*.msi" -o -name "*.dmg" -o -name "*.pkg.tar.gz" -o -name "*.rpm" -o -name "*.deb" -o -name "*.AppImage" \) | while read file_path; do
    echo "$file_path"
done
echo "======================="

# Actual processing and upload
find "$BASE_DIRECTORY" -type f \( -name "*.msi" -o -name "*.dmg" -o -name "*.pkg.tar.gz" -o -name "*.rpm" -o -name "*.deb" -o -name "*.AppImage" \) | while read file_path; do
    case "$file_path" in
        *x64_en-US.msi) os="windows" arch="x64";;
        *-arm64.dmg) os="macOS" arch="arm64";;
        *-x64.dmg) os="macOS" arch="x64";;
        *-x86_64.pkg.tar.gz) os="arch-linux" arch="x86_64";;
        *x86_64.rpm) os="fedora" arch="x86_64";;
        *_amd64.deb) os="debian" arch="amd64";;
        *.AppImage) os="linux" arch="universal";;
        *) echo "Unknown file format: $file_path" && continue;;
    esac

    # Skip excluded OS
    if should_exclude "$os"; then
        echo "Skipping excluded OS ($os) file: $file_path"
        continue
    fi

    # Construct the channel name using OS, architecture, and app version
    channel_name="${os}-${arch}-${APP_VERSION}"

    # Upload the file
    upload_with_butler "$file_path" "$channel_name"
done

echo "Upload process completed."
