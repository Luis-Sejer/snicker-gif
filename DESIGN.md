---
name: Snicker
description: GIF search in your Mac menu bar; the site is a Mac desktop with Snicker already running on it.
colors:
  night: "#120d24"
  ink: "#f5f3fa"
  ink-secondary: "#c9c3dc"
  ink-tertiary: "#a79fbf"
  system-blue: "#0a84ff"
  blue-fill: "#0066cc"
  blue-fill-hover: "#0071e3"
  system-pink: "#ff375f"
  system-orange: "#ff9f0a"
  system-purple: "#bf5af2"
  link-sky: "#9ecbff"
  glass: "rgb(38 34 52 / 0.55)"
  glass-strong: "rgb(30 26 44 / 0.78)"
  glass-edge: "rgb(255 255 255 / 0.16)"
  glass-lit: "rgb(255 255 255 / 0.2)"
  glass-fill: "rgb(255 255 255 / 0.12)"
  menubar-glass: "rgb(20 16 36 / 0.42)"
typography:
  display:
    fontFamily: "-apple-system, BlinkMacSystemFont, \"SF Pro Text\", \"SF Pro Display\", system-ui, \"Segoe UI\", Roboto, sans-serif"
    fontSize: "clamp(4rem, 2rem + 8vw, 7.5rem)"
    fontWeight: 800
    lineHeight: 0.92
    letterSpacing: "-0.04em"
  headline:
    fontFamily: "-apple-system, BlinkMacSystemFont, \"SF Pro Text\", \"SF Pro Display\", system-ui, \"Segoe UI\", Roboto, sans-serif"
    fontSize: "clamp(2rem, 1.2rem + 3vw, 3.5rem)"
    fontWeight: 700
    lineHeight: 1.04
    letterSpacing: "-0.035em"
  title:
    fontFamily: "-apple-system, BlinkMacSystemFont, \"SF Pro Text\", \"SF Pro Display\", system-ui, \"Segoe UI\", Roboto, sans-serif"
    fontSize: "clamp(1.25rem, 1rem + 1vw, 1.75rem)"
    fontWeight: 400
    lineHeight: 1.35
  lead:
    fontFamily: "-apple-system, BlinkMacSystemFont, \"SF Pro Text\", \"SF Pro Display\", system-ui, \"Segoe UI\", Roboto, sans-serif"
    fontSize: "19px"
    fontWeight: 400
    lineHeight: 1.5
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
  item: "7px"
  tile: "12px"
  menu: "14px"
  card: "16px"
  panel: "18px"
  window: "26px"
  pill: "999px"
spacing:
  tight: "6px"
  gap: "12px"
  menubar: "32px"
  gutter: "clamp(16px, 4vw, 64px)"
  section: "clamp(88px, 14vh, 160px)"
components:
  button-primary:
    backgroundColor: "{colors.blue-fill}"
    textColor: "{colors.ink}"
    typography: "{typography.label}"
    rounded: "{rounded.pill}"
    padding: "0 22px"
    height: "48px"
  button-primary-hover:
    backgroundColor: "{colors.blue-fill-hover}"
  button-glass:
    backgroundColor: "{colors.glass-fill}"
    textColor: "{colors.ink}"
    rounded: "{rounded.pill}"
    padding: "0 22px"
    height: "48px"
  command-copy:
    backgroundColor: "{colors.glass}"
    textColor: "{colors.ink-secondary}"
    typography: "{typography.mono}"
    rounded: "{rounded.pill}"
    padding: "0 8px 0 18px"
    height: "48px"
  search-field:
    backgroundColor: "{colors.glass-fill}"
    textColor: "{colors.ink}"
    typography: "{typography.body}"
    rounded: "{rounded.pill}"
    padding: "0 12px 0 14px"
    height: "40px"
  chip:
    backgroundColor: "{colors.glass-fill}"
    textColor: "{colors.ink}"
    rounded: "{rounded.pill}"
    padding: "0 10px"
    height: "26px"
  chip-selected:
    backgroundColor: "{colors.blue-fill}"
  popover:
    backgroundColor: "{colors.glass}"
    rounded: "{rounded.window}"
    width: "420px"
    height: "560px"
  window:
    backgroundColor: "{colors.glass-strong}"
    rounded: "{rounded.panel}"
  context-menu:
    backgroundColor: "{colors.glass-strong}"
    rounded: "{rounded.menu}"
    padding: "6px"
  context-menu-item-active:
    backgroundColor: "{colors.blue-fill}"
    rounded: "{rounded.item}"
    padding: "7px 12px"
  menubar:
    backgroundColor: "{colors.menubar-glass}"
    height: "{spacing.menubar}"
    padding: "0 14px"
