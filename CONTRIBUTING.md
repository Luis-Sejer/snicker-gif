# Contributing to Snicker

Thanks for helping make Snicker better. Bug reports, ideas and pull requests are all welcome.

By taking part you agree to follow the [Code of Conduct](CODE_OF_CONDUCT.md).

## Reporting bugs and suggesting features

Open an [issue](https://github.com/Luis-Sejer/snicker-gif/issues/new/choose) and pick the template that fits. For bugs, include your macOS version, the Snicker version (in Finder, select Snicker and press ⌘I) and the steps that show the problem.

Found a security issue? Please follow [SECURITY.md](SECURITY.md) instead of opening a public issue.

## Development setup

You need macOS 26 or later and the Xcode Command Line Tools (`xcode-select --install`). Full Xcode is not required.

```sh
git clone https://github.com/Luis-Sejer/snicker-gif.git
cd snicker-gif
./build.sh install
```

Source builds don’t include a KLIPY key, so Snicker asks for one on first launch. Keys are free from KLIPY’s [developer portal](https://docs.klipy.com).

### Project layout

| Path | What lives there |
|---|---|
| `Sources/Snicker/App.swift` | App entry point, menu bar item, popover and global shortcut |
| `Sources/Snicker/ContentView.swift` | The popover: search, grid, tiles, settings and welcome screen |
| `Sources/Snicker/Klipy.swift` | The GIF model, the KLIPY API and clipboard/file handling |
| `Sources/Snicker/Library.swift` | Favorites and recents |
| `Resources/` | Files bundled into the app by `build.sh` (KLIPY's logo) |
| `Tests/SnickerTests/` | Tests for decoding, file naming and the library |
| `docs/index.html`, `site.css`, `site.js`, `motion.js` | The website (GitHub Pages), with GSAP in `docs/vendor/gsap/` |
| `docs/src/` | HTML sources and scripts for the icon, README artwork and launch video |

## Guidelines

- **Stay native.** Use SwiftUI and AppKit, and follow Apple’s [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines). Snicker has no third-party dependencies and should keep it that way.
- **Build with the Command Line Tools.** Avoid APIs that need full Xcode. For example, keep view state in `ObservableObject` instead of `@State`, whose macro plugin ships only with Xcode.
- **Keep it accessible.** Every control needs a VoiceOver label, everything must work from the keyboard, and animation must respect Reduce Motion and Auto-play Animated Images.
- **Keep it small.** Prefer the simplest change that works, and match the style of the surrounding code.

## Pull requests

1. Fork the repository and create a branch from `main`.
2. Make your change and check it builds with `./build.sh`. If you have Xcode, run the tests with `swift test`; otherwise CI runs them on your pull request.
3. Try it: `./build.sh install` builds, installs and launches your version.
4. Add a line under **Unreleased** in [CHANGELOG.md](CHANGELOG.md) if users will notice the change.
5. Open a pull request that explains what changed and why, with a screenshot for anything visual.

## Releases

Maintainers release by moving the **Unreleased** entries in `CHANGELOG.md` under a new version heading, committing, and running:

```sh
./release.sh 1.1.0
```

That tags the commit. GitHub Actions then builds the app with the KLIPY key stored as a repository secret and publishes the release, using the changelog entry as release notes.
