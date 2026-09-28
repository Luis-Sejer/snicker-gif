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
swift test            # run the tests (needs full Xcode; CI runs them on every push)
./build.sh install    # build, install to ~/Applications, relaunch
swift build           # quick compile check (needs Sources/Snicker/BundledKey.swift; run ./build.sh once first)
docs/src/render.sh    # re-render icon, README hero and launch video (needs Chrome, Node, ffmpeg, img2webp)
./release.sh 1.1.0    # tag a release; GitHub Actions builds and publishes it
```

Tests live in `Tests/SnickerTests` (Swift Testing) and cover KLIPY response decoding, file naming and favorites/recents storage. They need full Xcode, because XCTest and Swift Testing don't ship with the Command Line Tools; without Xcode, push and read the CI result (`gh run watch`). Test new logic there; views are verified by eye: run `./build.sh install` and ask the user for a screenshot, since the sandboxed agent cannot capture the screen or send keystrokes, and offscreen snapshots do not render Liquid Glass.

## Code map

| File | Responsibility |
|---|---|
| `Sources/Snicker/App.swift` | Entry point, `AppDelegate`, status item + template icon, `NSPopover`, hidden Edit menu, Carbon global hotkey (`HotKey`) |
| `Sources/Snicker/ContentView.swift` | All UI: `ViewState`, search field, chips, masonry grid, `GifTile`, footer + settings menu, `WelcomeView` (API key entry), `AnimatedGif` (NSImageView wrapper) |
| `Sources/Snicker/Klipy.swift` | `Gif` model, KLIPY API client (`fetch`, `autocomplete`), `GifFile` (download cache, clipboard, drag, save) |
| `Sources/Snicker/Library.swift` | Favorites and recents, persisted as JSON in UserDefaults |
| `Sources/Snicker/Updater.swift` | Daily check of GitHub's latest release, the Update / Later reminder, and running `install.sh` to update |
| `Tests/SnickerTests/` | Swift Testing tests; `Library(defaults:)` takes a throwaway `UserDefaults` suite so tests never touch real data |
| `Sources/Snicker/BundledKey.swift` | **Generated and gitignored.** Written by `build.sh`; never create, edit or commit it by hand |
| `docs/src/` | HTML sources for the icon (`icon.html`) and the animated hero/launch video (`anim.html`), render scripts, ElevenLabs audio |

## Rules that are easy to break

1. **Build with the Command Line Tools, not Xcode.** On the macOS 27 SDK, `@State` is a macro whose plugin ships only with Xcode, so it fails to compile here. Keep view state in `ViewState` (an `ObservableObject`) or another `ObservableObject`. `@StateObject`, `@ObservedObject`, `@AppStorage`, `@FocusState`, `@Binding` and `@Environment` are fine.
2. **Never commit an API key.** `build.sh` reads the KLIPY key from `SNICKER_KLIPY_KEY` or `~/.config/snicker/klipy-key` and writes it XOR-masked into `BundledKey.swift`. CI uses the `KLIPY_API_KEY` repository secret. A user-entered key in UserDefaults (`klipyApiKey`) overrides the bundled one.
3. **Copying must write both clipboard types** (`GifFile.copyToPasteboard`): the file URL for Teams, the raw `com.compuserve.gif` data for Slack, Discord and Messages. Removing either breaks pasting somewhere.
4. **KLIPY uses a Tenor-compatible v2 API** at `https://api.klipy.com/v2/` (`featured`, `search`, `autocomplete`). An invalid key returns HTTP 404 with a JSON error message, not 401. KLIPY's attribution rules require the search placeholder to read "Search KLIPY" (the only hard requirement); the official "Powered by KLIPY" logo is recommended and shown in the popover footer (`Resources/powered-by-klipy.png`, copied into the app by `build.sh`, tinted as a template image) and on the site (`docs/assets/klipy/`). Keep both. Their terms forbid storing, rehosting or retaining copies of KLIPY media: `GifFile.download` keeps only the GIF currently on the clipboard and `clearDownloads()` runs at launch. Don't add a persistent media cache; favorites and recents store metadata and URLs only.
5. **GIFs animate only while the popover is open** (`ViewState.isShown`). A hidden popover must cost nothing; letting them run cost ~20% CPU at idle.
6. **Accessibility is a requirement.** New controls need VoiceOver labels; everything must work from the keyboard; animations respect `accessibilityReduceMotion`; GIFs respect `accessibilityPlayAnimatedImages`.
7. **The popover size is fixed up front** (`Layout.popoverSize`, `sizingOptions = []`). Letting SwiftUI size it after showing makes it grow up under the menu bar.
8. **Menu bar apps have no main menu**, so text-editing shortcuts only work because of the hidden Edit menu in `App.swift`. Don't remove it.