---

# Design System: Snicker

The web tokens below govern the marketing site in `docs/` only; the native macOS app in `Sources/` follows Apple HIG and Liquid Glass through SwiftUI system materials and is not governed by them.

## Overview

**Creative North Star: "The Running Desktop"**

The site is a Mac desktop at dusk, and Snicker is already running on it. A fixed wallpaper of the app icon's colors blooms behind everything; a translucent menu bar crosses the top; every surface that holds content is a pane of Liquid Glass floating over that wallpaper: blurred, saturated, lit along its top edge by a hairline. Sections are not bands or cards but windows, menus and popovers a Mac user already knows, so the page demonstrates the product instead of describing it.

The type is Apple's own system face with tight display tracking, because the product's look is pinned to Apple's. Colour comes from two sources only: the wallpaper and Apple's system accents. Density is low and generous; motion is springy where macOS springs (popover open, copy confirmation) and otherwise quiet, and it all stops under reduced motion.

**Key Characteristics:**
- Fixed dusk wallpaper (four radial blooms over near-black violet) under every surface.
- Glass panes: translucent fill, backdrop blur 20-34px with saturate 1.6-1.8, 1px white hairline edge, inset top highlight.
- macOS vocabulary as structure: menu bar, popover with arrow, context menu, window bars with traffic lights, keycaps.
- SF Pro system stack, heavy weights, negative tracking at display sizes.
- Pill controls everywhere a control is pressable.

## Colors

A dark, violet-black night lit by Apple's saturated system accents, with all surfaces taking their colour from the wallpaper through glass.

### Primary
- **Filled Control Blue** (`blue-fill`): the fill of every primary, selected or active control: Download button, selected chip, highlighted context-menu row, skip link. Deeper than Apple's system blue so white text passes 4.5:1; hover lifts to `blue-fill-hover`.
- **System Blue** (`system-blue`): never a fill behind text. Focus rings (2px outline, 3px offset), the search field's focus glow, and the selected-tile inset ring.

### Secondary
- **System Pink** (`system-pink`): text caret, list bullets in the feature list, selection highlight (at 55% alpha). Small, warm punctuation.

### Tertiary
- **System Orange** and **System Purple** (`system-orange`, `system-purple`): icon strokes that distinguish paired concepts (file vs. image data). They also appear, with pink and blue, as the wallpaper's blooms (`#ff7a3d`, `#6a4bff`, `#e0307a`, `#1e90ff`, variants of the icon palette tuned for the gradient).

### Neutral
- **Dusk Night** (`night`): page background and the base the wallpaper blooms over; also `theme-color`.
- **Frost White** (`ink`): primary text and headings. Pure `#fff` is used for text sitting on filled or glass controls.
- **Lavender Mist** (`ink-secondary`): body copy in sections, promise line, secondary text inside panes.
- **Dim Lavender** (`ink-tertiary`): fine print, labels, window-bar titles, keyboard hints, `dt` labels.
- **Sky Link** (`link-sky`): inline links; hover to white. Underlined, 1px, offset 0.2em.
- **Glass** (`glass`), **Strong Glass** (`glass-strong`), **Glass Edge** (`glass-edge`), **Glass Lit** (`glass-lit`), **Glass Fill** (`glass-fill`), **Menu Bar Glass** (`menubar-glass`): the material. `glass` for the popover and floating layers, `glass-strong` for windows, chat panes and menus that carry dense text, `glass-fill` for controls sitting on a pane.

### Named Rules
**The Wallpaper Is the Palette Rule.** Surfaces never carry their own brand colour. They are translucent, and colour arrives from the wallpaper behind them. A solid coloured section background breaks the world.

**The Two Blues Rule.** Text on blue sits on `blue-fill`. `system-blue` is for rings and outlines only.

## Typography

