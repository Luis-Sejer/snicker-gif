// The live popover demo: search, chips, favorites, keyboard, and ⌘⌥V to toggle.
// Tiles are emoji on solid colour, standing in for GIFs; clicking one copies the emoji.

const LIBRARY = [
  { emoji: "😂", tags: "lol laugh funny haha trending", a: "#ffd60a", b: "#ff7a00", h: 104 },
  { emoji: "🙏", tags: "thank you thanks please trending", a: "#64d2ff", b: "#0a4bd6", h: 150 },
  { emoji: "😎", tags: "cool wow nice trending", a: "#5e5ce6", b: "#bf5af2", h: 96 },
  { emoji: "💯", tags: "yes perfect agree trending", a: "#ff453a", b: "#8e1b4c", h: 130 },
  { emoji: "👍", tags: "yes ok agree thumbs trending", a: "#30d158", b: "#0a7d5a", h: 132 },
  { emoji: "🤯", tags: "wow mind blown omg trending", a: "#ff9f0a", b: "#c2410c", h: 110 },
  { emoji: "❤️", tags: "love thank you heart trending", a: "#ff2d92", b: "#6a1b9a", h: 150 },
  { emoji: "👀", tags: "look wow eyes trending", a: "#bf5af2", b: "#3a1c8c", h: 96 },
  { emoji: "🙌", tags: "yes party celebrate trending", a: "#34c759", b: "#1d6f42", h: 140 },
  { emoji: "😅", tags: "lol oops facepalm trending", a: "#0a84ff", b: "#5e5ce6", h: 110 },
  { emoji: "🫡", tags: "yes ok on it salute", a: "#ff9f0a", b: "#ff375f", h: 104 },
  { emoji: "🎉", tags: "party celebrate yay happy birthday", a: "#ff9f0a", b: "#ff375f", h: 92 },
  { emoji: "🕺", tags: "party dance happy", a: "#30d158", b: "#0a7d5a", h: 150 },
  { emoji: "🥳", tags: "party happy birthday celebrate", a: "#5e5ce6", b: "#bf5af2", h: 100 },
  { emoji: "🍾", tags: "party celebrate cheers", a: "#ff453a", b: "#8e1b4c", h: 130 },
  { emoji: "🪩", tags: "party dance disco", a: "#64d2ff", b: "#0a4bd6", h: 140 },
  { emoji: "💃", tags: "party dance happy", a: "#ff2d92", b: "#6a1b9a", h: 160 },
  { emoji: "🎊", tags: "party celebrate happy birthday", a: "#bf5af2", b: "#3a1c8c", h: 110 },
  { emoji: "🎈", tags: "party happy birthday", a: "#0a84ff", b: "#5e5ce6", h: 100 },
  { emoji: "🤦", tags: "facepalm no oops", a: "#ff9f0a", b: "#c2410c", h: 120 },
  { emoji: "🙅", tags: "no nope", a: "#ff453a", b: "#8e1b4c", h: 110 },
  { emoji: "🙄", tags: "no eye roll whatever", a: "#5e5ce6", b: "#3a1c8c", h: 96 },
  { emoji: "☕", tags: "good morning coffee", a: "#c2410c", b: "#6a1b9a", h: 120 },
  { emoji: "🌅", tags: "good morning sunrise", a: "#ff9f0a", b: "#ff375f", h: 100 },
  { emoji: "🤣", tags: "lol laugh funny", a: "#ffd60a", b: "#ff375f", h: 130 },
  { emoji: "😮", tags: "wow omg surprised", a: "#64d2ff", b: "#5e5ce6", h: 104 },
].map((gif, index) => ({ ...gif, id: String(index) }));

const QUICK_PICKS = ["Thank you", "LOL", "Yes", "No", "Wow", "Party", "Facepalm", "Good morning"];
const SUGGESTIONS = ["party time", "party hard", "happy birthday", "thank you so much", "lol funny", "wow amazing", "good morning coffee", "no way"];
const COLUMN_COUNT = 3;
const COPIED_LINGER_MS = 900;
const ENTRANCE_MS = 1200;

