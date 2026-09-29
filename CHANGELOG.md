# Changelog

All notable changes to Snicker are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and Snicker follows
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Stickers: switch between GIFs and KLIPY's stickers with the GIFs | Stickers switch in the search field, or ⌘T. Stickers have transparent backgrounds and paste like GIFs.
- Cursed (Experimental), a new Content setting that shows only the wild GIFs: what Work-Safe would hide, plus cursed GIFs for your search. A Cursed chip stays visible while it's on; click it to turn Cursed off.

## [1.4.1] - 2026-09-29

### Fixed

- The shortcut hints and the ⋯ button at the bottom are easier to read over busy GIFs.

## [1.4.0] - 2026-09-29

### Added

- Check for Updates… in the ⋯ menu, and a Check for Updates button in Settings → General.
- Favorite slots: pin a GIF to one of nine slots from its right-click menu, then copy it from any app with ⌃⌥1 to ⌃⌥9, without opening Snicker. The menu bar icon flashes a checkmark to confirm.
- Collections: group GIFs into your own named sets, like "Work" or "Mondays". Add a GIF from its right-click menu, and right-click a collection to rename or delete it.
- Recent searches show as chips when the search field is empty. Right-click one to remove it, or clear them all in Settings.
- Surprise Me: the dice button (or ⌘R) copies a random GIF from what's showing.
- Find GIF in Snicker: select text in any app, then right-click → Services → Find GIF in Snicker.
- A Content setting in Settings → General: Unrestricted, Standard or Work-Safe.

### Changed

- Snicker checks for a new version every time you open it, not once a day. Clicking Later still holds the reminder until the next day.
- Favorites, Recent and Trending are icons now, to make room for collections and searches. Turn on Show Tab Names in Settings to bring the names back.
- The shortcut hints and the ⋯ button sit on a glass bar, so they stay readable over busy GIFs. Update messages grow out of it instead of stacking a second card on top.

## [1.3.0] - 2026-09-29

### Added

- A Settings window (⌘, or Settings… in the ⋯ menu) with General, Shortcuts and Advanced tabs.
- Every keyboard shortcut can be changed under Shortcuts: opening Snicker, moving between GIFs, copying, favoriting, saving, and switching between Favorites, Recent and Trending. Handy for keyboards without arrow keys.
- New shortcuts: ⌘S saves the chosen GIF to Downloads, and ⌘1, ⌘2 and ⌘3 show Favorites, Recent and Trending.
- Choose what Snicker opens on: Trending, Favorites, Recent, or whatever you used last.
- After an update, Snicker opens with what’s new in that version, and a link to the full changelog.

### Changed

- Launch at Login, Random File Names, Clear Recent GIFs and the API key moved from the ⋯ menu into Settings.

## [1.2.0] - 2026-09-28

### Added

- An uninstall command: add `-s -- --uninstall` to the install command. It keeps your favorites and settings.
- Instructions for AI coding agents to install, check and uninstall Snicker, in `docs/install/agent.md`.
- Right-click (or Control-click) the menu bar icon for the same menu as the ⋯ button.
- An About Snicker window with the version, build number and links to support the creator and to GitHub.

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

[Unreleased]: https://github.com/Luis-Sejer/snicker-gif/compare/v1.4.1...HEAD
[1.4.1]: https://github.com/Luis-Sejer/snicker-gif/compare/v1.4.0...v1.4.1
[1.4.0]: https://github.com/Luis-Sejer/snicker-gif/compare/v1.3.0...v1.4.0
[1.3.0]: https://github.com/Luis-Sejer/snicker-gif/compare/v1.2.0...v1.3.0
[1.2.0]: https://github.com/Luis-Sejer/snicker-gif/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/Luis-Sejer/snicker-gif/compare/v1.0.1...v1.1.0
[1.0.1]: https://github.com/Luis-Sejer/snicker-gif/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/Luis-Sejer/snicker-gif/releases/tag/v1.0.0
