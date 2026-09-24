# AGENTS.md

Guide for AI coding agents working on Snicker. Humans: see [CONTRIBUTING.md](CONTRIBUTING.md).

## What Snicker is

A macOS menu bar app for finding and sharing GIFs. ⌘⌥V opens a popover; the user searches KLIPY's GIF library and clicks a GIF to copy it or drags it into any app. Its reason to exist: copied GIFs paste into Microsoft Teams, which only accepts a file URL on the clipboard, as well as apps that take raw GIF data.

- SwiftUI + AppKit, Swift Package Manager, **no third-party dependencies**
- macOS 26+ (Liquid Glass APIs), Apple Silicon
- No Dock icon (`LSUIElement`), no sandbox, not notarized

## Commands

```sh
./build.sh            # build build/Snicker.app (release config)
./build.sh install    # build, install to ~/Applications, relaunch
swift build           # quick compile check (needs Sources/Snicker/BundledKey.swift; run ./build.sh once first)
docs/src/render.sh    # re-render icon, README hero and launch video (needs Chrome, Node, ffmpeg, img2webp)
./release.sh 1.1.0    # tag a release; GitHub Actions builds and publishes it
```

There is no test suite. Verify a change by building it, and for anything visual, by running `./build.sh install` and asking the user for a screenshot: the sandboxed agent cannot capture the screen or send keystrokes, and offscreen snapshots do not render Liquid Glass.

## Code map

| File | Responsibility |
|---|---|
| `Sources/Snicker/App.swift` | Entry point, `AppDelegate`, status item + template icon, `NSPopover`, hidden Edit menu, Carbon global hotkey (`HotKey`) |
| `Sources/Snicker/ContentView.swift` | All UI: `ViewState`, search field, chips, masonry grid, `GifTile`, footer + settings menu, `WelcomeView` (API key entry), `AnimatedGif` (NSImageView wrapper) |
| `Sources/Snicker/Klipy.swift` | `Gif` model, KLIPY API client (`fetch`, `autocomplete`), `GifFile` (download cache, clipboard, drag, save) |
| `Sources/Snicker/Library.swift` | Favorites and recents, persisted as JSON in UserDefaults |
| `Sources/Snicker/BundledKey.swift` | **Generated and gitignored.** Written by `build.sh`; never create, edit or commit it by hand |
| `docs/src/` | HTML sources for the icon (`icon.html`) and the animated hero/launch video (`anim.html`), render scripts, ElevenLabs audio |

## Rules that are easy to break

1. **Build with the Command Line Tools, not Xcode.** On the macOS 27 SDK, `@State` is a macro whose plugin ships only with Xcode, so it fails to compile here. Keep view state in `ViewState` (an `ObservableObject`) or another `ObservableObject`. `@StateObject`, `@ObservedObject`, `@AppStorage`, `@FocusState`, `@Binding` and `@Environment` are fine.
2. **Never commit an API key.** `build.sh` reads the KLIPY key from `SNICKER_KLIPY_KEY` or `~/.config/snicker/klipy-key` and writes it XOR-masked into `BundledKey.swift`. CI uses the `KLIPY_API_KEY` repository secret. A user-entered key in UserDefaults (`klipyApiKey`) overrides the bundled one.
3. **Copying must write both clipboard types** (`GifFile.copyToPasteboard`): the file URL for Teams, the raw `com.compuserve.gif` data for Slack, Discord and Messages. Removing either breaks pasting somewhere.
4. **KLIPY uses a Tenor-compatible v2 API** at `https://api.klipy.com/v2/` (`featured`, `search`, `autocomplete`). An invalid key returns HTTP 404 with a JSON error message, not 401.
5. **Accessibility is a requirement.** New controls need VoiceOver labels; everything must work from the keyboard; animations respect `accessibilityReduceMotion`; GIFs respect `accessibilityPlayAnimatedImages`.
6. **The popover size is fixed up front** (`Layout.popoverSize`, `sizingOptions = []`). Letting SwiftUI size it after showing makes it grow up under the menu bar.
7. **Menu bar apps have no main menu**, so text-editing shortcuts only work because of the hidden Edit menu in `App.swift`. Don't remove it.

## Conventions

- Match the surrounding style: small views, doc comments that explain *why*, no magic numbers (named constants on the type).
- Prefer the smallest change that works; no new abstractions or dependencies without a clear need.
- Commits use [Conventional Commits](https://www.conventionalcommits.org): `feat:`, `fix:`, `docs:`, `ci:`, `refactor:`.
- User-visible changes get a line under **Unreleased** in `CHANGELOG.md`. `release.sh` refuses to tag a version without its changelog section, and the release notes are taken from it.

## Release pipeline

`release.sh` checks the tree is clean and the changelog has the version, then tags and pushes. `.github/workflows/release.yml` builds on a `macos-26` runner with the key secret, zips the app and publishes a GitHub release. `install.sh` (what the README's `curl` line runs) downloads the latest `Snicker.zip` into `~/Applications` and strips the quarantine flag.

## README artwork

The hero image, the looping WebP and the launch video all come from one timeline in `docs/src/anim.html`, driven by `?t=<seconds>`. The beats are constants at the top of its script; `render.sh` places the sound effects and voiceover on the same beats (in ms). The artwork is a drawing of the real UI, so keep it in sync when the UI changes.
