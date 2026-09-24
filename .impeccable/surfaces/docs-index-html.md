---
version: 1
slug: "docs-index-html"
primary_target: "docs/index.html"
related_targets: []
---

## Scope

Landing page for Snicker at `docs/index.html`, served by GitHub Pages. Visitor mode: **Persuade**. Audiences: office workers in Teams/Slack and Mac enthusiasts, equally. Action: download (curl install or zip). Proof on hand: the real app UI (recreated), icon, animated hero render, 15s launch video. No testimonials or numbers exist; none may be invented. Price: say "Free" and open source, nothing about the future.

## Direction contract

THESIS: The site is a Mac desktop in light mode, and Snicker is already running on it. The category default (centered headline over a screenshot, feature card grid) and the AI-default dark gradient glow are both refused; the product is demonstrated live in the first viewport, and the page reads like an Apple editorial product page.

OWN-WORLD: Apple light gray desktop #f5f5f7 with ink #1d1d1f; macOS light-mode glass (white translucent, hairline edge, soft layered shadow) for the menu bar, popover and Dock. Editorial rhythm by flat fields: white bands (#ffffff) and one black field (#0b0b0d); blue #0071e3 is the only accent and there are no gradients outside GIF content (the pink field was dropped on 2026-09-24: "the red isn't really part of our brand"). SF Pro via the system stack at Apple's semibold display weight. Small draggable GIF windows on the desktop, a reaction marquee, real app screenshots that settle from a 3D tilt, and a Dock with spring magnification.

STORY: A visitor sees a working GIF popover hanging from the menu bar, types or clicks a chip, clicks a GIF, and sees it copied. They see the right-click menu, learn it pastes everywhere (Teams included) because it writes both a file and image data, then take the one-line install.

FIRST VIEWPORT: Menu bar full width (light). Left: app icon, the "Snicker" wordmark at display scale, a one-line promise, and ⌘⌥V keycaps above the primary Download button plus a copyable curl line. Right: the live popover (420×560) anchored under the menu bar icon with its arrow, Trending loaded. Around them, a few draggable GIF windows sit on the desktop. Pressing ⌘⌥V toggles the popover. The search field is not auto-focused on page load: autofocus would take keyboard focus from the skip link and jump the page on phones. It focuses when ⌘⌥V or the menu bar icon opens the popover.

FORM: The Menu Bar Site; position 7 of 7 on the ordered list (dealt by the roll, chosen by the user); raised by "Clipboard Anatomy" (position 4). Seed key f4cd5ac6. World revised by the user (2026-09-24): "more like Apple and less AI gradient, more editorial", references heyclicky.com and superlist.craftedbygc.com, keep the menu bar header. The user-pinned direction replaced the dusk-wallpaper world without a new roll.

FINISH: unreviewed and undocumented is unfinished; this build ends with the finish review, the verdict, DESIGN.md, and every shipping raster carrying its provenance

## Memorable moment

Typing in the page's popover actually filters the grid, and clicking a GIF shows "Copied" and puts a real link on the clipboard.

## Signature interaction and motion grammar

Signature: the working popover, toggled by ⌘⌥V or the menu bar icon. Motion: glass springs from the menu bar icon (scale from top center with slight overshoot), tiles stagger in only when the results change, the Copied badge pops in place without re-rendering the grid; desktop GIF windows drag; the reaction marquee scrolls; the anatomy section splits the GIF into two layers on scroll. All motion stops under prefers-reduced-motion.

## Unresolved

Phone layout: the desktop metaphor collapses to a stacked page with the popover as a full-width card and no menu bar.
