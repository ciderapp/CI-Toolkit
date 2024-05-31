#!/bin/bash

# Exit script on error
set -e

# Initialize variables
APP_VERSION=""
BASE_DIRECTORY=""
EXCLUDE_OS=""
NORMALIZE=false
DRYRUN=false # New variable for dry run mode

# Function to display usage
usage() {
    echo "Cider Distribution Tool v1.0"
    echo "Requires: Authorized Butler install."
    echo "Usage: $0 -v <app_version> -d <directory> [-e <exclude_os>] [--normalize] [--dryrun]"
    echo "  -v <app_version>    Specify the app version to upload."
    echo "  -d <directory>      Specify the directory containing the installers."
    echo "  -e <exclude_os>     Optional. Comma-separated list of OS to exclude (e.g., windows,macOS)."
    echo "  --normalize         Optional. Standardize file names according to specified scheme."
    echo "  --dryrun            Optional. Simulate the upload process without making any changes."
    exit 1
}

# Parse command-line options
while getopts ":v:d:e:-:" opt; do
    case ${opt} in
        v) APP_VERSION=$OPTARG ;;
        d) BASE_DIRECTORY=$OPTARG ;;
        e) EXCLUDE_OS=$OPTARG ;;
        -)
            case "${OPTARG}" in
                normalize) NORMALIZE=true ;;
                dryrun) DRYRUN=true ;;
                *) usage ;;
            esac
        ;;
        ?) usage ;;
    esac
done

# Convert EXCLUDE_OS to an array
IFS=',' read -r -a EXCLUDE_OS_ARRAY <<< "$EXCLUDE_OS"

# Start of the script
echo "======================="
echo "Starting upload process"
echo "Version: $APP_VERSION"
echo "Directory: $BASE_DIRECTORY"
[ ! -z "$EXCLUDE_OS" ] && echo "Excluding OS: $EXCLUDE_OS"
echo "======================="

# Function to check if an OS should be excluded
should_exclude() {
    local os=$1
    for exclude_os in "${EXCLUDE_OS_ARRAY[@]}"; do
        if [[ "$os" == "$exclude_os" ]]; then
            return 0
        fi
    done
    return 1
}

# Find and display files to process
echo "Files to be processed:"
find "$BASE_DIRECTORY" -type f \( -name "*.msi" -o -name "*.dmg" -o -name "*.pkg.tar.*" -o -name "*.rpm" -o -name "*.deb" -o -name "*.AppImage" \) | while read file_path; do
    echo "$file_path"
done
echo "======================="

# Normalize file name to match the specified naming scheme
normalize_file_name() {
    local file_path=$1
    local os=$2
    local arch=$3
    local extension="${file_path##*.}"

    # Special handling for .pkg.tar.zst files
    if [[ "$file_path" == *.pkg.tar.zst ]]; then
        extension="pkg.tar.zst"
    fi

    # Adjust the echo statement according to your naming scheme, including OS and arch if needed
    echo "Cider-$os-$arch.$extension"
}

# Define Itch.io user/project
ITCHIO_USERNAME="cidercollective"
ITCHIO_PROJECT_NAME="cider"

# Function to upload a file to Itch.io using Butler
upload_with_butler() {
    local file_path=$1
    local channel_name=$2
    local dry_run_cmd=$3

    if [ "$dry_run_cmd" = true ]; then
        echo "Dry run: butler push \"$file_path\" \"$ITCHIO_USERNAME/$ITCHIO_PROJECT_NAME:$channel_name\" --userversion \"$APP_VERSION\" --dry-run"
    else
        butler push "$file_path" "$ITCHIO_USERNAME/$ITCHIO_PROJECT_NAME:$channel_name" --userversion "$APP_VERSION"
    fi
}

# Start processing and uploading files
find "$BASE_DIRECTORY" -type f \( -name "*.msi" -o -name "*.dmg" -o -name "*.pkg.tar.*" -o -name "*.rpm" -o -name "*.deb" -o -name "*.AppImage" \) | while read file_path; do
    original_file_path="$file_path" # Initialize original file path
    
    # Determine OS and architecture based on the file name
    case "$file_path" in
        *x64_en-US.msi) os="windows" arch="x64" ;;
        *-arm64.dmg) os="macOS" arch="arm64" ;;
        *-x64.dmg) os="macOS" arch="x64" ;;
        *-x86_64.pkg.tar.*) os="linux-arch" arch="x64" ;;
        *x86_64.rpm) os="linux-fedora" arch="x64" ;;
        *_amd64.deb) os="linux-debian" arch="x64" ;;
        *.AppImage) os="linux-appimage" arch="x64" ;;
        *) echo "Unknown file format: $file_path" && continue ;;
    esac

    # Skip excluded OS
    if should_exclude "$os"; then
        echo "Skipping excluded OS ($os) file: $file_path"
        continue
    fi

    # Normalize file name if requested
    if [ "$NORMALIZE" = true ]; then
        normalized_file_name=$(normalize_file_name "$file_path" "$os" "$arch")
        if [ "$DRYRUN" = true ]; then
            echo "Would rename: $file_path to $normalized_file_name"
        else
            mv "$file_path" "$BASE_DIRECTORY/$normalized_file_name"
            file_path="$BASE_DIRECTORY/$normalized_file_name"
        fi
    fi

    # Construct the channel name using OS, architecture
    channel_name="${os}-${arch}"

    # Simulate or perform the upload
    if [ "$DRYRUN" = true ]; then
        upload_with_butler "$file_path" "$channel_name" true
    else
        upload_with_butler "$file_path" "$channel_name" false
    fi

    # If file was renamed and it's not a dry run, move it back to the original name
    if [ "$NORMALIZE" = true ] && [ "$DRYRUN" = false ]; then
        mv "$file_path" "$original_file_path"
    fi
done

echo "Upload process completed."
