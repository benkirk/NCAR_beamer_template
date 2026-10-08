/* ncar-revealjs.js -- autofit for the NCAR revealjs theme.
 *
 * A content slide whose body runs past the bottom margin gets its body text
 * shrunk in small steps until it fits (never below 65%), like PowerPoint's
 * shrink-on-overflow in the pptx decks.  The title keeps its size (fixed in
 * the scss).  Opt out per slide with {.no-autofit} or {.scrollable}, or per
 * deck with `themeoptions: [autofit=false]`.
 *
 * Layout controls (ncar-revealjs.lua wraps the body in .ncar-body): a slide
 * with scale="S" starts at S instead of 1, .fill grows in the same steps until
 * the body would overflow, down or across (up to 3x), and .vcenter then
 * centers the body in the space left above the floor.  These apply even where
 * autofit is off.
 *
 * Reveal only lays out the slides near the current one, so each slide is
 * fitted when it is shown (and all of them for ?print-pdf); fitting is
 * idempotent, so late renderers (fonts, mermaid, MathJax) just refit.
 *
 * Also: quarto renders each mermaid diagram inside its slide, which reveal
 * has scaled to the window, so mermaid measured every label at that scale
 * (0.8 at 1280 px) and clipped the text.  Rendering in mermaid's own
 * unscaled scratch element measures true sizes.
 */
(function () {
  "use strict";
  var MIN = 0.65, STEP = 0.04, GAP = 24;  // GAP: slide px between body and footnotes
  var MAXFILL = 3.0;
  var NEVER = ".ncar-section, .closing, .feature, .full, .quarto-title-block";
  var NOSHRINK = ".scrollable, .no-autofit";

  function contentBottom(s) {
    var b = 0;
    for (var i = 0; i < s.children.length; i++) {
      var c = s.children[i];
      if (c.matches("h2, aside.notes, .ncar-waves, .ncar-footnotes, script, style")) continue;
      b = Math.max(b, c.offsetTop + c.offsetHeight);
    }
    return b;
  }

  // .fill stops where a code block or table would scroll (code there doesn't
  // wrap, scss), across or inside its own height cap, or the body gets wider
  function scrolls(s) {
    var over = false;
    s.querySelectorAll(":scope > .ncar-body :is(pre, pre code, table)").forEach(function (e) {
      if (e.scrollWidth > e.clientWidth + 1 || e.scrollHeight > e.clientHeight + 1) over = true;
    });
    var body = s.querySelector(":scope > .ncar-body");
    return over || (body && body.scrollWidth > body.clientWidth + 1);
  }

  function fit(s, autofit) {
    if (!s.classList.contains("slide") || s.matches(NEVER) || s.offsetHeight === 0) return;
    var layout = s.classList.contains("ncar-layout");
    var shrink = autofit && !s.matches(NOSHRINK);
    if (!layout && !shrink) return;
    s.style.fontSize = "";
    s.style.removeProperty("--ncar-fit");  // scales the diagram cap (scss)
    s.style.removeProperty("--ncar-shift");
    var cs = getComputedStyle(s);
    var base = parseFloat(cs.fontSize);
    // footnotes sit on the floor (scss): the body has to end above them
    var foot = s.querySelector(":scope > .ncar-footnotes");
    var floor = s.clientHeight - parseFloat(cs.paddingBottom);
    var limit = function () { return foot ? floor - foot.offsetHeight - GAP : floor; };
    var f = 1;
    var size = function (v) {
      f = v;
      s.style.fontSize = (base * f).toFixed(2) + "px";
      s.style.setProperty("--ncar-fit", f.toFixed(2));
    };
    var scale = parseFloat(s.getAttribute("data-ncar-scale"));
    if (scale > 0 && scale !== 1) size(scale);
    if (s.classList.contains("ncar-fill")) {
      var over = function () { return contentBottom(s) > limit() || scrolls(s); };
      while (f + STEP <= MAXFILL && !over()) size(f + STEP);
      if (over() && f - STEP >= MIN) size(f - STEP);
    }
    if (shrink) {
      while (contentBottom(s) > limit() && f - STEP >= MIN) size(f - STEP);
    }
    if (s.classList.contains("ncar-vcenter")) {
      var free = limit() - contentBottom(s);
      if (free > 0) s.style.setProperty("--ncar-shift", (free / 2).toFixed(1) + "px");
    }
  }

  function fitShown() {
    var autofit = !document.documentElement.classList.contains("ncar-no-autofit");
    document.querySelectorAll(".reveal .slides section.slide").forEach(function (s) {
      fit(s, autofit);
    });
  }

  // mermaidAPI is frozen, so swap in a copy whose render drops the container
  function unscaledMermaid() {
    try {
      var api = window.mermaid && window.mermaid.mermaidAPI;
      if (!api || !api.render || api.ncarUnscaled) return;
      window.mermaid.mermaidAPI = Object.assign({}, api, {
        ncarUnscaled: true,
        render: function (id, text) { return api.render(id, text); },
      });
    } catch (e) {
      console.warn("ncar-revealjs: mermaid labels may clip", e);
    }
  }

  window.addEventListener("DOMContentLoaded", function () {
    unscaledMermaid();  // before quarto's "load" handler renders
    var R = window.Reveal;
    if (!R) return;
    ["ready", "slidechanged", "pdf-ready"].forEach(function (e) { R.on(e, fitShown); });
    window.addEventListener("load", fitShown);
    if (document.fonts) document.fonts.ready.then(fitShown);
    setTimeout(fitShown, 1500);  // mermaid, MathJax
    if (window.MathJax && MathJax.Hub) MathJax.Hub.Queue(fitShown);
  });
})();
