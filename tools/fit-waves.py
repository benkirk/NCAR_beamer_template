#!/usr/bin/env python3
"""Fit the brand wave lines to cubic Béziers, for the beamer and revealjs themes.

The 2025 brand's slide template (Google Slides / PowerPoint) draws its waves as
raster art: a cover overlay of three Light Blue lines with white fills between
them.  This script traces the line centres in that PNG and fits each line as
two cubic Bézier segments joined at its rightmost point, then prints the
control points as fractions of the slide width and height:

  * a TikZ block for beamerouterthemeNCAR.sty (y up), and
  * a Lua table for ncar-revealjs.lua (y down).

Paste both; re-run to check that they still agree with each other and with the
art.  Usage:

  fit-waves.py <template.pptx>   # the framework's branded template
  fit-waves.py cover.png         # ppt/media/image4.png extracted by hand

The cover overlay is ppt/media/image4.png (1920x1080, placed at the slide's
left edge with 28.4% cropped from the right, so pixel x / 1920 is the slide
fraction).  The themes use these three curves on every slide type, shifted
right for the section, closing and content slides: the brand guide's content
slides (p26) carry the same shapes with the bulge running off the right edge.
(The pptx master's own content strip, ppt/media/image2.png, is a squeezed
export of that and is not traced.)

Needs numpy, scipy and Pillow.
"""
import io
import sys
import zipfile

import numpy as np
from PIL import Image
from scipy.optimize import minimize

# ---------------------------------------------------------------------------
# tracing
# ---------------------------------------------------------------------------

def line_centres(mask, n_lines):
    """Per row, the centre x of each of the n_lines runs of True in mask."""
    rows = []
    for y in range(mask.shape[0]):
        xs = np.flatnonzero(mask[y])
        if len(xs) == 0:
            continue
        # split into runs
        breaks = np.flatnonzero(np.diff(xs) > 2) + 1
        runs = np.split(xs, breaks)
        if len(runs) != n_lines:
            continue
        rows.append((y, [float(r.mean()) for r in runs]))
    return rows


def cover_samples(png):
    """Cover overlay: Light Blue lines on a white/transparent field."""
    im = np.asarray(Image.open(png).convert("RGBA")).astype(int)
    h, w = im.shape[:2]
    r, g, b, a = (im[..., i] for i in range(4))
    mask = (a > 128) & (b - r > 60)  # blue-ish: the lines, not the white fills
    rows = line_centres(mask, 3)
    return [[(x / w, y / (h - 1)) for (y, cs) in rows for x in [cs[i]]] for i in range(3)]




# ---------------------------------------------------------------------------
# fitting
# ---------------------------------------------------------------------------

def bezier(p0, p1, p2, p3, t):
    t = t[:, None]
    return ((1 - t) ** 3 * p0 + 3 * (1 - t) ** 2 * t * p1
            + 3 * (1 - t) * t ** 2 * p2 + t ** 3 * p3)


def x_at(p0, p1, p2, p3, ys):
    """x of the curve at each y in ys (y must be monotone along the curve)."""
    t = np.linspace(0, 1, 2001)
    pts = bezier(p0, p1, p2, p3, t)
    order = np.argsort(pts[:, 1])
    return np.interp(ys, pts[order, 1], pts[order, 0])


def fit_segment(pts, p0, p3, vertical_at):
    """Fit P1, P2 for a segment from p0 to p3 through pts.

    vertical_at is 'end' or 'start': that endpoint's tangent is vertical (the
    peak), so the neighbouring control point shares its x.
    """
    xs, ys = pts[:, 0], pts[:, 1]

    def unpack(v):
        if vertical_at == "end":
            p1 = np.array([v[0], v[1]])
            p2 = np.array([p3[0], v[2]])
        else:
            p1 = np.array([p0[0], v[0]])
            p2 = np.array([v[1], v[2]])
        return p1, p2

    def cost(v):
        p1, p2 = unpack(v)
        return np.mean((x_at(p0, p1, p2, p3, ys) - xs) ** 2)

    mid = (p0 + p3) / 2
    if vertical_at == "end":
        v0 = [p0[0], mid[1], mid[1]]
    else:
        v0 = [mid[1], p3[0], mid[1]]
    res = minimize(cost, v0, method="Nelder-Mead",
                   options={"xatol": 1e-6, "fatol": 1e-12, "maxiter": 4000})
    p1, p2 = unpack(res.x)
    return p1, p2, np.sqrt(res.fun)


def fit_line(samples):
    """Two segments joined at the rightmost point; returns the 7 points."""
    pts = np.array(samples)
    k = int(np.argmax(pts[:, 0]))
    peak = pts[k]
    top = pts[: k + 1]
    bottom = pts[k:]
    p0 = pts[0].copy()
    p6 = pts[-1].copy()
    p1, p2, e1 = fit_segment(top, p0, peak, "end")
    p4, p5, e2 = fit_segment(bottom, peak, p6, "start")
    return [p0, p1, p2, peak, p4, p5, p6], max(e1, e2)


# ---------------------------------------------------------------------------
# output
# ---------------------------------------------------------------------------

def f(v):
    return f"{v:.4f}"


def print_lua(lines):
    print("-- The brand's three wave lines (tools/fit-waves.py): each is two cubics")
    print("-- from the top edge to the bottom edge, as {x, y} fractions of the slide")
    print("-- (y down): start, ctrl, ctrl, peak, ctrl, ctrl, end.")
    print("local WAVES = {")
    for pts in lines:
        body = ", ".join("{%s, %s}" % (f(p[0]), f(p[1])) for p in pts)
        print(f"  {{ {body} }},")
    print("}")


def print_tikz(lines):
    print("% The brand's three wave lines (tools/fit-waves.py), each two cubics from")
    print("% the top edge to the bottom edge.  \\ncar@wave@<n>@down{<dx>} is line n")
    print("% shifted right by dx (a fraction of \\paperwidth); @up is the same path")
    print("% bottom to top, for filling between two lines.")
    for i, pts in enumerate(lines, 1):
        def c(p):
            return f"({{({f(p[0])}+#1)*\\paperwidth}},{f(1 - p[1])}\\paperheight)"
        n = "i" * i
        print(f"\\def\\ncar@wave@{n}@down#1{{%")
        print(f"  {c(pts[0])}")
        print(f"    .. controls {c(pts[1])} and {c(pts[2])} .. {c(pts[3])}")
        print(f"    .. controls {c(pts[4])} and {c(pts[5])} .. {c(pts[6])}}}")
        print(f"\\def\\ncar@wave@{n}@up#1{{%")
        print(f"  {c(pts[6])}")
        print(f"    .. controls {c(pts[5])} and {c(pts[4])} .. {c(pts[3])}")
        print(f"    .. controls {c(pts[2])} and {c(pts[1])} .. {c(pts[0])}}}")


def main(argv):
    if len(argv) != 2:
        sys.exit(__doc__)
    if argv[1].endswith(".pptx"):
        cover = io.BytesIO(zipfile.ZipFile(argv[1]).read("ppt/media/image4.png"))
    else:
        cover = argv[1]

    fitted, errs = [], []
    for s in cover_samples(cover):
        pts, err = fit_line(s)
        fitted.append(pts)
        errs.append(err)
    print(f"% rms error {', '.join(f'{e * 100:.2f}%' for e in errs)} of the width")
    print_tikz(fitted)
    print()
    print_lua(fitted)


if __name__ == "__main__":
    main(sys.argv)
