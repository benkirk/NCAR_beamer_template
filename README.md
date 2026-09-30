# NSF NCAR / UCAR Beamer Template

Branded slides for NSF NCAR, UCAR and UCP, written in **LaTeX beamer** or
**Quarto Markdown**: a PDF, and from the same Markdown an **HTML** (revealjs)
deck to present in a browser. The theme follows the 2026 Brand Guide: the
brand palette, Poppins type, the official logo lockups, and the wave
super-graphic.

![preview](docs/preview.png)

![HTML preview](docs/preview-html.png)

## Quick Start

### 1. Get your own copy

Click **Use this template → Create a new repository** at the top of this
page. Or, from the command line:

```bash
gh repo create my-talk --template benkirk/NCAR_beamer_template --private --clone
cd my-talk
```

### 2. Install the prerequisites

| you want | you need |
|---|---|
| LaTeX slides | TeX Live (or MacTeX / MiKTeX) with **XeLaTeX** and **latexmk** |
| Quarto HTML slides | [Quarto](https://quarto.org/docs/get-started/) ≥ 1.6 only: no TeX |
| Quarto PDF slides | the LaTeX row, plus [Quarto](https://quarto.org/docs/get-started/) ≥ 1.6. Quarto's TinyTeX (`quarto install tinytex`) also works and installs missing LaTeX packages on the fly. With a minimal TeX Live, callouts need `fontawesome5` (`texlive-fonts-extra` on Debian/Ubuntu). |

On NCAR systems, `module load texlive` provides TeX. No font installation is
needed, because Poppins is bundled with the theme.

### 3. Write and build

| | edit | build | output |
|---|---|---|---|
| **LaTeX** | `talk.tex` | `make` | `talk.pdf` |
| **Quarto** | `talk-quarto.qmd` | `make quarto` | `talk-quarto.pdf` |
| **Quarto, HTML** | `talk-quarto.qmd` | `make html` | `talk-quarto.html` (+ `talk-quarto_files/`) |

Both starter decks contain a title slide, a section divider, a content slide,
a photo slide, code, and a closing slide. Replace the placeholder text, drop
your photos into `images/`, and rebuild.

Stuck? `examples/` shows every feature: [`template.tex`](examples/template.tex),
[`quarto-demo.qmd`](examples/quarto-demo.qmd), and
[`paper.tex`](examples/paper.tex) for non-slide documents. Build them with
`make examples`.

## Already have a project?

**A Quarto project:** add the extension to it, then use `format: ncar-beamer`
(PDF) or `format: ncar-revealjs` (HTML), or list both:

```bash
quarto add benkirk/NCAR_beamer_template
```

**An existing LaTeX deck:** point TeX at the theme directory and switch the
theme:

```bash
export TEXINPUTS=/path/to/NCAR_beamer_template/_extensions/ncar//:
export TTFONTS=/path/to/NCAR_beamer_template/_extensions/ncar//:   # bundled Poppins
latexmk -xelatex my-talk.tex
```

```latex
\usetheme[brand=ncar]{NCAR}
```

## Cheat sheet

| | LaTeX | Quarto Markdown |
|---|---|---|
| Title slide | `\titlepage` in a `[plain]` frame | automatic from `title:`, `subtitle:`, `author:`, `institute:`, `date:` |
| Photo on the title slide | `\titlegraphic{\includegraphics{photo.jpg}}` | `titlegraphic: photo.jpg` |
| Fine print under the title | `\titlefineprint{...}` | `fineprint: "..."` |
| Section divider | `\section{...}` | `# Section` |
| Divider subtitle | `\sectionsubtitle{...}` before `\section` | a paragraph right after `# Section` |
| Slide | `\begin{frame}{Title}` | `## Title` |
| Blocks | `block`, `exampleblock`, `alertblock` | `### Title`, `### Title {.example}`, `### Title {.alert}` |
| Emphasis | `\alert{...}` | `[text]{.alert}` |
| Photo "feature" slide | `\begin{frame}[ncarbg=photo.jpg]` | `## Title {.feature background="photo.jpg"}` |
| Closing slide | `\ncarclosingframe{Thank you!}{...}` | `## Thank you! {.closing}` |
| Code | `lstlisting` (styled automatically) | fenced code blocks (brand-colored highlighting) |
| Callouts | | `::: {.callout-note}` and the other callout types |
| Extra logo or slide decoration | `\logo{...}`: bottom right, above the footer (space reserved) | `logo: file.png` |
| Theme options | `\usetheme[<options>]{NCAR}` | `themeoptions: [<options>]` |

Everything in the Quarto column works in both `ncar-beamer` and `ncar-revealjs`.
The HTML format adds a few things of its own (next section).

## HTML slides (`ncar-revealjs`)

The same Markdown renders as a [revealjs](https://revealjs.com) web deck, in the
same layouts: the title slide with waves or a photo, section dividers,
content slides with the accent tab and logo, feature and closing slides.

```bash
quarto render talk-quarto.qmd --to ncar-revealjs    # or: make html
```

Open `talk-quarto.html` in a browser; keep `talk-quarto_files/` beside it.

| key | |
|---|---|
| `→` `←` / space | next / previous |
| `f` | full screen |
| `s` | speaker view: notes (`::: {.notes}`), next slide, timer |
| `m` | slide menu |
| `b` / `c` | whiteboard / draw on the slide |
| `o` / `esc` | overview |

HTML-only extras:
- **`## Title {.brand-dark}`**: a content slide on Space with white text. PDF
  draws an ordinary slide.
- **Autofit**: a content slide that overflows shrinks its body text (down to
  65%) until it fits; the title keeps its size. Opt out per slide with
  `{.no-autofit}` or `{.scrollable}`, or per deck with `themeoptions: [autofit=false]`.
- **Live diagrams**: mermaid and Graphviz draw in the browser, filling the
  column (capped to the content height). Mermaid picks up the brand font and
  colors. `examples/quarto-demo.qmd` has one of each.
- **Screenshots**: `{height="72%" fig-align="center"}`, the beamer recipe for a
  full-width 16:9 image, fits the HTML slide too. A smaller percentage gives
  a proportionally smaller image.
- **Fragments**: `::: {.incremental}` lists and `. . .` pauses step through.
  (Beamer PDF gets one page per step.)

**One file to email:** set `embed-resources: true` for a single self-contained
`.html` (fonts, logos and photos inlined). The whiteboard can't be embedded,
so turn it off at the same time:

```yaml
format:
  ncar-revealjs:
    embed-resources: true
    chalkboard: false
```

**A PDF from the HTML deck:** open it with `?print-pdf` after the file name
(for example `talk-quarto.html?print-pdf`) in Chrome, and print to PDF with
background graphics on. For a PDF to hand out, the beamer format is usually
the better choice.

### Theme options

| option | values | default | |
|---|---|---|---|
| `brand` | `ncar`, `ucar`, `ncarucar` | `ncar` | palette and logo lockup: NSF NCAR, UCAR, or NSF NCAR-UCAR |
| `title` | `dark`, `light` | `dark` | title/closing slide field: brand color with the white-reversed logo, or white with the full-color logo |
| `fonts` | `poppins`, `bundled`, `helvetica` | `poppins` | `poppins` uses an installed Poppins, else the bundled copy; `bundled` always uses the bundled copy; `helvetica` is the brand's sanctioned substitute (and the only choice under pdfLaTeX) |
| `footer` | `minimal`, `full` | `minimal` | page number only, or also the section, short title and date |
| `sectionpages` | `true`, `false` | `true` | a branded divider slide at each section |
| `logo` | `true`, `false` | `true` | logo at the top right of content slides |
| `autofit` | `true`, `false` | `true` | HTML only: shrink overflowing content slides to fit |

The HTML format reads `brand`, `title` and `autofit` and ignores the rest. It
has no NSF NCAR-UCAR web lockup yet, so `brand=ncarucar` shows the NSF NCAR
logo there.

`make variants` builds `examples/template.tex` in UCAR, NCAR-UCAR, light-title,
4:3 and pdfLaTeX flavors.

### Colors

Use the palette by name:
- **NSF NCAR:** `NCARBlue`, `DarkBlue`, `Space`, `LightBlue`, `LightGray`
- **UCAR/UCP:** `UCARAqua`, `UCARAquaContrast`, `LightAqua`
- **Accents:** `BrandOrange`, `BrandYellow`

There are also brand-aware roles that follow the `brand=` option: `BrandPrimary`, `BrandPrimaryText`, `BrandSecondary`,
`BrandAccent` and `BrandText`.

## Brand rules the theme follows

- **Text colors:**
  - Dark Blue on white or Light Gray.
  - White on NCAR Blue.
  - Space on UCAR Aqua.
- **Accents:** orange and yellow appear only in small amounts (the title bar, the slide-title tab, alert blocks).
- **Logos:**
  - The NCAR logo is always locked up with the NSF logo.
  - Full-color on light backgrounds, white-reversed on dark ones.
  - Never placed on busy photos, so feature slides have no logo.
- **Fonts:** Poppins Bold for headlines and Poppins Regular for body text, with Helvetica as the substitute.

The logos are the official RGB lockups from the UCAR brand portal
(<https://ucar.canto.com/v/branding>). NSF NCAR, UCAR and UCP staff may use
them on presentations without further permission. For any other use, contact
designhelp@ucar.edu. Poppins is distributed under the SIL Open Font License.

## What's in the repository

```
talk.tex, talk-quarto.qmd   your starter decks
images/                     photos (examples use images/wallpaper/)
_extensions/ncar/           the theme: Quarto extension *and* LaTeX sources
  beamerthemeNCAR.sty         options; loads the color/font/inner/outer themes
  ncar_branding.sty           palette, fonts, logos, listings style (also for non-beamer docs)
  ncar-beamer.lua             Quarto: loads the theme; Markdown sugar
  ncar-revealjs.{scss,css,js,lua}, title-slide.html
                              the HTML (revealjs) format
  ncar.theme                  syntax-highlighting colors
  ncar-assets/                logos and bundled Poppins; web/ holds the HTML logos
tools/web-logos.sh          regenerates ncar-assets/web/ from the brand kit
examples/                   feature showcase (LaTeX, Quarto, article)
  diagrams/                   one Graphviz and one mermaid source, shared by both
                              showcases; `make diagrams` rebuilds the PDFs that
                              template.tex includes (needs Graphviz and npx)
```

## Migrating a 2020-brand (v1) deck

1. Change `\usetheme{ncar}` to `\usetheme{NCAR}`.
2. Point `TEXINPUTS` and `TTFONTS` at this repo's `_extensions/ncar/` (see
   "Already have a project?" above).

Everything else carries over:
- **Environments:**
  - `NCARtitleframe[img]` becomes the new title slide. Its body, usually
    `\vspace` plus `\maketitle`, is ignored.
  - `NCARprettyframe[img]` becomes a photo feature frame, or a brand-field
    frame when no image is given.
- **Colors:** the old names still compile. `HilightGreen` is now an NCAR Blue
  text highlight, so it stays legible on white.
- **`\logo{...}`** still decorates the bottom of a slide, as before.
- **`listings`** is still loaded automatically, and your own `\lstset`
  still works.
- **No-op commands:** `\titlebackground`, `\nobackground` and
  `\defaultbackground` do nothing.

What looks different:
- Poppins is wider than Helvetica, so slides packed to the limit may need
  trimming or `[shrink]`.
- Each `\section` now gets a divider slide. Use `sectionpages=false` for the
  old behavior.
- `footer=full` shows the section name in the footer, as the old footer did.

## The 2020-brand version

The previous theme (`\usetheme{ncar}`, CoolGray with the older `#1A658F` blue
and Cormorant) is preserved at tag
[`v1.0-brand2020`](https://github.com/benkirk/NCAR_beamer_template/tree/v1.0-brand2020)
and on branch `brand-2020`. Documents that use its color names (`NCARBlue`,
`CoolGray11`, `DeepBlue`, ...) still compile with this version; those names
map onto the nearest 2026 colors.

## License

Copyright © 2026 University Corporation for Atmospheric Research.

This theme is licensed under
[CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/) (Creative
Commons Attribution-ShareAlike 4.0 International); the full text is in
[`LICENSE`](LICENSE). You may share and adapt it with attribution, provided
you distribute your changes under the same license.

Slides you *create* with the template are your own content. The license
covers the theme and the starter files, not what you put in your deck.

These parts are **not** covered by that license:

- **NSF, NCAR, UCAR and UCP logos** (`_extensions/ncar/ncar-assets/logos/`
  and `ncar-assets/web/`).
  These are trademarks used under the
  [UCAR brand guidelines](https://ucar.canto.com/v/branding).
- **The Poppins font** (`_extensions/ncar/ncar-assets/fonts/Poppins/`) is
  licensed under the SIL Open Font License; see `OFL.txt` in that directory.
- **The photographs in `images/wallpaper/`** are carried over from the
  original template as example imagery. Replace them with your own.
