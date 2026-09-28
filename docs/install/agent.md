# Installing Snicker with an AI agent

Instructions for an AI coding agent (Claude Code, Codex, Cursor and similar) asked to install, update or uninstall Snicker on the user's Mac. Follow them in order, and tell the user what you did.

## Install or update

1. **Check the Mac can run it.** Snicker needs macOS 26 or later on Apple silicon.

   ```sh
   sw_vers -productVersion   # must be 26 or higher
   uname -m                  # must be arm64
   ```

   If either check fails, stop and tell the user Snicker won't run on this Mac. Don't try to build or install it anyway.

2. **Run the installer.** It downloads the latest release from GitHub, replaces any older copy in `~/Applications`, clears the quarantine flag (Snicker isn't notarized) and opens the app. It needs no admin password.

   ```sh
   curl -fsSL https://raw.githubusercontent.com/Luis-Sejer/snicker-gif/main/install.sh | sh
   ```

   It keeps the user's favorites, recents, settings and any KLIPY key they added.

3. **Check it worked.**

   ```sh
   pgrep -x Snicker && /usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" ~/Applications/Snicker.app/Contents/Info.plist
   ```

   This should print a process ID and a version number. Compare the version with the latest release on https://github.com/Luis-Sejer/snicker-gif/releases/latest.

4. **Tell the user how to use it.** Snicker has no Dock icon or window. It lives in the menu bar as a **GIF** icon. Press ⌘⌥V from any app, type a search, and click a GIF to copy it. It pastes into Microsoft Teams, Slack, Messages and more. No account or setup is needed: release builds include a KLIPY API key.

   If the user says macOS blocked the app, have them open **System Settings → Privacy & Security** and click **Open Anyway**.

## Uninstall

```sh
curl -fsSL https://raw.githubusercontent.com/Luis-Sejer/snicker-gif/main/install.sh | sh -s -- --uninstall
```

This quits Snicker and removes the app and its GIF cache. It keeps favorites and settings, in case the user reinstalls.

Only if the user asks to remove everything, also delete the settings:

```sh
defaults delete dk.sejer.snicker
```

If they had turned on Launch at Login, macOS drops the login item on its own once the app is gone.

## Don't

- Don't use `sudo`. Nothing here needs admin rights.
- Don't build from source unless the user asks. The release is built by GitHub Actions from the tagged source.
- Don't ask the user for a KLIPY key. Release builds work without one.
