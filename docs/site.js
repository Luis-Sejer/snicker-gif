// The live popover demo: search, chips, favorites, keyboard, and ⌘⌥V to toggle.
// Tiles are emoji-on-gradient illustrations; clicking one copies the emoji.

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

const ICONS = {
  star: '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12 2.5l2.9 6.1 6.6.8-4.9 4.6 1.3 6.6L12 17.3l-5.9 3.3 1.3-6.6-4.9-4.6 6.6-.8z"/></svg>',
  clock: '<svg viewBox="0 0 16 16" aria-hidden="true"><path d="M8 1a7 7 0 1 0 0 14A7 7 0 0 0 8 1Zm.75 3.5v3.19l2.28 2.28-1.06 1.06L7.25 8.3V4.5h1.5Z"/></svg>',
  flame: '<svg viewBox="0 0 16 16" aria-hidden="true"><path d="M8.6 1c.4 2.2-.7 3.3-1.6 4.4C6 6.6 5 7.8 5 9.7 5 12.1 6.4 15 9 15c2.3 0 4-1.9 4-4.6 0-2.3-1.2-3.4-2.1-4.6.1 1.2-.3 2.1-1.1 2.6C10.2 5.8 10 3 8.6 1Z"/></svg>',
  check: '<svg viewBox="0 0 16 16" aria-hidden="true"><circle cx="8" cy="8" r="7.5" fill="#fff"/><path d="M4.6 8.2l2.2 2.2 4.6-4.8" fill="none" stroke="#b86a00" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/></svg>',
};

const state = {
  query: "",
  mode: "trending", // trending | favorites | recents | search
  selected: 0,
  favorites: new Set(),
  recents: [],
  copiedID: null,
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

function renderGrid() {
  const gifs = results();
  state.selected = Math.min(state.selected, Math.max(gifs.length - 1, 0));
  const columns = Array.from({ length: COLUMN_COUNT }, () => ({ el: document.createElement("div"), height: 0 }));
  columns.forEach(({ el }) => { el.className = "grid__col"; el.setAttribute("role", "presentation"); });

  gifs.forEach((gif, index) => {
    const tile = document.createElement("button");
    tile.type = "button";
    tile.className = "tile";
    tile.setAttribute("role", "listitem");
    tile.style.cssText = `--a:${gif.a};--b:${gif.b};--i:${index};--speed:${1.2 + (index % 5) * 0.25}s;height:${gif.h}px`;
    tile.classList.toggle("is-favorite", state.favorites.has(gif.id));
    tile.classList.toggle("is-selected", Boolean(index === state.selected && (state.query || state.navigated)));
    tile.classList.toggle("is-copied", state.copiedID === gif.id);
    const favorite = state.favorites.has(gif.id);
    tile.setAttribute("aria-label", `${gif.tags.split(" ")[0]} reaction${favorite ? ", favorite" : ""}. Copies ${gif.emoji}`);
    tile.innerHTML = `<span class="tile__emoji" aria-hidden="true">${gif.emoji}</span>
      <span class="tile__star" role="button" tabindex="-1" aria-label="${favorite ? "Remove from" : "Add to"} Favorites">${ICONS.star}</span>
      ${state.copiedID === gif.id ? `<span class="tile__copied">${ICONS.check}Copied</span>` : ""}`;
    tile.addEventListener("click", (event) => {
      if (event.target.closest(".tile__star")) toggleFavorite(gif);
      else copy(gif);
    });
    const shortest = columns.reduce((low, column) => (column.height < low.height ? column : low));
    shortest.el.append(tile);
    shortest.height += gif.h;
  });

  grid.replaceChildren(...columns.map(({ el }) => el));
  grid.style.gridTemplateColumns = `repeat(${COLUMN_COUNT}, 1fr)`;
  grid.style.display = "grid";

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
  renderGrid();
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
  render();
  setTimeout(() => {
    if (state.copiedID !== gif.id) return;
    state.copiedID = null;
    render();
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
  render();
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

// The video starts from a glass play button, then hands over to the native controls.
const video = $("#launch-video");
const play = $("#launch-play");
play.addEventListener("click", () => {
  video.controls = true;
  play.hidden = true;
  video.play();
});

// The menu bar clock, like the real one.
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

render();
aimArrow();