**Display Font:** SF Pro via the system stack (`-apple-system, BlinkMacSystemFont, "SF Pro Text", "SF Pro Display", system-ui`, falling back to Segoe UI and Roboto)
**Body Font:** the same stack
**Label/Mono Font:** SF Mono via `ui-monospace, "SF Mono", Menlo, monospace`

**Character:** Deliberately Apple's own voice. The system face is chosen, not defaulted, because the product's look is pinned to macOS; weight and tracking carry the hierarchy.

### Hierarchy
- **Display** (800, clamp 4rem to 7.5rem, 0.92, -0.04em): the "Snicker" wordmark only.
- **Headline** (700, clamp 2rem to 3.5rem, 1.04, -0.035em): section headings, balanced wrap. Inside a window head it steps down to clamp 1.6rem to 2.5rem.
- **Title** (400, clamp 1.25rem to 1.75rem, 1.35): the hero promise, max 30ch, emphasis in 650 Frost White.
- **Lead** (19px): section intro paragraphs (max 60ch) and FAQ questions (at 600).
- **Body** (17px, 1.5): running text, 58-65ch; 15px inside panes.
- **Label** (600, 13px): window-bar titles, menu bar (13.5px), chat titles (12px), popover footer (11px). Sentence case; never uppercase-tracked.
- **Mono** (500, 14-15px): shell commands only.

### Named Rules
**The System Voice Rule.** One family for everything but shell commands. Hierarchy is weight (400 to 800) and negative tracking, never a second display face.

## Layout

The first viewport is a desktop: a two-column grid (copy, then a fixed 420px demo column) under a fixed 32px menu bar, max 1440px, with the popover sticky beneath the menu bar icon. Later sections sit in a 1200px column (FAQ 820px, info window 760px) with side padding `gutter` and top padding `section`. Gaps inside panes run in 6px (tiles, chips) and 12px (actions, rows) steps; pane padding is 14-28px.

At 1080px the desktop collapses to one column, the popover centres below the copy and loses its arrow, and the anatomy diagram stacks without connectors. At 720px the menu bar keeps only the app name, keycaps hide, actions stack full width, and the popover becomes a full-width 520px card.

## Elevation & Depth

Depth is material plus soft, ambient shadow: glass panes blur what is behind them and cast a large, low-opacity black shadow, with an inset 1px white highlight along the top edge standing in for light.

### Shadow Vocabulary
- **Window float** (`box-shadow: 0 30px 80px rgb(0 0 0 / 0.45), inset 0 1px 0 var(--glass-lit)`): popover, info/player/terminal windows (0.42), context menu (`0 30px 70px`).
- **Layer float** (`box-shadow: 0 16px 40px rgb(0 0 0 / 0.3)`): anatomy layers and chat panes.
- **Control lift** (`box-shadow: 0 8px 20px rgb(0 0 0 / 0.35), inset 0 1px 0 rgb(255 255 255 / 0.28)`): primary button; hover deepens to `0 12px 26px / 0.4` with a 1px rise.
- **Keycap** (`box-shadow: inset 0 -3px 0 rgb(0 0 0 / 0.22), 0 6px 16px rgb(0 0 0 / 0.25)`): physical key bevel; pressing sinks it 3px.
- **Icon drop** (`filter: drop-shadow(0 18px 28px rgb(0 0 0 / 0.4))`): app icon art only.

### Named Rules
**The Lit Edge Rule.** Every floating glass pane has a 1px `glass-edge` border and, when it is a window or menu, an inset `glass-lit` top highlight. Glass without an edge reads as a smudge.

## Shapes

Continuous-feeling rounded rectangles in a macOS ladder: the popover at `window` (26px), windows and chat panes at `panel` (18px), floating layers at `card` (16px), menus at `menu` (14px), GIF tiles and keycaps at `tile` (12px), menu rows at `item` (7px). Every pressable control (buttons, chips, search, command line, badges) is a full pill. Circles only for traffic lights, favourite stars and bullets. Borders are always 1px white hairlines at 8-35% alpha; dividers are 1px at 8-12%.

## Components

