#!/bin/sh
# Installs or updates Snicker in ~/Applications from the latest GitHub release.
set -e
REPO=Luis-Sejer/snicker-gif
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
