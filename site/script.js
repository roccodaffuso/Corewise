// SPDX-License-Identifier: MPL-2.0

const reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
const header = document.querySelector(".site-header");
const product = document.querySelector("[data-product-depth]");
const reveals = document.querySelectorAll(".reveal");

const updateChrome = () => {
  header?.classList.toggle("is-scrolled", window.scrollY > 24);

  if (!product || reducedMotion) return;
  const progress = Math.min(Math.max(window.scrollY / window.innerHeight, 0), 1.2);
  product.style.setProperty("--product-y", `${progress * -42}px`);
  product.style.setProperty("--product-rotate-y", `${-7 + progress * 5}deg`);
  product.style.setProperty("--product-rotate-x", `${2 - progress * 1.4}deg`);
};

let scrollFrame = 0;
window.addEventListener("scroll", () => {
  if (scrollFrame) return;
  scrollFrame = window.requestAnimationFrame(() => {
    updateChrome();
    scrollFrame = 0;
  });
}, { passive: true });

updateChrome();

if (reducedMotion || !("IntersectionObserver" in window)) {
  reveals.forEach((element) => element.classList.add("is-visible"));
} else {
  const revealObserver = new IntersectionObserver((entries) => {
    entries.forEach((entry) => {
      if (!entry.isIntersecting) return;
      entry.target.classList.add("is-visible");
      revealObserver.unobserve(entry.target);
    });
  }, { threshold: 0.14, rootMargin: "0px 0px -5%" });

  reveals.forEach((element) => revealObserver.observe(element));
}

const createSignalField = (canvas, options = {}) => {
  const context = canvas.getContext("2d", { alpha: true });
  if (!context) return;

  const pointer = { x: 0.72, y: 0.42, active: false };
  let width = 0;
  let height = 0;
  let frame = 0;
  let running = true;
  let lastDraw = 0;

  const resize = () => {
    const bounds = canvas.getBoundingClientRect();
    const ratio = Math.min(window.devicePixelRatio || 1, 1.5);
    width = Math.max(bounds.width, 1);
    height = Math.max(bounds.height, 1);
    canvas.width = Math.round(width * ratio);
    canvas.height = Math.round(height * ratio);
    context.setTransform(ratio, 0, 0, ratio, 0, 0);
  };

  const draw = (time = 0) => {
    if (!running) return;
    if (!reducedMotion) frame = window.requestAnimationFrame(draw);
    if (!reducedMotion && time - lastDraw < 34) return;
    lastDraw = time;

    context.clearRect(0, 0, width, height);
    const phase = reducedMotion ? 0 : time * 0.00045;
    const centerY = height * (options.centerY || 0.55);
    const lineCount = options.lineCount || 6;

    for (let line = 0; line < lineCount; line += 1) {
      const alpha = 0.045 + line * 0.013;
      context.beginPath();
      context.strokeStyle = `rgba(104, 222, 212, ${alpha})`;
      context.lineWidth = line === Math.floor(lineCount / 2) ? 1.2 : 0.7;

      for (let x = -20; x <= width + 20; x += 12) {
        const normalizedX = x / Math.max(width, 1);
        const distance = Math.abs(normalizedX - pointer.x);
        const influence = pointer.active ? Math.max(0, 1 - distance * 3.1) : 0.2;
        const baseWave = Math.sin(normalizedX * 12 + phase * (1 + line * 0.08)) * (9 + line * 2.2);
        const fineWave = Math.sin(normalizedX * 36 - phase * 1.7 + line) * 3.2;
        const pointerWave = Math.sin(normalizedX * 54 + phase * 2) * influence * 14;
        const offset = (line - (lineCount - 1) / 2) * 46;
        const y = centerY + offset + baseWave + fineWave + pointerWave;
        if (x === -20) context.moveTo(x, y);
        else context.lineTo(x, y);
      }

      context.stroke();
    }

    const gradient = context.createRadialGradient(
      pointer.x * width,
      pointer.y * height,
      0,
      pointer.x * width,
      pointer.y * height,
      Math.min(width, height) * 0.34
    );
    gradient.addColorStop(0, "rgba(104, 222, 212, 0.08)");
    gradient.addColorStop(1, "rgba(104, 222, 212, 0)");
    context.fillStyle = gradient;
    context.fillRect(0, 0, width, height);
  };

  const host = canvas.parentElement;
  host?.addEventListener("pointermove", (event) => {
    const bounds = canvas.getBoundingClientRect();
    pointer.x = (event.clientX - bounds.left) / Math.max(bounds.width, 1);
    pointer.y = (event.clientY - bounds.top) / Math.max(bounds.height, 1);
    pointer.active = true;
  }, { passive: true });

  host?.addEventListener("pointerleave", () => {
    pointer.active = false;
  }, { passive: true });

  const visibilityObserver = new IntersectionObserver((entries) => {
    const visible = entries.some((entry) => entry.isIntersecting);
    if (visible && !running) {
      running = true;
      frame = window.requestAnimationFrame(draw);
    } else if (!visible && running) {
      running = false;
      window.cancelAnimationFrame(frame);
    }
  });

  resize();
  new ResizeObserver(resize).observe(canvas);
  visibilityObserver.observe(canvas);
  draw();
};

const heroCanvas = document.querySelector("[data-signal-canvas]");
const ctaCanvas = document.querySelector("[data-cta-canvas]");

if (heroCanvas) createSignalField(heroCanvas, { lineCount: 7, centerY: 0.52 });
if (ctaCanvas) createSignalField(ctaCanvas, { lineCount: 4, centerY: 0.5 });
