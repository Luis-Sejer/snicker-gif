# Roadmap

Ideas that fit Snicker but aren't planned yet. Want one? Say so in an [issue](https://github.com/Luis-Sejer/snicker-gif/issues/new/choose), or build it: see [CONTRIBUTING.md](CONTRIBUTING.md).

## Potential future features

- **GIFs in your language.** KLIPY takes a locale, so Snicker could follow the Mac's language and find Danish GIFs for "tillykke".
- **Stickers.** KLIPY also has stickers with transparent backgrounds (`searchfilter=sticker`). A GIF / Sticker switch in the popover.
- **Paste for me.** Choosing a GIF pastes it straight into the chat you came from. Needs macOS's Accessibility permission, so it would be opt-in.
- **Spotlight and Shortcuts.** "Find a GIF of…" from Spotlight, and an action in the Shortcuts app, through App Intents. Needs checking that it builds without full Xcode.
- **Try instead.** When a search finds little or nothing, suggest related searches or what's trending. KLIPY's `search_suggestions` and `trending_terms` endpoints cover this, though suggestions are thin for niche searches.