const ICONS = {
  // Phosphor icons (phosphoricons.com, MIT).
  star: '<svg viewBox="0 0 256 256" fill="currentColor" aria-hidden="true"><path d="M234.29,114.85l-45,38.83L203,211.75a16.4,16.4,0,0,1-24.5,17.82L128,198.49,77.47,229.57A16.4,16.4,0,0,1,53,211.75l13.76-58.07-45-38.83A16.46,16.46,0,0,1,31.08,86l59-4.76,22.76-55.08a16.36,16.36,0,0,1,30.27,0l22.75,55.08,59,4.76a16.46,16.46,0,0,1,9.37,28.86Z"/></svg>',
  clock: '<svg viewBox="0 0 256 256" fill="currentColor" aria-hidden="true"><path d="M128,24A104,104,0,1,0,232,128,104.11,104.11,0,0,0,128,24Zm56,112H128a8,8,0,0,1-8-8V72a8,8,0,0,1,16,0v48h48a8,8,0,0,1,0,16Z"/></svg>',
  flame: '<svg viewBox="0 0 256 256" fill="currentColor" aria-hidden="true"><path d="M143.38,17.85a8,8,0,0,0-12.63,3.41l-22,60.41L84.59,58.26a8,8,0,0,0-11.93.89C51,87.53,40,116.08,40,144a88,88,0,0,0,176,0C216,84.55,165.21,36,143.38,17.85Zm40.51,135.49a57.6,57.6,0,0,1-46.56,46.55A7.65,7.65,0,0,1,136,200a8,8,0,0,1-1.32-15.89c16.57-2.79,30.63-16.85,33.44-33.45a8,8,0,0,1,15.78,2.68Z"/></svg>',
  check: '<svg viewBox="0 0 256 256" fill="currentColor" aria-hidden="true"><path d="M128,24A104,104,0,1,0,232,128,104.11,104.11,0,0,0,128,24Zm45.66,85.66-56,56a8,8,0,0,1-11.32,0l-24-24a8,8,0,0,1,11.32-11.32L112,148.69l50.34-50.35a8,8,0,0,1,11.32,11.32Z"/></svg>',
};

const state = {
  query: "",
  mode: "trending", // trending | favorites | recents | search
  selected: 0,
  navigated: false,
  favorites: new Set(),
  recents: [],
  copiedID: null,
  shownKey: "",
};

const $ = (selector) => document.querySelector(selector);
const popover = $("#demo");
const toggle = $("#menubar-toggle");
const input = $("#demo-search");
const clear = $("#demo-clear");
const chips = $("#demo-chips");
const grid = $("#demo-grid");
const empty = $("#demo-empty");
const status = $("#demo-status");
const keys = document.querySelector(".keys");

function results() {
  if (state.query) {
    const words = state.query.toLowerCase().split(/\s+/).filter(Boolean);
    return LIBRARY.filter((gif) => words.every((word) => gif.tags.includes(word)));
  }
  if (state.mode === "favorites") return LIBRARY.filter((gif) => state.favorites.has(gif.id));
  if (state.mode === "recents") return state.recents.map((id) => LIBRARY[Number(id)]);
  return LIBRARY.filter((gif) => gif.tags.includes("trending"));
}

function chip(label, { icon, pressed, onClick }) {
  const button = document.createElement("button");
  button.type = "button";
  button.className = "chip";
  button.setAttribute("aria-pressed", String(Boolean(pressed)));
  button.innerHTML = `${icon ? ICONS[icon] : ""}<span>${label}</span>`;
  button.addEventListener("click", onClick);
  return button;
}

