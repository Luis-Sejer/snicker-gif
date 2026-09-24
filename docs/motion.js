// Page choreography with GSAP. Every animation has a job:
// - the intro tells the shortcut story: keys press, the popover springs open, GIF windows land on the desktop
// - the story section scrubs the whole flow, from shortcut to paste, as you scroll
// - headlines reveal line by line to set hierarchy as each section arrives
// - the right-click menu, clipboard diagram and video each play their one moment on arrival
// All of it lives inside gsap.matchMedia, so Reduce Motion reverts to the static page (and site.js's CSS states).

(() => {
  const root = document.documentElement;
  if (!window.gsap || !window.ScrollTrigger || !window.SplitText) {
    root.classList.remove("intro");
    return;
  }
  gsap.registerPlugin(ScrollTrigger, SplitText, ScrambleTextPlugin);

  const EASE_OUT = "expo.out";
  const $ = (selector, scope = document) => scope.querySelector(selector);
  const $$ = (selector, scope = document) => [...scope.querySelectorAll(selector)];

  /** Layout position of an element inside an ancestor, ignoring transforms (which GSAP is animating). */
  function offsetIn(element, ancestor) {
    let x = 0;
    let y = 0;
    for (let node = element; node && node !== ancestor; node = node.offsetParent) {
      x += node.offsetLeft;
      y += node.offsetTop;
    }
    return { x, y, width: element.offsetWidth, height: element.offsetHeight };
  }

  function intro() {
    const popover = $("#demo");
    const wordmark = SplitText.create(".wordmark", { type: "chars", mask: "chars" });
    // The popover's CSS transitions serve the ⌘⌥V toggle; they would fight the intro tween.
    gsap.set(popover, { transition: "none" });

    const timeline = gsap.timeline({
      defaults: { ease: EASE_OUT },
      onStart: () => root.classList.remove("intro"),
      onComplete: () => {
        gsap.set(popover, { clearProps: "transition,transform,opacity,visibility" });
        gsap.set(".sticker", { clearProps: "transform,opacity,visibility" });
      },
    });
    timeline
      .from(".desktop__icon", { y: 24, scale: 0.8, autoAlpha: 0, duration: 1 })
      .from(wordmark.chars, { yPercent: 110, duration: 1, stagger: 0.045 }, "<0.1")
      .from([".promise", ".shortcut", ".actions", ".fineprint"], { y: 18, autoAlpha: 0, duration: 0.9, stagger: 0.08 }, "<0.3")
      // The shortcut, pressed key by key, is what opens the popover.
      .to(".keys kbd", { y: 3, duration: 0.07, stagger: 0.11, yoyo: true, repeat: 1, ease: "power1.inOut" }, "-=0.35")
      .from(popover, { scale: 0.94, y: -10, autoAlpha: 0, duration: 0.5, ease: "back.out(1.2)", transformOrigin: "88% 0%" }, ">-0.05")
      .from(".demo-note", { autoAlpha: 0, duration: 0.6 }, "<0.3")
      .from(".sticker", {
        y: -90,
        rotation: () => gsap.utils.random(-28, 28),
        autoAlpha: 0,
        duration: 1.1,
        ease: "back.out(1.7)",
        stagger: 0.1,
      }, "<-0.2");
    return timeline;
  }

  function story() {
    const section = $("#how");
    const scene = $(".story__scene", section);
    const popover = $(".scene-pop", scene);
    const trending = $$(".scene-grid--trending .scene-tile", scene);
    const party = $$(".scene-grid--party .scene-tile", scene);
    const target = $(".scene-tile--target", scene);
    const copied = $(".scene-copied", scene);
    const gif = $(".scene-gif", scene);
    const query = $(".scene-query", scene);
    const cursor = document.createElementNS("http://www.w3.org/2000/svg", "svg");
    cursor.setAttribute("class", "scene-cursor");
    cursor.setAttribute("viewBox", "0 0 26 34");
    cursor.innerHTML = '<path d="M3 2 L3 26 L9 20.5 L13 30 L17 28.3 L13.2 19 L21.5 19 Z" fill="#000" stroke="#fff" stroke-width="2" stroke-linejoin="round"/>';
    scene.append(cursor);
    section.classList.add("is-scrubbed");
    query.textContent = "";

    const targetCenter = () => {
      const box = offsetIn(target, scene);
      return { x: box.x + box.width * 0.55, y: box.y + box.height * 0.6 };
    };
    // The chat GIF starts as if it were the copied tile, then flies into the chat.
    const flight = () => {
      const from = offsetIn(target, scene);
      const to = offsetIn(gif, scene);
      return {
        x: from.x + from.width / 2 - (to.x + to.width / 2),
        y: from.y + from.height / 2 - (to.y + to.height / 2),
        scale: from.width / to.width,
      };
    };

    gsap.set(popover, { autoAlpha: 0, scale: 0.92, y: -10, transformOrigin: "80% 0%" });
    gsap.set(party, { autoAlpha: 0, scale: 0.8 });
    gsap.set(copied, { autoAlpha: 0, scale: 0.6 });
    gsap.set(gif, { autoAlpha: 0 });

    // Four equal beats that line up with the four step captions (which site.js highlights).
    const timeline = gsap.timeline({
      defaults: { ease: "power2.out" },
      scrollTrigger: { trigger: section, start: "top top", end: "bottom bottom", scrub: 0.6, invalidateOnRefresh: true },
    });
    timeline
      // 1. The shortcut opens the popover.
      .to(popover, { autoAlpha: 1, scale: 1, y: 0, duration: 0.6, ease: "back.out(1.1)" }, 0)
      // 2. "party" is typed and the grid reshuffles.
      .to(query, { duration: 0.7, scrambleText: { text: query.dataset.text, chars: "lowerCase", speed: 0.5 } }, 1)
      .to(trending, { autoAlpha: 0, scale: 0.8, duration: 0.35, stagger: 0.04 }, 1.2)
      .to(party, { autoAlpha: 1, scale: 1, duration: 0.45, stagger: 0.05, ease: "back.out(1.6)" }, 1.4)
      // 3. The pointer clicks a GIF and it's copied.
      .fromTo(cursor,
        { autoAlpha: 0, x: () => scene.offsetWidth * 0.95, y: () => scene.offsetHeight * 0.9 },
        { autoAlpha: 1, x: () => targetCenter().x, y: () => targetCenter().y, duration: 0.55, ease: "power3.inOut" }, 2)
      .to(target, { scale: 0.94, duration: 0.1, ease: "power2.out" }, 2.55)
      .to(target, { scale: 1.06, duration: 0.25, ease: "back.out(3)" }, 2.63)
      .to(copied, { autoAlpha: 1, scale: 1, duration: 0.25, ease: "back.out(2)" }, 2.63)
      // 4. The popover closes and the GIF lands in the chat.
      .to([popover, cursor], { autoAlpha: 0, scale: 0.95, duration: 0.35 }, 3)
      .fromTo(gif,
        { autoAlpha: 1, x: () => flight().x, y: () => flight().y, scale: () => flight().scale },
        { x: 0, y: 0, scale: 1, duration: 0.8, ease: "power3.inOut" }, 3.1)
      .to({}, { duration: 0.1 }, 3.9);
  }

  function headlineReveals() {
    $$("h2:not(.visually-hidden)").forEach((heading) => {
      SplitText.create(heading, {
        type: "lines",
        mask: "lines",
        autoSplit: true,
        onSplit: (split) => gsap.from(split.lines, {
          yPercent: 105,
          duration: 1.1,
          ease: EASE_OUT,
          stagger: 0.08,
          scrollTrigger: { trigger: heading, start: "top 85%", once: true },
        }),
      });
    });
    ScrollTrigger.batch(".lead, .facts li, .faq details, .install__note", {
      start: "top 88%",
      once: true,
      onEnter: (elements) => gsap.from(elements, { y: 18, autoAlpha: 0, duration: 0.8, ease: EASE_OUT, stagger: 0.06 }),
    });
  }

  function rightClick() {
    gsap.timeline({ scrollTrigger: { trigger: ".right-click", start: "top 75%", once: true } })
      .from(".right-click__tile", { y: 30, autoAlpha: 0, duration: 0.8, ease: EASE_OUT })
      .from(".right-click .cursor", { x: -70, y: 50, autoAlpha: 0, duration: 0.7, ease: "power3.inOut" }, "<0.2")
      // The menu opens from the point that was clicked.
      .from(".right-click .context-menu", { scale: 0.97, autoAlpha: 0, transformOrigin: "0% 0%", duration: 0.18, ease: "power3.out" }, ">-0.05")
      .from(".right-click .context-menu__item", { autoAlpha: 0, duration: 0.15, stagger: 0.03 }, "<0.05");
  }

  function anatomy() {
    const stage = $(".anatomy__stage");
    const timeline = gsap.timeline({ scrollTrigger: { trigger: stage, start: "top 75%", end: "center 45%", scrub: 0.8 } });
    timeline
      .from(".anatomy__source", { scale: 0.9, autoAlpha: 0, duration: 0.3 })
      // The copies travel along the lines: fork first, then each row.
      .fromTo(".connector--fork", { clipPath: "inset(0 100% 0 0)" }, { clipPath: "inset(0 0% 0 0)", duration: 0.3, ease: "none" })
      .from(".layer--file", { x: -40, autoAlpha: 0, duration: 0.3 }, "<0.15")
      .from(".layer--data", { x: -40, autoAlpha: 0, duration: 0.3 }, "<0.05")
      .fromTo(".connector--one, .connector--two", { clipPath: "inset(0 100% 0 0)" }, { clipPath: "inset(0 0% 0 0)", duration: 0.25, ease: "none" })
      .from(".chat--one", { x: -40, autoAlpha: 0, duration: 0.3 }, "<0.1")
      .from(".chat--two", { x: -40, autoAlpha: 0, duration: 0.3 }, "<0.05");
  }

  function video() {
    // The player grows to full size as it arrives, focusing the section on the film.
    gsap.fromTo(".watch .player",
      { scale: 0.84, borderRadius: 40 },
      { scale: 1, borderRadius: 20, ease: "none", scrollTrigger: { trigger: ".watch .player", start: "top bottom", end: "center 55%", scrub: true } });
  }

  function marquee() {
    const strip = $(".marquee");
    const track = $(".marquee__track", strip);
    strip.classList.add("is-driven");
    const loop = gsap.to(track, { xPercent: -50, duration: 40, ease: "none", repeat: -1 });
    // Start deep into the loop so reversing (scrolling up) never runs out of repeats.
    loop.totalTime(loop.duration() * 100);
    ScrollTrigger.create({
      trigger: strip,
      start: "top bottom",
      end: "bottom top",
      onUpdate: (self) => {
        // The strip speeds up with the scroll and runs the way you scroll, then settles.
        const boost = gsap.utils.clamp(1, 6, Math.abs(self.getVelocity()) / 250);
        gsap.to(loop, {
          timeScale: self.direction * boost,
          duration: 0.2,
          overwrite: true,
          onComplete: () => gsap.to(loop, { timeScale: self.direction, duration: 1.2, ease: "power2.out" }),
        });
      },
    });
    return () => strip.classList.remove("is-driven");
  }

  // Play the intro only on a fresh view of the top of the page: not after the fallback already showed it,
  // and not when a reload restored a scrolled position.
  const shouldPlayIntro = () => root.classList.contains("intro") && window.scrollY < 40;

  const media = gsap.matchMedia();
  media.add("(prefers-reduced-motion: no-preference)", () => {
    if (shouldPlayIntro()) intro();
    else root.classList.remove("intro", "intro-skipped");
    story();
    headlineReveals();
    rightClick();
    anatomy();
    video();
    const undoMarquee = marquee();
    return () => {
      undoMarquee();
      $("#how").classList.remove("is-scrubbed");
    };
  });
  media.add("(prefers-reduced-motion: reduce)", () => root.classList.remove("intro"));
})();
