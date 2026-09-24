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

  // Starting states are set explicitly with gsap.set() and animated with .to(). A from() inside a timeline gets
  // its starting state reverted on the first tick, which showed content on a fast (cached) load and then
  // blinked it away as each step began.
  function intro() {
    const popover = $("#demo");
    const wordmark = SplitText.create(".wordmark", { type: "chars", mask: "chars" });
    const copyLines = [".promise", ".shortcut", ".actions", ".fineprint"];
    // The popover's CSS transitions serve the ⌘⌥V toggle; they would fight the intro tween.
    gsap.set(popover, { transition: "none", autoAlpha: 0, scale: 0.94, y: -10, transformOrigin: "88% 0%" });
    gsap.set(".desktop__icon", { autoAlpha: 0, y: 24, scale: 0.8 });
    gsap.set(wordmark.chars, { yPercent: 110 });
    gsap.set(copyLines, { autoAlpha: 0, y: 18 });
    gsap.set(".demo-note", { autoAlpha: 0 });
    gsap.set(".sticker", { autoAlpha: 0, y: -90, rotation: () => gsap.utils.random(-28, 28) });
    root.classList.remove("intro");

    const timeline = gsap.timeline({
      defaults: { ease: EASE_OUT },
      onComplete: () => {
        gsap.set(popover, { clearProps: "transition,transform,opacity,visibility" });
        gsap.set(".sticker", { clearProps: "transform,opacity,visibility" });
      },
    });
    timeline
      .to(".desktop__icon", { autoAlpha: 1, y: 0, scale: 1, duration: 1 })
      .to(wordmark.chars, { yPercent: 0, duration: 1, stagger: 0.045 }, "<0.1")
      .to(copyLines, { autoAlpha: 1, y: 0, duration: 0.9, stagger: 0.08 }, "<0.3")
      // The shortcut, pressed key by key, is what opens the popover.
      .to(".keys kbd", { y: 3, duration: 0.07, stagger: 0.11, yoyo: true, repeat: 1, ease: "power1.inOut" }, "-=0.35")
      .to(popover, { autoAlpha: 1, scale: 1, y: 0, duration: 0.5, ease: "back.out(1.2)" }, ">-0.05")
      .to(".demo-note", { autoAlpha: 1, duration: 0.6 }, "<0.3")
      .to(".sticker", { autoAlpha: 1, y: 0, rotation: 0, duration: 1.1, ease: "back.out(1.7)", stagger: 0.1 }, "<-0.2");
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
        onSplit: (split) => gsap.fromTo(split.lines, { yPercent: 105 }, {
          yPercent: 0,
          duration: 1.1,
          ease: EASE_OUT,
          stagger: 0.08,
          scrollTrigger: { trigger: heading, start: "top 85%", once: true },
        }),
      });
    });
    const fadeIns = ".lead, .facts li, .faq details, .install__note";
    gsap.set(fadeIns, { autoAlpha: 0, y: 18 });
    ScrollTrigger.batch(fadeIns, {
      start: "top 88%",
      once: true,
      onEnter: (elements) => gsap.to(elements, { autoAlpha: 1, y: 0, duration: 0.8, ease: EASE_OUT, stagger: 0.06 }),
    });
  }

  function rightClick() {
    gsap.set(".right-click__tile", { autoAlpha: 0, y: 30 });
    gsap.set(".right-click .cursor", { autoAlpha: 0, x: -70, y: 50 });
    gsap.set(".right-click .context-menu", { autoAlpha: 0, scale: 0.97, transformOrigin: "0% 0%" });
    gsap.set(".right-click .context-menu__item", { autoAlpha: 0 });
    gsap.timeline({ scrollTrigger: { trigger: ".right-click", start: "top 75%", once: true } })
      .to(".right-click__tile", { autoAlpha: 1, y: 0, duration: 0.8, ease: EASE_OUT })
      .to(".right-click .cursor", { autoAlpha: 1, x: 0, y: 0, duration: 0.7, ease: "power3.inOut" }, "<0.2")
      // The menu opens from the point that was clicked, almost instantly, as on a Mac.
      .to(".right-click .context-menu", { autoAlpha: 1, scale: 1, duration: 0.18, ease: "power3.out" }, ">-0.05")
      .to(".right-click .context-menu__item", { autoAlpha: 1, duration: 0.15, stagger: 0.03 }, "<0.05");
  }

  function anatomy() {
    const stage = $(".anatomy__stage");
    const hiddenLine = { clipPath: "inset(0 100% 0 0)" };
    gsap.set(".anatomy__source", { autoAlpha: 0, scale: 0.9 });
    gsap.set(".connector--fork, .connector--one, .connector--two", hiddenLine);
    gsap.set(".layer--file, .layer--data, .chat--one, .chat--two", { autoAlpha: 0, x: -40 });
    const timeline = gsap.timeline({ scrollTrigger: { trigger: stage, start: "top 75%", end: "center 45%", scrub: 0.8 } });
    timeline
      .to(".anatomy__source", { autoAlpha: 1, scale: 1, duration: 0.3 })
      // The copies travel along the lines: fork first, then each row.
      .to(".connector--fork", { clipPath: "inset(0 0% 0 0)", duration: 0.3, ease: "none" })
      .to(".layer--file", { autoAlpha: 1, x: 0, duration: 0.3 }, "<0.15")
      .to(".layer--data", { autoAlpha: 1, x: 0, duration: 0.3 }, "<0.05")
      .to(".connector--one, .connector--two", { clipPath: "inset(0 0% 0 0)", duration: 0.25, ease: "none" })
      .to(".chat--one", { autoAlpha: 1, x: 0, duration: 0.3 }, "<0.1")
      .to(".chat--two", { autoAlpha: 1, x: 0, duration: 0.3 }, "<0.05");
  }

  function realShots() {
    // The two windows drift at different speeds, so they read as depth on a desktop.
    // They start slightly tilted back in 3D and settle flat as they reach the middle of the screen.
    // One arc across the whole pass: tilted back on the way in, flat while you read, tipping forward on the way out.
    gsap.set([".real__shot--glass", ".real__shot--messages"], { transformOrigin: "50% 60%" });
    gsap.timeline({ scrollTrigger: { trigger: ".real__stage", start: "top 95%", end: "bottom 5%", scrub: 0.8 } })
      // Linear, so the tilt resolves steadily and is flat exactly as the windows reach the middle of the screen.
      .fromTo(".real__shot--glass", { rotationX: 26, rotationY: 22 }, { rotationX: 0, rotationY: 0, duration: 0.5, ease: "none" }, 0)
      .fromTo(".real__shot--messages", { rotationX: 28, rotationY: -26 }, { rotationX: 0, rotationY: 0, duration: 0.5, ease: "none" }, 0)
      .to(".real__shot--glass", { rotationX: -18, rotationY: -14, duration: 0.4, ease: "none" }, 0.6)
      .to(".real__shot--messages", { rotationX: -20, rotationY: 16, duration: 0.4, ease: "none" }, 0.6);
    // On wider screens the windows also drift at different depths; on phones they stay put so they never collide.
    if (window.matchMedia("(min-width: 901px)").matches) {
      const drift = { trigger: ".real__stage", start: "top bottom", end: "bottom top", scrub: true };
      gsap.fromTo(".real__shot--glass", { yPercent: 4 }, { yPercent: -4, ease: "none", scrollTrigger: drift });
      gsap.fromTo(".real__shot--messages", { yPercent: 14 }, { yPercent: -10, ease: "none", scrollTrigger: { ...drift } });
    }
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

  // The intro runs once, outside gsap.matchMedia: ScrollTrigger reverts and restores matchMedia animations
  // while it measures the page on load, and a restored timeline only re-applies the steps it has reached, so
  // every later element would show at full opacity until its turn, then blink out.
  const reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  if (!reduceMotion && shouldPlayIntro()) intro();
  else root.classList.remove("intro", "intro-skipped");

  const media = gsap.matchMedia();
  media.add("(prefers-reduced-motion: no-preference)", () => {
    story();
    headlineReveals();
    realShots();
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
