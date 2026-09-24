---
name: Snicker
description: GIF search in your Mac menu bar; the site is a light Mac desktop with Snicker already running on it, set as an Apple editorial product page.
colors:
  paper: "#f5f5f7"
  surface: "#ffffff"
  ink: "#1d1d1f"
  ink-secondary: "#515154"
  ink-tertiary: "#6e6e73"
  rule: "rgb(0 0 0 / 0.1)"
  tint: "rgb(0 0 0 / 0.05)"
  tint-strong: "rgb(0 0 0 / 0.09)"
  glass: "rgb(255 255 255 / 0.72)"
  glass-edge: "rgb(0 0 0 / 0.08)"
  glass-lit: "rgb(255 255 255 / 0.9)"
  menubar-glass: "rgb(246 246 248 / 0.72)"
  link: "#0066cc"
  night: "#0b0b0d"
  night-surface: "#1c1c1e"
  night-ink-secondary: "#a1a1a6"
  system-blue: "#0a84ff"
  blue-fill: "#0071e3"
  blue-fill-hover: "#0068d1"
  system-orange: "#ff9f0a"
  system-purple: "#bf5af2"
typography:
  display:
    fontFamily: "-apple-system, BlinkMacSystemFont, \"SF Pro Text\", \"SF Pro Display\", system-ui, \"Segoe UI\", Roboto, sans-serif"
    fontSize: "clamp(4rem, 2rem + 6vw, 6rem)"
    fontWeight: 700
    lineHeight: 0.95
    letterSpacing: "-0.04em"
  headline:
    fontFamily: "-apple-system, BlinkMacSystemFont, \"SF Pro Text\", \"SF Pro Display\", system-ui, \"Segoe UI\", Roboto, sans-serif"
    fontSize: "clamp(2.25rem, 1.2rem + 3.6vw, 4.5rem)"
    fontWeight: 600
    lineHeight: 1.02
    letterSpacing: "-0.035em"
  title:
    fontFamily: "-apple-system, BlinkMacSystemFont, \"SF Pro Text\", \"SF Pro Display\", system-ui, \"Segoe UI\", Roboto, sans-serif"
    fontSize: "clamp(1.3rem, 1rem + 1vw, 1.8rem)"
    fontWeight: 400
    lineHeight: 1.35
    letterSpacing: "-0.01em"
  lead:
    fontFamily: "-apple-system, BlinkMacSystemFont, \"SF Pro Text\", \"SF Pro Display\", system-ui, \"Segoe UI\", Roboto, sans-serif"
    fontSize: "clamp(1.15rem, 1rem + 0.5vw, 1.4rem)"
    fontWeight: 400
    lineHeight: 1.45
  body:
    fontFamily: "-apple-system, BlinkMacSystemFont, \"SF Pro Text\", \"SF Pro Display\", system-ui, \"Segoe UI\", Roboto, sans-serif"
    fontSize: "17px"
    fontWeight: 400
    lineHeight: 1.5
  label:
    fontFamily: "-apple-system, BlinkMacSystemFont, \"SF Pro Text\", \"SF Pro Display\", system-ui, \"Segoe UI\", Roboto, sans-serif"
    fontSize: "13px"
    fontWeight: 600
    lineHeight: 1
  mono:
    fontFamily: "ui-monospace, \"SF Mono\", Menlo, monospace"
    fontSize: "15px"
    fontWeight: 500
    lineHeight: 1.6
rounded:
  row: "6px"
  tile: "12px"
  window: "14px"
  layer: "16px"
  player: "20px"
  dock: "22px"
  popover: "26px"
  pill: "999px"
spacing:
  tight: "6px"
  gap: "12px"
  menubar: "32px"
  gutter: "clamp(16px, 4vw, 64px)"
  section: "clamp(96px, 16vh, 180px)"