### Buttons
Tactile glass pills that sit in the world rather than on it.
- **Shape:** full pill (999px), 48px tall, 22px side padding, 600 16px label, optional 18px stroked SVG icon.
- **Primary:** `blue-fill` with white text and control lift; one per view (Download).
- **Hover / Focus:** 1px rise, deeper shadow, `blue-fill-hover`; focus is the global 2px System Blue ring.
- **Glass:** `glass-fill` with a 1px 20% white edge; hover to 20% fill. Secondary actions inside panes (Copy command).
- **Command line:** a glass pill showing the shell command in mono with a nested "Copy" pill; hover brightens the nested pill.
- **Play:** 64px glass pill over video, scales to 1.04 on hover.

### Chips
- **Style:** 26px pills, `glass-fill`, 1px 14% white edge, 500 12px label with optional 12px glyph.
- **State:** pressed chips fill with `blue-fill` and a `#3d9dff` edge; hover brightens to 18% white.

### Cards / Containers
- **Corner Style:** per the Shapes ladder.
- **Background:** `glass` or `glass-strong` over the wallpaper.
- **Shadow Strategy:** window float or layer float.
- **Border:** 1px `glass-edge`.
- **Internal Padding:** 14-18px for layers and chat panes, 22-28px for window bodies.

### Inputs / Fields
- **Style:** 40px pill, 10% white fill, 1px 14% edge, inset top highlight, 16px stroked search glyph in Dim Lavender, 17px text.
- **Focus:** edge turns System Blue at 80% with a 3px 30% System Blue glow.

### Navigation
The macOS menu bar: fixed, 32px, `menubar-glass` with 24px blur and 1.7 saturate, 13.5px labels, the app name in 700. Items are 6px-rounded hover targets (16% white). The right side carries the Snicker template glyph (toggles the demo; 24% white when expanded) and a live tabular clock. On phones only the app name remains.

### Window
Info, player and terminal panes share one chrome: `glass-strong`, `panel` corners, window float, and a 40px window bar with red/yellow/green traffic lights (`#ff5f57`, `#febc2e`, `#28c840`), a 600 13px Dim Lavender title and an 8% white bottom divider.

### Popover (signature)
The live demo: 420x560 glass at `window` corners with a 22x11 arrow that tracks the menu bar icon. It springs open from its top-right origin (`cubic-bezier(0.34, 1.4, 0.64, 1)`, 0.45s) and closes by scaling to 0.9 with an 8px blur. Inside: search field, horizontally scrolling chips, a three-column masonry of GIF tiles, and an 11px footer of keyboard hints.

### GIF Tile
Emoji on a two-stop 135deg gradient (`--a` to `--b`) at `tile` corners with a white top sheen, standing in for GIFs and labelled as illustrations. Tiles stagger in (28ms steps), the emoji bobs, hover scales to 1.04, keyboard selection draws a 2.5px System Blue inset ring, a star badge appears on hover (filled `#ffd60a` when favourited), and copying dims the tile and pops a glass "Copied" pill.

### Context Menu
`glass-strong`, `menu` corners, 6px padding, 7px-rounded rows with right-aligned shortcut glyphs in Dim Lavender; the active row fills `blue-fill`; separators are 1px 12% white inset 10px.

### Keycaps
46px glass keys at `tile` corners, 600 20px glyphs, keycap bevel shadow, sinking 3px when the shortcut fires.

## Do's and Don'ts

### Do:
- **Do** put every content surface on glass over the fixed wallpaper: translucent fill, backdrop blur 20-34px with saturate 1.6-1.8, 1px `glass-edge`.
- **Do** borrow structure from macOS itself (menu bar, popover, context menu, window bar with traffic lights, keycaps) instead of inventing section chrome.
- **Do** use `blue-fill` under any white text on blue, and `system-blue` for the 2px focus ring with 3px offset.
- **Do** make every pressable control a full pill.
- **Do** write macOS shortcut glyphs (⌘ ⌥ ⇧ ⏎) as real keycaps or menu shortcuts; they are the world's native notation.
- **Do** stop all animation under `prefers-reduced-motion`, and keep scroll-driven effects progressive (content visible without them).

### Don't:
- **Don't** give a section an opaque coloured background; colour comes from the wallpaper through glass.
- **Don't** put white text on `system-blue` (#0a84ff); it fails contrast.
- **Don't** add a second display typeface or uppercase tracked labels; hierarchy is SF Pro weight and tracking.
- **Don't** use hard, offset or coloured shadows; shadows are large, soft and black.
- **Don't** present emoji tiles as real GIFs; they are labelled illustrations.
