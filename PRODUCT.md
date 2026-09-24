# Product

<!-- impeccable:product-schema 1 -->

## Platform

web (the marketing site). The product itself is a native macOS app; its design follows Apple's Human Interface Guidelines and Liquid Glass.

## Stack

Delegated: plain static HTML/CSS/JS in `docs/`, served by GitHub Pages with no build step. Chosen because it is one page, loads fastest, needs no toolchain, and is easy for people and AI agents to edit.

## Users

Two audiences, weighted equally:

- **Office workers** who live in Microsoft Teams or Slack all day and want a fast, fun reaction GIF without leaving what they are doing. Their pain: GIF pickers that don't paste into Teams.
- **Mac enthusiasts** who collect well-crafted menu bar apps and care about native design, small size and keyboard control.

## Product Purpose

Snicker is a macOS menu bar GIF search. Press ⌘⌥V, type, click a GIF, and paste it anywhere. Success is a GIF in the conversation within a few seconds, from anywhere on the Mac.

## Positioning

The lead promise is speed and fun: the perfect reaction one shortcut away, from any app. Supporting proof: it pastes everywhere, including Microsoft Teams where most GIF pickers fail, because it puts both a file URL and raw GIF data on the clipboard. Teams is a feature further down, not the headline (the user's decision: few people know it's a problem). It is a native SwiftUI app of about 2 MB (1.2 MB download), free and open source, with no account and no setup.

## Operating Context

Used mid-conversation in chat apps (Teams, Slack, Discord, Messages, Mail). Opened by a global shortcut or the menu bar icon, used for seconds, then gone. Installed via a one-line `curl` command or a zip from GitHub Releases; not on the Mac App Store and not notarized, so manual installs need System Settings → Privacy & Security → Open Anyway.

## Capabilities and Constraints

- Search (Trending when empty), search suggestions, quick picks
- Click to copy, drag into any app, Copy Link, Save to Downloads, Open on KLIPY
- Favorites and Recent, kept between launches
- Keyboard control: ↑↓ choose, Return copy, ⇧Return copy link, ⌘D favorite
- Launch at Login, Random File Names
- Requires macOS 26 or later on Apple Silicon
- GIFs come from KLIPY; the app shows "Powered by KLIPY"
- Pricing: say only that it is free (and open source, MIT). Paid features may come later; make no promises about the future.

## Brand Commitments

- Name: Snicker. Icon: warm orange→pink→purple gradient tile with two tilted cards, the front one reading "GIF" (the smirk under them was removed at the user's request). Menu bar icon: the same two cards as a template glyph.
- The icon's gradient lives in the icon only. Around it the brand is Apple's light palette with blue as the single accent; pink or red fields are not part of the brand (the user's decision).
- The app's look is Apple Liquid Glass; the product voice is playful but plain.

## Evidence on Hand

- `docs/assets/icon.png`: app icon (1024px)
- `docs/assets/hero.webp`, `docs/assets/hero.png`: animated and still render of the app in use (light theme)
- `docs/assets/snicker-launch.mp4` and `poster.jpg`: 15-second launch video with voiceover and sound (light theme)
- `docs/assets/screens/`: real screenshots taken by the user: `glass.webp` (the popover over a green wallpaper, cropped to the menu bar and popover, showing the Liquid Glass effect) and `messages.webp` (a Messages conversation with pasted GIFs). Earlier screenshots with celebrities and branded characters were deliberately left out.
- No testimonials, user counts, press or reviews exist yet. Do not invent any.

## Product Principles

1. Seconds, not minutes: every step between wanting a GIF and sending it is a cost.
2. Works where people actually are, Teams included.
3. Native and small beats feature-heavy.
4. Nothing to set up and nothing collected.

## Accessibility & Inclusion

The app supports VoiceOver, full keyboard control, Reduce Motion and Auto-play Animated Images. The site must meet WCAG 2.2 AA, respect `prefers-reduced-motion`, and work fully by keyboard.
