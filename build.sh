#!/bin/sh
# Builds build/Snicker.app. `./build.sh install` also installs it to ~/Applications and launches it.
# Needs only the Xcode Command Line Tools.
set -e
cd "$(dirname "$0")"

VERSION=$(git describe --tags --abbrev=0 2>/dev/null | sed 's/^v//')
VERSION=${VERSION:-0.0.0}

swift build -c release
APP=build/Snicker.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp .build/release/Snicker "$APP/Contents/MacOS/Snicker"
cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key><string>Snicker</string>
    <key>CFBundleIdentifier</key><string>dk.sejer.snicker</string>
    <key>CFBundleName</key><string>Snicker</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>$VERSION</string>
    <key>LSMinimumSystemVersion</key><string>26.0</string>
    <key>LSUIElement</key><true/>
</dict>
</plist>
PLIST
# Ad-hoc signature: Apple Silicon refuses to run unsigned code, and this needs no developer account.
codesign --force --sign - "$APP"
echo "Built $APP ($VERSION)"

[ "$1" = "install" ] || exit 0
# ~/Applications needs no admin rights and is still indexed by Spotlight.
INSTALL_DIR="$HOME/Applications"
mkdir -p "$INSTALL_DIR"
if pkill -x Snicker; then sleep 1; fi
rm -rf "$INSTALL_DIR/Snicker.app"
cp -R "$APP" "$INSTALL_DIR/"
open "$INSTALL_DIR/Snicker.app"
echo "Installed and launched $INSTALL_DIR/Snicker.app"