function renderChips() {
  chips.replaceChildren();
  const browse = (mode) => () => { state.query = ""; input.value = ""; state.mode = mode; render(); };
  chips.append(
    chip("Favorites", { icon: "star", pressed: !state.query && state.mode === "favorites", onClick: browse("favorites") }),
    chip("Recent", { icon: "clock", pressed: !state.query && state.mode === "recents", onClick: browse("recents") }),
    chip("Trending", { icon: "flame", pressed: !state.query && state.mode === "trending", onClick: browse("trending") }),
  );
  const typed = state.query.toLowerCase();
  const suggestions = typed.length >= 2 ? SUGGESTIONS.filter((term) => term.startsWith(typed) && term !== typed) : [];
  for (const term of suggestions.length ? suggestions : QUICK_PICKS) {
    chips.append(chip(term, {
      pressed: state.query.toLowerCase() === term.toLowerCase(),
      onClick: () => search(term),
    }));
  }
}

/** Builds the tiles. Only runs when the set of results changes, so copying or starring never re-renders the grid. */
function buildGrid(gifs) {
  const columns = Array.from({ length: COLUMN_COUNT }, () => ({ el: document.createElement("div"), height: 0 }));
  columns.forEach(({ el }) => { el.className = "grid__col"; el.setAttribute("role", "presentation"); });

  gifs.forEach((gif, index) => {
    const tile = document.createElement("button");
    tile.type = "button";
    tile.className = "tile";
    tile.dataset.id = gif.id;
    tile.dataset.index = String(index);
    tile.setAttribute("role", "listitem");
    tile.style.cssText = `--a:${gif.a};--i:${index};--speed:${1.2 + (index % 5) * 0.25}s;height:${gif.h}px`;
    tile.innerHTML = `<span class="tile__emoji" aria-hidden="true">${gif.emoji}</span>
      <span class="tile__star" aria-hidden="true">${ICONS.star}</span>`;
    tile.addEventListener("click", (event) => {
      if (event.target.closest(".tile__star")) toggleFavorite(gif);
      else copy(gif);
    });
    const shortest = columns.reduce((low, column) => (column.height < low.height ? column : low));
    shortest.el.append(tile);
    shortest.height += gif.h;
  });

  grid.replaceChildren(...columns.map(({ el }) => el));
  grid.classList.add("is-entering");
  clearTimeout(buildGrid.timer);
  buildGrid.timer = setTimeout(() => grid.classList.remove("is-entering"), ENTRANCE_MS);
}

/** Updates selection, favorites and the Copied badge in place. */
function updateTiles(gifs) {
  grid.querySelectorAll(".tile").forEach((tile) => {
    const gif = LIBRARY[Number(tile.dataset.id)];
    const favorite = state.favorites.has(gif.id);
    const selected = Number(tile.dataset.index) === state.selected && Boolean(state.query || state.navigated);
    const copied = state.copiedID === gif.id;
    tile.classList.toggle("is-favorite", favorite);
    tile.classList.toggle("is-selected", selected);
    tile.classList.toggle("is-copied", copied);
    tile.setAttribute("aria-label", `${gif.tags.split(" ")[0]} reaction${favorite ? ", favorite" : ""}. Copies ${gif.emoji}`);
    const badge = tile.querySelector(".tile__copied");
    if (copied && !badge) tile.insertAdjacentHTML("beforeend", `<span class="tile__copied">${ICONS.check}Copied</span>`);
    if (!copied && badge) badge.remove();
  });

  empty.hidden = gifs.length > 0;
  if (!gifs.length) {
    empty.innerHTML = state.query
      ? `<b>No results for “${escapeHTML(state.query)}”</b>Try “party”, “lol” or “thank you”.`
      : state.mode === "favorites"
        ? "<b>No favorites yet</b>Point at a GIF and click its star, or select it and press ⌘D."
        : "<b>No recent GIFs</b>GIFs you copy show up here.";
  }
}

