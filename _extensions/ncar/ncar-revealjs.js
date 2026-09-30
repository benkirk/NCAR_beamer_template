/* ncar-revealjs.js -- autofit for the NCAR revealjs theme.
 *
 * A content slide whose body runs past the bottom margin gets its body text
 * shrunk in small steps until it fits (never below 65%), like PowerPoint's
 * shrink-on-overflow in the pptx decks.  The title keeps its size (fixed in
 * the scss).  Opt out per slide with {.no-autofit} or {.scrollable}, or per
 * deck with `themeoptions: [autofit=false]`.
 *
 * Reveal only lays out the slides near the current one, so each slide is
 * fitted when it is shown (and all of them for ?print-pdf); fitting is
 * idempotent, so late renderers (fonts, mermaid, MathJax) just refit.
 */
(function () {
  "use strict";
  var MIN = 0.65, STEP = 0.04;
  var SKIP = ".ncar-section, .closing, .feature, .scrollable, .no-autofit, .quarto-title-block";

  function contentBottom(s) {
    var b = 0;
    for (var i = 0; i < s.children.length; i++) {
      var c = s.children[i];
      if (c.matches("h2, aside.notes, .ncar-waves, script, style")) continue;
      b = Math.max(b, c.offsetTop + c.offsetHeight);
    }
    return b;
  }

  function fit(s) {
    if (!s.classList.contains("slide") || s.matches(SKIP) || s.offsetHeight === 0) return;
    s.style.fontSize = "";
    s.style.removeProperty("--ncar-fit");  // scales the diagram cap (scss)
    var cs = getComputedStyle(s);
    var base = parseFloat(cs.fontSize);
    var limit = s.clientHeight - parseFloat(cs.paddingBottom);
    for (var f = 1; contentBottom(s) > limit && f - STEP >= MIN; ) {
      f -= STEP;
      s.style.fontSize = (base * f).toFixed(2) + "px";
      s.style.setProperty("--ncar-fit", f.toFixed(2));
    }
  }

  function fitShown() {
    if (document.documentElement.classList.contains("ncar-no-autofit")) return;
    document.querySelectorAll(".reveal .slides section.slide").forEach(fit);
  }

  window.addEventListener("DOMContentLoaded", function () {
    var R = window.Reveal;
    if (!R) return;
    ["ready", "slidechanged", "pdf-ready"].forEach(function (e) { R.on(e, fitShown); });
    window.addEventListener("load", fitShown);
    if (document.fonts) document.fonts.ready.then(fitShown);
    setTimeout(fitShown, 1500);  // mermaid, MathJax
    if (window.MathJax && MathJax.Hub) MathJax.Hub.Queue(fitShown);
  });
})();