components:
  button-primary:
    backgroundColor: "{colors.blue-fill}"
    textColor: "{colors.surface}"
    typography: "{typography.body}"
    rounded: "{rounded.pill}"
    padding: "0 22px"
    height: "48px"
  button-primary-hover:
    backgroundColor: "{colors.blue-fill-hover}"
  button-secondary:
    backgroundColor: "{colors.tint-strong}"
    textColor: "{colors.ink}"
    rounded: "{rounded.pill}"
    padding: "0 22px"
    height: "48px"
  button-secondary-hover:
    backgroundColor: "{colors.rule}"
  command-copy:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.ink-secondary}"
    typography: "{typography.mono}"
    rounded: "{rounded.pill}"
    padding: "0 7px 0 18px"
    height: "48px"
  search-field:
    backgroundColor: "{colors.tint}"
    textColor: "{colors.ink}"
    typography: "{typography.body}"
    rounded: "{rounded.pill}"
    padding: "0 12px 0 14px"
    height: "40px"
  chip:
    backgroundColor: "{colors.tint}"
    textColor: "{colors.ink}"
    rounded: "{rounded.pill}"
    padding: "0 10px"
    height: "26px"
  chip-selected:
    backgroundColor: "{colors.blue-fill}"
    textColor: "{colors.surface}"
  popover:
    backgroundColor: "{colors.glass}"
    rounded: "{rounded.popover}"
    width: "420px"
    height: "560px"
  window:
    backgroundColor: "{colors.surface}"
    rounded: "{rounded.window}"
  context-menu:
    backgroundColor: "{colors.menubar-glass}"
    rounded: "{rounded.tile}"
    padding: "6px"
  context-menu-item-active:
    backgroundColor: "{colors.blue-fill}"
    textColor: "{colors.surface}"
    rounded: "{rounded.row}"
    padding: "6px 10px"
  menubar:
    backgroundColor: "{colors.menubar-glass}"
    height: "{spacing.menubar}"
    padding: "0 14px"
  field-white:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.ink}"
    padding: "{spacing.section} 0"
  field-night:
    backgroundColor: "{colors.night}"
    textColor: "{colors.paper}"
    padding: "{spacing.section} 0"
  dock:
    backgroundColor: "{colors.glass}"
    rounded: "{rounded.dock}"
    padding: "7px 8px"
---

# Design System: Snicker

The web tokens below govern the marketing site in `docs/` only; the native macOS app in `Sources/` follows Apple HIG via SwiftUI system materials and is not governed by them.

## Overview

**Creative North Star: "The Light Desktop, Edited"**

The site is a Mac desktop in light mode with Snicker already running on it, and it reads like an Apple editorial product page. The ground is Apple's light gray (`paper`); a light translucent menu bar crosses the top; the live popover hangs from its menu bar icon; small GIF windows with traffic lights sit on the desktop and can be dragged. The page then moves in editorial beats rather than cards: a big reaction marquee, a pinned scroll story, two real app screenshots overlapping like windows, then flat full-bleed fields: a white band on the gray page (the way Apple paces its product pages), a near-black field for the clipboard diagram, and a black field for the video.

Glass is reserved for the system chrome a Mac already has in light mode: the menu bar, the popover and the Dock. Everything else is either flat paper, a white window, or a solid field. Type is Apple's system face at semibold display weight, big and tight. Filled-control blue is the only accent. Icons are Phosphor (MIT) fill glyphs on a 256 grid, never hand-drawn. Motion is choreographed with self-hosted GSAP 3.15 (`docs/vendor/gsap`, driven from `docs/motion.js`): an intro that tells the shortcut story, a scrubbed story, headlines revealed line by line, real screenshots settling out of a 3D tilt, a right-click menu, a clipboard diagram drawn on scroll, a video that zooms to size, and a marquee that follows scroll velocity. UI responses (the popover toggle, tile entrance, Copied badge) are fast and use a strong ease-out; all motion reverts to the static page under reduced motion.

