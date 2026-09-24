---
version: 1
slug: "docs-index-html"
primary_target: "docs/index.html"
related_targets: []
---

## Scope

Landing page for Snicker at `docs/index.html`, served by GitHub Pages. Visitor mode: **Persuade**. Audiences: office workers in Teams/Slack and Mac enthusiasts, equally. Action: download (curl install or zip). Proof on hand: the real app UI (recreated), icon, animated hero render, 15s launch video. No testimonials or numbers exist; none may be invented. Price: say "Free" and open source, nothing about the future.

## Direction contract

THESIS: The site is a Mac desktop, and Snicker is already running on it. The category default, a centered headline over a screenshot with a feature grid, is refused; the product is demonstrated live in the first viewport.

OWN-WORLD: A deep dusk wallpaper of the icon's colors (orange #ff9f0a, pink #ff375f, purple #bf5af2, blue #0a84ff) blooming over near-black violet #120d24. A translucent macOS menu bar across the top; every surface is Liquid Glass: blurred, saturated, hairline-lit edges, 26px continuous corners. SF Pro via the system stack, tight display tracking. Emoji-on-gradient tiles stand in for GIFs, labeled as illustrations.

STORY: A visitor sees a working GIF popover hanging from the menu bar, types or clicks a chip, clicks a GIF, and sees it copied. They learn it pastes into Teams because it writes both a file and image data, then take the one-line install.

FIRST VIEWPORT: Menu bar full width. Left 45%: app icon, the "Snicker" wordmark at display scale, a one-line promise, and ⌘⌥V keycaps above the primary Download button plus a copyable curl line. Right: the live popover (420×560) anchored under the menu bar icon, with its arrow, search focused and Trending loaded. Pressing ⌘⌥V toggles it. The search field is not auto-focused on page load: autofocus would take keyboard focus from the skip link and jump the page on phones. It focuses when ⌘⌥V or the menu bar icon opens the popover.

FORM: The Menu Bar Site; position 7 of 7 on the ordered list (dealt by the roll, chosen by the user); raised by "Clipboard Anatomy" (position 4) as the second section. Seed key f4cd5ac6.

FINISH: unreviewed and undocumented is unfinished; this build ends with the finish review, the verdict, DESIGN.md, and every shipping raster carrying its provenance

## Memorable moment

Typing in the page's popover actually filters the grid, and clicking a GIF shows "Copied" and puts a real link on the clipboard.

## Signature interaction and motion grammar

Signature: the working popover, toggled by ⌘⌥V or the menu bar icon. Motion: glass springs from the menu bar icon (scale from top center with slight overshoot), tiles stagger in, the Copied badge pops; the anatomy section splits the GIF into two layers on scroll. All motion stops under prefers-reduced-motion.

## Unresolved

Phone layout: the desktop metaphor collapses to a stacked page with the popover as a full-width card and no menu bar.
