#!/bin/sh
# Installs or updates GifBar in ~/Applications from the latest GitHub release.
set -e
REPO=Luis-Sejer/GifBar
DOWNLOAD_DIR=$(mktemp -d)
trap 'rm -rf "$DOWNLOAD_DIR"' EXIT

# gh works while the repo is private; plain curl works once it is public.
if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
    gh release download --repo "$REPO" --pattern GifBar.zip --dir "$DOWNLOAD_DIR"
else
    curl -fsSL "https://github.com/$REPO/releases/latest/download/GifBar.zip" -o "$DOWNLOAD_DIR/GifBar.zip"
fi

mkdir -p "$HOME/Applications"
if pkill -x GifBar; then sleep 1; fi
rm -rf "$HOME/Applications/GifBar.app"
ditto -x -k "$DOWNLOAD_DIR/GifBar.zip" "$HOME/Applications"
# Not notarized, so drop the quarantine flag that would make Gatekeeper block it.
xattr -dr com.apple.quarantine "$HOME/Applications/GifBar.app" 2>/dev/null || true
open "$HOME/Applications/GifBar.app"
echo "GifBar is installed. Press ⌘⌥V to open it."