**Key Characteristics:**
- Light only: `paper` ground, `ink` text, `color-scheme: light`.
- macOS light-mode glass (white 72% fill, 24-34px blur at 1.8 saturate, 8% black hairline, white inset top highlight, soft layered shadow) for menu bar, popover and Dock only.
- Flat full-bleed fields: white bands (`surface`) and `night` fields; no gradients.
- One accent: `blue-fill` (#0071e3); `system-blue` only for rings and carets.
- SF Pro system stack at 600 for display sizes, negative tracking.
- macOS vocabulary as structure: menu bar, popover with arrow, context menu, window bars with traffic lights, keycaps, Dock.
- Pill controls everywhere a control is pressable.

## Colors

Apple's light gray desktop and ink, paced by white bands and black fields, with one accent: Apple's filled-control blue.

### Primary
- **Filled Control Blue** (`blue-fill`): the only accent. Every filled control with white text (Download button, selected chip, highlighted context-menu row, skip link, Dock video tile), the facts-list bullets, the text caret and the 22% selection highlight. Apple's system blue is too light for white text, so fills use this deeper blue; hover to `blue-fill-hover`.
- **System Blue** (`system-blue`): never a fill behind text. The 2px focus ring (3px offset), the search field's focus edge and 3px 25% glow, the selected-tile 2.5px inset ring, the typing caret in the story.

### Tertiary
- **System Orange** and **System Purple** (`system-orange`, `system-purple`): functional icon colours only, telling paired concepts apart on the black field (file vs. image data). Not accents: never fills, text or controls.

### Neutral
- **Desktop Gray** (`paper`): page background and `theme-color`.
- **Window White** (`surface`): the white bands, windows, keycaps, the command line, draggable GIF windows; also the text colour on blue fills.
- **Ink** (`ink`): headings and primary text.
- **Graphite** (`ink-secondary`): leads, the promise, secondary copy, fact items on the white band.
- **Slate** (`ink-tertiary`): fine print, window-bar titles, keyboard hints, `dt` labels, placeholder text, marquee even words.
- **Hairline** (`rule`), **Tint** (`tint`), **Strong Tint** (`tint-strong`): dividers and borders; resting fill of search, chips and nested pills; hover fill and secondary button.
- **Glass** (`glass`), **Glass Edge** (`glass-edge`), **Glass Lit** (`glass-lit`), **Menu Bar Glass** (`menubar-glass`): the light-mode material.
- **Link Blue** (`link`): inline links, 1px underline at 0.2em offset, 2px on hover.
- **Night** (`night`), **Night Surface** (`night-surface`), **Night Secondary** (`night-ink-secondary`): the black fields, the panes on them, and their secondary text; primary text there is `paper`.

### Named Rules
**The Light Only Rule.** The site has one theme, light. There is no `prefers-color-scheme: dark` variant; dark mode was removed on purpose so one theme can be excellent. Darkness appears only as a deliberate `night` field.

**The Flat Field Rule.** A field is one solid fill edge to edge: a `surface` band with `rule` hairlines top and bottom, or `night`. No gradients anywhere: GIF stand-in tiles are single solid fills. The only gradient in the build is the marquee's edge-fade mask, which is transparency, not colour.

**The One Accent Rule.** `blue-fill` is the only accent colour. There is no brand pink or red; it was removed by decision ("the red isn't really part of our brand"). Colour beyond blue lives only inside GIF content (the solid-fill emoji tiles) the paired functional icons on the black field, and the Dock's app-style tiles (ink, graphite, blue, orange, white).

**The Two Blues Rule.** White text sits on `blue-fill`. `system-blue` is for rings, outlines and the story's typing caret only.

## Typography

**Display Font:** SF Pro via the system stack (`-apple-system, BlinkMacSystemFont, "SF Pro Text", "SF Pro Display", system-ui`, falling back to Segoe UI and Roboto)
**Body Font:** the same stack
**Label/Mono Font:** SF Mono via `ui-monospace, "SF Mono", Menlo, monospace`

**Character:** Apple's own editorial voice: semibold, very large and tight at display sizes, plain and regular in body. The system face is chosen because the product's look is pinned to macOS.

### Hierarchy
- **Display** (700, clamp 4rem to 6rem, 0.95, -0.04em): the "Snicker" wordmark only.
- **Headline** (600, clamp 2.25rem to 4.5rem, 1.02, -0.035em): section headings, balanced wrap. The same voice runs larger for the video title (to 6rem, -0.045em), the marquee (to 6rem) and the story steps (to 3.6rem); inside the info window it steps down to 2.6rem.
- **Title** (400, clamp 1.3rem to 1.8rem, 1.35): the hero promise, max 26ch, emphasis in 600 `ink`.
- **Lead** (400, clamp 1.15rem to 1.4rem, 1.45): section intros, max 34em, in `ink-secondary`.
- **Body** (400, 17px, 1.5): running text, 58-65ch; 15px inside windows. FAQ questions at 600 20px.
- **Label** (600, 13px): window-bar titles, chat titles (12px); menu bar at 13.5px, popover footer at 11px. Sentence case; never uppercase-tracked.
- **Mono** (500, 14-15px): shell commands only.

### Named Rules
**The Semibold Voice Rule.** Display sizes are 600 with negative tracking; only the wordmark and the menu bar app name go to 700. One family for everything but shell commands.

## Layout

The first viewport is a desktop: a two-column grid (copy, then a fixed 420px demo column) under a fixed 32px menu bar, max 1440px, with the popover sticky beneath the menu bar icon and draggable GIF windows placed around it. The marquee then runs full width. After the marquee, the story is a pinned scene (420vh tall section, a sticky viewport-height two-column stage of steps and scene) that advances four steps with scroll; step changes come from IntersectionObserver markers, never a scroll listener. The real-screenshot section is a 0.8/1.2 two-column grid at 1200px with the two captures overlapping in a 760px stage under 1400px perspective. Fields are full bleed with content in a 1200px column; the video field is full bleed with a 1320px player. Windowed sections use a 1200px column (FAQ 860px, info window 780px). Side padding is `gutter`; vertical rhythm between beats is `section`. Inside panes, gaps step in 6px and 12px.

At 1080px the desktop collapses to one column, the popover centres below the copy and loses its arrow, GIF windows hide, and the anatomy diagram stacks without connectors. At 900px the story stacks and shows one step at a time, and the screenshots stack flat, centred at up to 380px. At 720px the menu bar keeps only the app name, keycaps hide, actions stack full width, and the popover becomes a full-width 520px card. The Dock appears only with a fine hovering pointer at 1080px and up.

## Elevation & Depth

Depth is soft, layered, black and low opacity, as in macOS light mode. Glass panes add blur and a white inset top highlight; windows are opaque white with the same shadow. On the black fields, panes use a deeper shadow.

### Shadow Vocabulary
- **Window** (`box-shadow: 0 24px 60px rgb(0 0 0 / 0.16), 0 2px 8px rgb(0 0 0 / 0.06)`): popover, Dock, info and terminal windows, story chat window, a dragged GIF window. Glass adds `inset 0 1px 0 var(--glass-lit)`.
- **Small** (`box-shadow: 0 10px 24px rgb(0 0 0 / 0.14), 0 1px 3px rgb(0 0 0 / 0.08)`): resting GIF windows on the desktop.
- **Tile lift** (`box-shadow: 0 10px 24px rgb(0 0 0 / 0.22)`): hovered GIF tile.
- **Night pane** (`box-shadow: 0 16px 40px rgb(0 0 0 / 0.4)`): anatomy layers and chat panes on the black field; the video player takes `0 40px 120px rgb(0 0 0 / 0.6)`.
- **Keycap** (`box-shadow: inset 0 -3px 0 var(--tint-strong), 0 4px 10px rgb(0 0 0 / 0.08)`): physical key bevel; pressing sinks it 3px.
- **Icon drop** (`filter: drop-shadow(0 14px 22px rgb(0 0 0 / 0.22))`): app icon art only.
- **Captured** (none added): the real screenshots are transparent PNG/WebP captures that carry their own macOS window shadows; CSS adds none.

### Named Rules
**The Glass Is Chrome Rule.** Glass is for what macOS itself renders as translucent chrome: the menu bar, the popover, the Dock (and the Dock label, the context menu, the Copied and Play badges). Content windows are opaque `surface`; sections are flat.

## Shapes

Continuous-feeling rounded rectangles in a macOS ladder: popover at `popover` (26px), Dock at `dock` (22px), video player at `player` (20px), night panes at `layer` (16px), windows at `window` (14px), GIF tiles, GIF windows, keycaps and the context menu at `tile` (12px), menu rows and menu bar items at `row` (6px). Dock tiles use a 23% squircle-like radius. Every pressable control (buttons, chips, search, command line, badges) is a full pill. Circles only for traffic lights, favourite stars and list bullets. Borders are 1px black hairlines at 8-10% on light, white at 8-10% on black.

## Components

### Buttons
Plain Apple pills, flat, no shadow.
- **Shape:** full pill (999px), 48px tall, 22px side padding, 500 17px label, optional 18px Phosphor icon.
- **Primary:** `blue-fill` with white text; one per view (Download for Mac).
- **Hover / Focus / Press:** `blue-fill-hover`, plus a 1px rise only on a fine hovering pointer; press scales to 0.97 in 100ms; focus is the global 2px `system-blue` ring at 3px offset.
- **Secondary:** `tint-strong` fill with `ink` text, hover to `rule`; on the terminal it inverts to 14% white.
- **Command line:** a white pill with a hairline edge showing the shell command in mono, with a nested `tint` "Copy" pill that darkens on hover.
- **Play:** 64px white-glass pill centred over the video, scales to 1.04 on hover (fine pointer only).

### Chips
- **Style:** 26px pills, `tint` fill, no border, 500 12px label with optional 12px Phosphor glyph.
- **State:** hover to `tint-strong`; pressed fills `blue-fill` with white text.

### White Band
A full-bleed `surface` field on the `paper` page with 1px `rule` hairlines top and bottom and `section` padding, content in a 1200px column. It holds the features copy (headline, lead, a facts list with 8px `blue-fill` dot bullets and `ink-secondary` items at 58ch) beside the right-click menu demo.

### Cards / Containers
- **Windows:** `surface`, `window` corners, 1px `glass-edge`, window shadow, and a 40px window bar with traffic lights (`#ff5f57`, `#febc2e`, `#28c840`), a 600 13px `ink-tertiary` title and a `rule` divider. The terminal is the dark variant (`#1e1e20`).
- **Night panes:** `night-surface`, `layer` corners, 10% white edge, night pane shadow, 14-18px padding.
- **Internal Padding:** 14-18px for panes, 22-28px for window bodies.

### Inputs / Fields
- **Style:** 40px pill, `tint` fill, transparent 1px edge, 17px Phosphor search glyph in `ink-tertiary`, 17px text, custom clear button.
- **Focus:** edge turns `system-blue` with a 3px 25% blue glow.

### Navigation
The macOS menu bar: fixed, 32px, `menubar-glass` with 24px blur and 1.8 saturate, `rule` bottom border, 13.5px labels, app name in 700. Items are 6px-rounded hover targets filling `tint-strong`. The right side carries the Snicker template glyph (toggles the demo; filled `tint-strong` when expanded) and a live tabular clock. On phones only the app name remains.

### Popover (signature)
The live demo: 420x560 glass at `popover` corners with a 22x11 arrow that tracks the menu bar icon. Toggled often by ⌘⌥V, so it is quick and flat: it opens from its top-right origin in 200ms and closes in 150ms (to scale 0.96, 6px up, fading out in 120ms), both on the strong ease-out `cubic-bezier(0.23, 1, 0.32, 1)`, with no overshoot or blur. Only the one-time intro lets it spring in. Inside: search field, horizontally scrolling chips, a three-column masonry of GIF tiles, and an 11px footer of keyboard hints.

### GIF Tile
An emoji on one solid fill (`--a`) at `tile` corners, standing in for a GIF and labelled as an illustration. Tiles stagger in (220ms strong ease-out, 28ms steps) only when results change, the emoji bobs, hover scales to 1.04 with tile lift (fine pointer only), keyboard selection draws a 2.5px `system-blue` inset ring, a star badge appears on hover (filled `#ffd60a` when favourited), and copying dims the tile and pops a white-glass "Copied" pill in 180ms.

### Desktop GIF Window
A 150px (small: 118px) white window with a 22px bar of 7px traffic lights and a file name, over a solid-fill GIF tile. Rests rotated a few degrees with the small shadow; dragging straightens it, scales to 1.05 and lifts to the window shadow.

### Context Menu
Near-opaque menu bar glass (`rgb(246 246 248 / 0.97)`), `tile` corners, 6px padding, 6px-rounded rows with right-aligned shortcut glyphs in `ink-secondary`; the active row fills `blue-fill`; separators are 1px `rule` inset 10px.

### Keycaps
46px white keys at `tile` corners, 500 20px glyphs, keycap bevel, sinking 3px when the shortcut fires. The story uses inline em-sized keycaps with the same bevel.

### Marquee
A full-width band of reaction words at headline weight (to 6rem), alternating `ink` and `ink-tertiary` with emoji between, its edges faded by a horizontal mask. It loops linearly over 40s; with GSAP it follows scroll velocity (up to 6x, in the scroll's direction) and eases back to base speed over 1.2s. Without GSAP it is a plain CSS loop.

### Story
A pinned scene: four large 600 steps at 18% opacity, the current one at full; beside them a white chat window and a glass popover act out open, type, copy and paste. With GSAP the scene is one scrubbed timeline (0.6 smoothing) across the section; without it, or under reduced motion, CSS plays each step's end state.

### Real Screenshots
Two real captures of the app (Messages and the popover search) overlapping like windows. They start tilted back in 3D (about 12-16 degrees on each axis, in opposite directions) and settle flat as the stage reaches the middle of the screen, drifting gently in parallax; on phones they sit flat and stacked. They are real product UI; the emoji tiles elsewhere are illustrations.

### Dock
Light glass at `dock` corners, fixed to the bottom centre, rising when the pointer reaches the bottom 64px. Icons are 54px and magnify toward 96px with a cosine falloff over 150px, each size driven by a per-frame spring (stiffness 1500, damping 120). Tiles are solid-fill squircles with Phosphor fill glyphs; a glass label floats above the hovered icon. Hidden on touch and below 1080px; magnification is off under reduced motion.

## Do's and Don'ts

### Do:
- **Do** keep the ground `paper` and text `ink`; pace the page with full-bleed white bands and `night` fields.
- **Do** reserve glass (white 72% fill, 24-34px blur at 1.8 saturate, 1px `glass-edge`, `glass-lit` inset top) for macOS chrome: menu bar, popover, Dock.
- **Do** borrow structure from macOS itself (menu bar, popover, context menu, window bars with traffic lights, keycaps, Dock) instead of inventing section chrome.
- **Do** set display type in SF Pro at 600 with negative tracking (-0.035em to -0.045em).
- **Do** use `blue-fill` under any white text on blue, and `system-blue` for the 2px focus ring with 3px offset.
- **Do** make every pressable control a full pill.
- **Do** write macOS shortcut glyphs (⌘ ⌥ ⇧ ⏎) as real keycaps or menu shortcuts; they are the world's native notation.
- **Do** use Phosphor (MIT) icons, inlined as SVG.
- **Do** set GSAP starting states with `gsap.set()` and animate with `.to()`; never `from()` on visible content.
- **Do** drive scroll effects through ScrollTrigger or IntersectionObserver, and keep them progressive (content visible without GSAP).
- **Do** keep UI responses short on the strong ease-out `cubic-bezier(0.23, 1, 0.32, 1)`: popover 200ms open, 150ms close.
- **Do** gate hover motion behind `(hover: hover) and (pointer: fine)`.
- **Do** revert all choreography under `prefers-reduced-motion` (inside `gsap.matchMedia`), keeping only short fades.

### Don't:
- **Don't** add a dark theme or a `prefers-color-scheme: dark` block; the site is light only by decision.
- **Don't** add a second accent: no pink, red or brand colour beside `blue-fill`.
- **Don't** use gradients for colour: no gradient backgrounds, glows or two-stop GIF tiles. Transparency masks (the marquee edge fade) are the only exception.
- **Don't** put white text on `system-blue` (#0a84ff); it fails contrast.
- **Don't** add a second display typeface or uppercase tracked labels.
- **Don't** use hard, offset or coloured shadows; shadows are soft, layered and black.
- **Don't** present emoji tiles as real GIFs; they are labelled illustrations.
- **Don't** attach scroll event listeners.
- **Don't** hand-draw icons.