## Conventions

- Match the surrounding style: small views, doc comments that explain *why*, no magic numbers (named constants on the type).
- Prefer the smallest change that works; no new abstractions or dependencies without a clear need.
- Commits use [Conventional Commits](https://www.conventionalcommits.org): `feat:`, `fix:`, `docs:`, `ci:`, `refactor:`.
- User-visible changes get a line under **Unreleased** in `CHANGELOG.md`. `release.sh` refuses to tag a version without its changelog section, and the release notes are taken from it.

## Release pipeline

`release.sh` checks the tree is clean and the changelog has the version, then tags and pushes. `.github/workflows/release.yml` builds on a `macos-26` runner with the key secret, zips the app and publishes a GitHub release. `install.sh` (what the README's `curl` line runs) downloads the latest `Snicker.zip` into `~/Applications` and strips the quarantine flag.

## README artwork

The hero image, the looping WebP and the launch video all come from one timeline in `docs/src/anim.html`, driven by `?t=<seconds>`. The beats are constants at the top of its script; `render.sh` places the sound effects and voiceover on the same beats (in ms). The artwork is a drawing of the real UI, so keep it in sync when the UI changes.

## Website

`docs/` is the GitHub Pages site (https://luis-sejer.github.io/snicker-gif/): plain static files, no build step.

| File | Responsibility |
|---|---|
| `docs/index.html` | Markup: menu bar header, live popover demo, marquee, scroll story, real screenshots, features, clipboard diagram, video, install, FAQ, Dock |
| `docs/site.css` | All styles. Tokens are the `:root` custom properties; the visual system is recorded in `DESIGN.md` |
| `docs/site.js` | Behaviour without GSAP: the popover demo, draggable GIF windows, the spring Dock, story step detection (IntersectionObserver), copy buttons, clock |
| `docs/motion.js` | GSAP choreography: intro, scrubbed story timeline, headline reveals, screenshot tilt, right-click menu, clipboard diagram, video zoom, marquee |
| `docs/vendor/gsap/` | GSAP 3.15 (core, ScrollTrigger, SplitText, ScrambleText), self-hosted so it loads with the page |
| `docs/assets/` | Icon, README hero, video and poster (rendered by `docs/src/render.sh`), real app screenshots in `screens/` |

Rules for the site:

1. **Light only.** Apple's gray desktop (`#f5f5f7`), white bands, one black field, blue (`#0071e3`) as the only accent. No dark mode (removed on purpose), no pink or red fields, no gradients except inside GIF content.
2. **Only show what the app does.** The popover demo, story scene and screenshots must depict real features.
3. **GSAP: set, then animate with `to()`.** Never use `from()` for anything visible on load; a `from()` in a timeline has its starting state reverted on the first tick, which showed content and then blinked it away on cached reloads. Set starting states with `gsap.set()` first.
4. **No scroll listeners.** Scroll-linked work goes through ScrollTrigger or IntersectionObserver. Everything must revert to the static page under `prefers-reduced-motion` (motion lives in `gsap.matchMedia`, except the intro, which runs once).
5. **The intro never replays over content.** An inline script in `<head>` hides the hero until the intro starts and gives up after 2.5s; `motion.js` skips the intro if that happened or if the reload restored a scrolled position.
6. **Screenshots show real GIFs, so choose them carefully:** prefer animals and original cartoons; avoid recognisable celebrities and branded characters on a promotional page.
7. **Keep `<meta name="robots" content="noindex">` until launch**, then remove it.

Design context for impeccable-style work: `PRODUCT.md` (product truth), `DESIGN.md` (visual system), `.impeccable/surfaces/docs-index-html.md` (the page's direction).
