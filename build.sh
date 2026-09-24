#!/bin/sh
# Builds GifBar.app, installs it to ~/Applications and launches it. Needs only the Xcode Command Line Tools.
set -e
cd "$(dirname "$0")"

swift build -c release
APP=build/GifBar.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp .build/release/GifBar "$APP/Contents/MacOS/GifBar"
cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key><string>GifBar</string>
    <key>CFBundleIdentifier</key><string>dk.sejer.gifbar</string>
    <key>CFBundleName</key><string>GifBar</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>1.0</string>
    <key>LSMinimumSystemVersion</key><string>26.0</string>
    <key>LSUIElement</key><true/>
</dict>
</plist>
PLIST
codesign --force --sign - "$APP"

# ~/Applications needs no admin rights and is still indexed by Spotlight.
INSTALL_DIR="$HOME/Applications"
mkdir -p "$INSTALL_DIR"
pkill -x GifBar 2>/dev/null || true
rm -rf "$INSTALL_DIR/GifBar.app"
cp -R "$APP" "$INSTALL_DIR/"
open "$INSTALL_DIR/GifBar.app"
echo "Installed and launched $INSTALL_DIR/GifBar.app"
