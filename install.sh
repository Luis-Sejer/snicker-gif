#!/bin/sh
# Installs or updates Snicker in ~/Applications from the latest GitHub release.
# With --uninstall, removes the app and its GIF cache but keeps favorites and settings.
set -e
REPO=Luis-Sejer/snicker-gif
BUNDLE_ID=dk.sejer.snicker

if [ "$1" = "--uninstall" ]; then
    if pkill -x Snicker; then sleep 1; fi
    # The README's hand install puts it in /Applications instead.
    rm -rf "$HOME/Applications/Snicker.app" "/Applications/Snicker.app"
    rm -rf "$HOME/Library/Caches/Snicker" "$HOME/Library/Caches/$BUNDLE_ID"
    echo "Snicker is uninstalled. Your favorites and settings are kept in case you come back."
    echo "To remove them too, run: defaults delete $BUNDLE_ID"
    exit 0
fi

DOWNLOAD_DIR=$(mktemp -d)
trap 'rm -rf "$DOWNLOAD_DIR"' EXIT

# gh works while the repo is private; plain curl works once it is public.
if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
    gh release download --repo "$REPO" --pattern Snicker.zip --dir "$DOWNLOAD_DIR"
else
    curl -fsSL "https://github.com/$REPO/releases/latest/download/Snicker.zip" -o "$DOWNLOAD_DIR/Snicker.zip"
fi

mkdir -p "$HOME/Applications"
if pkill -x Snicker; then sleep 1; fi
rm -rf "$HOME/Applications/Snicker.app"
ditto -x -k "$DOWNLOAD_DIR/Snicker.zip" "$HOME/Applications"
# Not notarized, so drop the quarantine flag that would make Gatekeeper block it.
xattr -dr com.apple.quarantine "$HOME/Applications/Snicker.app" 2>/dev/null || true
open "$HOME/Applications/Snicker.app"
echo "Snicker is installed. Press ⌘⌥V to open it."
