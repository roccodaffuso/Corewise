// SPDX-License-Identifier: MPL-2.0

const reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
const reveals = document.querySelectorAll(".reveal");

if (reducedMotion || !("IntersectionObserver" in window)) {
  reveals.forEach((element) => element.classList.add("is-visible"));
} else {
  const observer = new IntersectionObserver(
    (entries) => {
      entries.forEach((entry) => {
        if (!entry.isIntersecting) return;
        entry.target.classList.add("is-visible");
        observer.unobserve(entry.target);
      });
    },
    { threshold: 0.12 }
  );

  reveals.forEach((element) => observer.observe(element));

  const stage = document.querySelector("[data-depth]");
  const updateDepth = () => {
    if (!stage) return;
    const progress = Math.min(Math.max(window.scrollY / window.innerHeight, 0), 1);
    stage.style.setProperty("--tilt", `${4 - progress * 4}deg`);
    stage.style.setProperty("--lift", `${progress * -18}px`);
  };

  updateDepth();
  window.addEventListener("scroll", updateDepth, { passive: true });
}
