# Changelog

All notable changes to Snicker are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and Snicker follows
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- An uninstall command: add `-s -- --uninstall` to the install command. It keeps your favorites and settings.
- Instructions for AI coding agents to install, check and uninstall Snicker, in `docs/install/agent.md`.

## [1.1.0] - 2026-09-28

### Added

- Snicker tells you when a new version is out. Click Update to install it and reopen Snicker, or Later to be reminded tomorrow or the next time Snicker starts. It checks GitHub at most once a day.

## [1.0.1] - 2026-09-28

### Fixed

- Snicker now closes when you click elsewhere after using a GIF's right-click menu. Before, it stayed open until you clicked the menu bar icon.
- The search field is focused every time Snicker opens, so you can type right away.
- Reopening Snicker more than 30 seconds after closing it starts fresh on Trending instead of showing your old search.

## [1.0.0] - 2026-09-28

### Added

- GIF search from the menu bar with <kbd>⌘</kbd> <kbd>⌥</kbd> <kbd>V</kbd>, showing Trending before you type.
- Click to copy, or drag a GIF into any app. Copied GIFs paste into Microsoft Teams as well as Slack, Discord, Messages and Mail.
- Favorites and Recent, kept between launches.
- Search suggestions while typing, and quick picks for common reactions.
- A right-click menu on every GIF: Copy GIF, Copy Link, Add to Favorites, Save to Downloads and Open on KLIPY.
- Keyboard navigation: arrow keys to choose, <kbd>Return</kbd> to copy, <kbd>⇧</kbd> <kbd>Return</kbd> to copy the link and <kbd>⌘</kbd> <kbd>D</kbd> to favorite.
- Settings for Launch at Login and Random File Names.
- VoiceOver labels, actions and announcements, and support for Reduce Motion and Auto-play Animated Images.
- A Liquid Glass design for macOS 26 and later, with a menu bar icon that matches the app icon.
- Near-zero CPU use while closed: GIFs only animate while the popover is open.
- The search field reads "Search KLIPY", following KLIPY's attribution guidelines.
- A Support Snicker… item in the ⋯ menu, linking to Ko-fi.

[Unreleased]: https://github.com/Luis-Sejer/snicker-gif/compare/v1.1.0...HEAD
[1.1.0]: https://github.com/Luis-Sejer/snicker-gif/compare/v1.0.1...v1.1.0
[1.0.1]: https://github.com/Luis-Sejer/snicker-gif/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/Luis-Sejer/snicker-gif/releases/tag/v1.0.0