function render() {
  clear.hidden = !state.query;
  renderChips();
  const gifs = results();
  state.selected = Math.min(state.selected, Math.max(gifs.length - 1, 0));
  const key = gifs.map((gif) => gif.id).join(",");
  if (key !== state.shownKey) {
    state.shownKey = key;
    buildGrid(gifs);
  }
  updateTiles(gifs);
}

function search(term) {
  state.query = term;
  input.value = term;
  state.mode = "search";
  state.selected = 0;
  render();
}

function escapeHTML(text) {
  return text.replace(/[&<>"']/g, (char) => `&#${char.charCodeAt(0)};`);
}

async function copy(gif) {
  try {
    await navigator.clipboard.writeText(gif.emoji);
  } catch {
    // Clipboard access can be refused (for example in an embedded view); the demo still shows the result.
  }
  state.recents = [gif.id, ...state.recents.filter((id) => id !== gif.id)];
  state.copiedID = gif.id;
  status.textContent = `Copied ${gif.emoji}`;
  // In Recent, the list order changes; everywhere else only this tile's badge does.
  render();
  setTimeout(() => {
    if (state.copiedID !== gif.id) return;
    state.copiedID = null;
    updateTiles(results());
  }, COPIED_LINGER_MS);
}

function toggleFavorite(gif) {
  if (state.favorites.has(gif.id)) state.favorites.delete(gif.id);
  else state.favorites.add(gif.id);
  status.textContent = state.favorites.has(gif.id) ? "Added to Favorites" : "Removed from Favorites";
  render();
}

function moveSelection(offset) {
  const count = results().length;
  if (!count) return;
  state.navigated = true;
  state.selected = Math.min(Math.max(state.selected + offset, 0), count - 1);
  updateTiles(results());
  grid.querySelector(".tile.is-selected")?.scrollIntoView({ block: "nearest" });
}

function setOpen(open) {
  popover.classList.toggle("is-closed", !open);
  toggle.setAttribute("aria-expanded", String(open));
  if (open) input.focus({ preventScroll: true });
}

function pressKeys() {
  if (!keys) return;
  keys.classList.add("is-pressed");
  setTimeout(() => keys.classList.remove("is-pressed"), 160);
}

input.addEventListener("input", () => {
  state.query = input.value.trim();
  state.mode = state.query ? "search" : "trending";
  state.selected = 0;
  render();
});

input.addEventListener("keydown", (event) => {
  const selected = results()[state.selected];
  if (event.key === "ArrowDown") { event.preventDefault(); moveSelection(1); }
  else if (event.key === "ArrowUp") { event.preventDefault(); moveSelection(-1); }
  else if (event.key === "Enter" && selected) { event.preventDefault(); copy(selected); }
  else if (event.key.toLowerCase() === "d" && event.metaKey && selected) { event.preventDefault(); toggleFavorite(selected); }
});

clear.addEventListener("click", () => {
  input.value = "";
  state.query = "";
  state.mode = "trending";
  render();
  input.focus();
});

toggle.addEventListener("click", () => setOpen(popover.classList.contains("is-closed")));

document.addEventListener("keydown", (event) => {
  // event.code, because Option changes the character a key produces on a Mac.
  if (event.code === "KeyV" && event.metaKey && event.altKey) {
    event.preventDefault();
    pressKeys();
    setOpen(popover.classList.contains("is-closed"));
  } else if (event.key === "Escape" && !popover.classList.contains("is-closed") && popover.contains(document.activeElement)) {
    setOpen(false);
    toggle.focus();
  }
});

document.querySelectorAll("[data-copy]").forEach((button) => {
  const label = button.querySelector(".command__action") ?? button;
  const original = label.textContent;
  button.addEventListener("click", async () => {
    try {
      await navigator.clipboard.writeText(button.dataset.copy);
      label.textContent = "Copied";
    } catch {
      label.textContent = "Press ⌘C";
      window.getSelection()?.selectAllChildren(button.querySelector("code") ?? button);
    }
    setTimeout(() => { label.textContent = original; }, 1600);
  });
});

// ——— Desktop GIF windows you can drag around ———

document.querySelectorAll(".sticker").forEach((sticker) => {
  let start = null;
  sticker.addEventListener("pointerdown", (event) => {
    const dx = parseFloat(sticker.style.getPropertyValue("--dx")) || 0;
    const dy = parseFloat(sticker.style.getPropertyValue("--dy")) || 0;
    start = { x: event.clientX - dx, y: event.clientY - dy };
    sticker.setPointerCapture(event.pointerId);
    sticker.classList.add("is-dragging");
  });
  sticker.addEventListener("pointermove", (event) => {
    if (!start) return;
    sticker.style.setProperty("--dx", `${event.clientX - start.x}px`);
    sticker.style.setProperty("--dy", `${event.clientY - start.y}px`);
  });
  const drop = () => { start = null; sticker.classList.remove("is-dragging"); };
  sticker.addEventListener("pointerup", drop);
  sticker.addEventListener("pointercancel", drop);
});

// ——— The Dock: rises at the bottom edge and magnifies the icons near the pointer ———

const dock = $("#dock");
const dockItems = [...dock.querySelectorAll(".dock__item")];
const DOCK_BASE = 54;
const DOCK_MAX = 96;
const DOCK_REACH = 150;
const DOCK_TRIGGER = 64;
const DOCK_HIDE_DELAY_MS = 500;
const reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)");
let hideTimer;

function showDock(visible) {
  clearTimeout(hideTimer);
  if (visible) dock.classList.add("is-visible");
  else hideTimer = setTimeout(() => dock.classList.remove("is-visible"), DOCK_HIDE_DELAY_MS);
}

document.addEventListener("pointermove", (event) => {
  if (event.pointerType !== "mouse") return;
  const nearBottom = window.innerHeight - event.clientY < DOCK_TRIGGER;
  showDock(nearBottom || dock.matches(":hover"));
});
document.addEventListener("pointerleave", () => showDock(false));

// Each icon's size follows a spring toward its target, integrated every frame, so the swell stays smooth
// however fast the pointer moves. Distances are measured from where each icon sits at rest; measuring the
// live, already-magnified layout feeds back into itself and wobbles.
const SPRING = { stiffness: 1500, damping: 120 }; // per unit mass: quick and slightly overdamped, like the Dock
const REST_EPSILON = 0.05;
const springs = dockItems.map(() => ({ size: DOCK_BASE, velocity: 0, target: DOCK_BASE }));
let restOffsets = [];
let frame = 0;
let lastTime = 0;

function measureRest() {
  const dockBox = dock.getBoundingClientRect();
  const dockCenter = dockBox.left + dockBox.width / 2;
  restOffsets = dockItems.map((item) => {
    const box = item.getBoundingClientRect();
    return box.left + box.width / 2 - dockCenter;
  });
}

function magnification(distance) {
  const pull = Math.max(0, 1 - distance / DOCK_REACH);
  // A cosine falloff gives the Dock's rounded swell rather than a linear peak.
  return DOCK_BASE + (DOCK_MAX - DOCK_BASE) * (0.5 - Math.cos(pull * Math.PI) / 2);
}

function step(time) {
  const elapsed = Math.min((time - (lastTime || time)) / 1000, 1 / 30);
  lastTime = time;
  let moving = false;
  springs.forEach((spring, index) => {
    // Two half-steps per frame keep the stiff spring stable on slow frames.
    for (let substep = 0; substep < 2; substep++) {
      const dt = elapsed / 2;
      const acceleration = SPRING.stiffness * (spring.target - spring.size) - SPRING.damping * spring.velocity;
      spring.velocity += acceleration * dt;
      spring.size += spring.velocity * dt;
    }
    if (Math.abs(spring.target - spring.size) > REST_EPSILON || Math.abs(spring.velocity) > REST_EPSILON) moving = true;
    else { spring.size = spring.target; spring.velocity = 0; }
    dockItems[index].style.width = dockItems[index].style.height = `${spring.size}px`;
  });
  frame = moving ? requestAnimationFrame(step) : 0;
  if (!moving) lastTime = 0;
}

function animateDock() {
  if (!frame) frame = requestAnimationFrame(step);
}

dock.addEventListener("pointerenter", () => {
  if (springs.every((spring) => spring.size === DOCK_BASE)) measureRest();
});
dock.addEventListener("pointermove", (event) => {
  if (reduceMotion.matches || !restOffsets.length) return;
  const dockBox = dock.getBoundingClientRect();
  const pointer = event.clientX - (dockBox.left + dockBox.width / 2);
  springs.forEach((spring, index) => { spring.target = magnification(Math.abs(pointer - restOffsets[index])); });
  animateDock();
});
dock.addEventListener("pointerleave", () => {
  springs.forEach((spring) => { spring.target = DOCK_BASE; });
  animateDock();
  showDock(false);
});

// ——— Video: a glass play button, then the native controls ———

const video = $("#launch-video");
const play = $("#launch-play");
play.addEventListener("click", () => {
  video.controls = true;
  play.hidden = true;
  video.play();
});

// ——— The menu bar clock, like the real one ———

const clock = $("#clock");
function tick() {
  const now = new Date();
  clock.dateTime = now.toISOString();
  clock.textContent = now.toLocaleString(undefined, { weekday: "short", day: "numeric", month: "short", hour: "2-digit", minute: "2-digit" });
}
tick();
setInterval(tick, 15000);

// The popover's arrow points at the menu bar icon, wherever the layout puts the popover.
function aimArrow() {
  const icon = toggle.getBoundingClientRect();
  const box = popover.getBoundingClientRect();
  popover.style.setProperty("--arrow-right", `${Math.max(box.right - (icon.left + icon.width / 2) - 11, 16)}px`);
}
window.addEventListener("resize", aimArrow);
// The clock and the appearance icon change the menu bar's width, which moves the icon the arrow points at.
new ResizeObserver(aimArrow).observe(document.querySelector(".menubar__extras"));

render();
aimArrow();

// ——— The story: which step is showing ———
// Four markers sit at 0, 25, 50 and 75% of the story's scroll range; the step is how many have passed the
// middle of the screen. IntersectionObserver only wakes up when one crosses, so nothing runs per scroll frame.
// motion.js plays the scene with GSAP; without it (or with Reduce Motion) CSS plays each step's scene.

const story = $("#how");
const query = story.querySelector(".scene-query");
const markers = [...story.querySelectorAll(".story__marker")];
const TYPE_INTERVAL_MS = 90;
let storyStep = -1;
let typing = 0;

function typeQuery(text) {
  clearInterval(typing);
  if (reduceMotion.matches) { query.textContent = text; return; }
  query.textContent = "";
  let index = 0;
  typing = setInterval(() => {
    query.textContent = text.slice(0, ++index);
    if (index >= text.length) clearInterval(typing);
  }, TYPE_INTERVAL_MS);
}

function updateStory() {
  const middle = window.innerHeight / 2;
  const next = markers.filter((marker) => marker.getBoundingClientRect().top < middle).length - 1;
  if (next === storyStep) return;
  // With GSAP driving the scene, it types the query itself.
  if (!story.classList.contains("is-scrubbed")) {
    if (next >= 1 && storyStep < 1) typeQuery(query.dataset.text);
    if (next < 1) { clearInterval(typing); query.textContent = ""; }
  }
  storyStep = next;
  story.dataset.step = String(next);
}

// The top half of the screen: a marker enters it exactly when it crosses the middle.
const storyObserver = new IntersectionObserver(updateStory, { rootMargin: "0px 0px -50% 0px" });
markers.forEach((marker) => storyObserver.observe(marker));
