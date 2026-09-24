# GifBar

A menu bar GIF search for macOS, in the spirit of QuickGif. Press **⌘⌥V**, type, and click a GIF to copy it or drag it into a chat.

Pasting works in **Microsoft Teams** too: the clipboard gets the GIF as a file URL (what Teams needs) and as raw GIF data (what Slack, Discord and Messages use).

GIFs come from [KLIPY](https://klipy.com) through its Tenor-compatible API.

## Build

Needs only the Xcode Command Line Tools (`xcode-select --install`). Full Xcode is not required.

```sh
./build.sh
cp -R build/GifBar.app /Applications/
```

The app is ad-hoc signed, so the first launch needs right-click → **Open**. To start it automatically, add it under System Settings → General → Login Items.

## First run

Create a free API key in Klipy's developer portal and paste it into the popover. It is stored in the app's user defaults. Change it later from the gear menu.

## Usage

| Action | Result |
|---|---|
| ⌘⌥V or the menu bar icon | open or close |
| type | search (trending when empty) |
| Enter | copy the first result |
| click | copy and close |
| drag | drop the GIF file into any app |

Copied GIFs are cached in `~/Library/Caches/GifBar`.
