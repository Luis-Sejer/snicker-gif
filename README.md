# GifBar

A menu bar GIF search for macOS. Press **⌘⌥V**, type, and click a GIF to copy it, or drag it straight into a chat.

Pasting works in **Microsoft Teams** as well as Slack, Discord, Messages and Mail: the clipboard gets the GIF both as a file (what Teams needs) and as raw GIF data (what the others use).

Requires **macOS 26 or later** on Apple Silicon.

## Install

Paste this into Terminal:

```sh
gh api repos/Luis-Sejer/GifBar/contents/install.sh -H "Accept: application/vnd.github.raw" | sh
```

This needs the [GitHub CLI](https://cli.github.com) signed in to an account with access to this repository. Once the repository is public, plain `curl` works instead:

```sh
curl -fsSL https://raw.githubusercontent.com/Luis-Sejer/GifBar/main/install.sh | sh
```

Run the same command again to update.

<details>
<summary>Install by hand instead</summary>

1. Download `GifBar.zip` from the latest [release](https://github.com/Luis-Sejer/GifBar/releases/latest) and unzip it.
2. Move `GifBar.app` to `Applications` (or `~/Applications` if you are not an admin).
3. Open it. macOS will say it can't verify the developer, because GifBar is not notarized with a paid Apple developer account.
4. Go to **System Settings → Privacy & Security**, scroll down and click **Open Anyway**.

</details>

## First run

GifBar searches [KLIPY](https://klipy.com)'s GIF library, which needs a free API key:

1. Create an account and an app on KLIPY's developer portal ([docs.klipy.com](https://docs.klipy.com)) and copy the API key.
2. Press ⌘⌥V (or click the **GIF** icon in the menu bar) and paste the key.

The key is stored locally. Change it later from the **⋯** menu.

To start GifBar automatically, add it under **System Settings → General → Login Items**.

## Usage

| Action | Result |
|---|---|
| ⌘⌥V or the menu bar icon | open or close |
| type, or pick a suggestion | search (Trending when empty) |
| Enter | copy the first result |
| click | copy and close |
| drag | drop the GIF file into any app |

## Build from source

Needs only the Xcode Command Line Tools (`xcode-select --install`).

```sh
./build.sh install   # build, install to ~/Applications and launch
./release.sh 1.1.0   # tag, build and publish a GitHub release
```
