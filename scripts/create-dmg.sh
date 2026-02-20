#!/bin/bash

# Create DMG for DeepSeek App
# Usage: ./scripts/create-dmg.sh

set -e

APP_NAME="AiApp"
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_PATH="${PROJECT_DIR}/build/Build/Products/Release/${APP_NAME}.app"
OUTPUT_DIR="${PROJECT_DIR}/dist"
DMG_FINAL="${OUTPUT_DIR}/AiApp.dmg"
VOLUME_NAME="AiApp"

echo "Creating DMG for ${APP_NAME}..."

# Check if app exists
if [ ! -d "$APP_PATH" ]; then
    echo "Error: App not found at ${APP_PATH}"
    echo "Please build the app first with: xcodebuild -configuration Release"
    exit 1
fi

# Create output and staging directories
mkdir -p "$OUTPUT_DIR"
STAGING_DIR="${OUTPUT_DIR}/dmg-staging"
rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR"

# Copy app to staging
echo "Copying app..."
ditto "$APP_PATH" "$STAGING_DIR/${APP_NAME}.app"

# Remove extended attributes (quarantine) from the app
echo "Removing extended attributes..."
xattr -cr "$STAGING_DIR/${APP_NAME}.app"

# Create Applications symlink
ln -s /Applications "$STAGING_DIR/Applications"

# Remove old DMG if exists
rm -f "$DMG_FINAL"

# Create DMG directly (no mount needed)
echo "Creating DMG..."
hdiutil create -volname "$VOLUME_NAME" -srcfolder "$STAGING_DIR" -ov -format UDZO "$DMG_FINAL"

# Remove extended attributes from DMG itself
echo "Cleaning DMG attributes..."
xattr -c "$DMG_FINAL" 2>/dev/null || true

# Cleanup staging
rm -rf "$STAGING_DIR"

echo ""
echo "DMG created successfully: ${DMG_FINAL}"
echo "Size: $(du -h "$DMG_FINAL" | cut -f1)"
echo ""
echo "Note: Users may need to right-click and select 'Open' on first launch,"
echo "or go to System Preferences > Security & Privacy to allow the app."
