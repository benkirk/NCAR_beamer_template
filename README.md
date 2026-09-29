# NSF NCAR / UCAR Beamer Template

Branded PDF slides for NSF NCAR, UCAR and UCP, written in **LaTeX beamer** or
**Quarto Markdown**. The theme follows the 2026 Brand Guide: the brand
palette, Poppins type, the official logo lockups, and the wave super-graphic.

![preview](docs/preview.png)

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
| Quarto slides | the above, plus [Quarto](https://quarto.org/docs/get-started/) ≥ 1.4. Quarto's TinyTeX (`quarto install tinytex`) also works and installs missing LaTeX packages on the fly. With a minimal TeX Live, callouts need `fontawesome5` (`texlive-fonts-extra` on Debian/Ubuntu). |

On NCAR systems, `module load texlive` provides TeX. No font installation is
needed, because Poppins is bundled with the theme.

### 3. Write and build

| | edit | build | output |
|---|---|---|---|
| **LaTeX** | `talk.tex` | `make` | `talk.pdf` |
| **Quarto** | `talk-quarto.qmd` | `make quarto` | `talk-quarto.pdf` |

Both starter decks contain a title slide, a section divider, a content slide,
a photo slide, code, and a closing slide. Replace the placeholder text, drop
your photos into `images/`, and rebuild.

Stuck? `examples/` shows every feature: [`template.tex`](examples/template.tex),
[`quarto-demo.qmd`](examples/quarto-demo.qmd), and
[`paper.tex`](examples/paper.tex) for non-slide documents. Build them with
`make examples`.

## Already have a project?

**A Quarto project:** add the extension to it, then use `format: ncar-beamer`:

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
| Slide | `\begin{frame}{Title}` | `## Title` |
| Blocks | `block`, `exampleblock`, `alertblock` | `### Title`, `### Title {.example}`, `### Title {.alert}` |
| Emphasis | `\alert{...}` | `[text]{.alert}` |
| Photo "feature" slide | `\begin{frame}[ncarbg=photo.jpg]` | `## Title {.feature background="photo.jpg"}` |
| Closing slide | `\ncarclosingframe{Thank you!}{...}` | `## Thank you! {.closing}` |
| Code | `lstlisting` (styled automatically) | fenced code blocks (brand-colored highlighting) |
| Callouts | | `::: {.callout-note}` and the other callout types |
| Theme options | `\usetheme[<options>]{NCAR}` | `themeoptions: [<options>]` |

### Theme options

| option | values | default | |
|---|---|---|---|
| `brand` | `ncar`, `ucar`, `ncarucar` | `ncar` | palette and logo lockup: NSF NCAR, UCAR, or NSF NCAR-UCAR |
| `title` | `dark`, `light` | `dark` | title/closing slide field: brand color with the white-reversed logo, or white with the full-color logo |
| `fonts` | `poppins`, `bundled`, `helvetica` | `poppins` | `poppins` uses an installed Poppins, else the bundled copy; `bundled` always uses the bundled copy; `helvetica` is the brand's sanctioned substitute (and the only choice under pdfLaTeX) |
| `footer` | `minimal`, `full` | `minimal` | page number only, or also the short title and date |
| `sectionpages` | `true`, `false` | `true` | a branded divider slide at each section |
| `logo` | `true`, `false` | `true` | logo at the top right of content slides |

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
  ncar.theme                  syntax-highlighting colors
  ncar-assets/                logos and bundled Poppins
examples/                   feature showcase (LaTeX, Quarto, article)
```

## The 2020-brand version

The previous theme (`\usetheme{ncar}`, CoolGray with the older `#1A658F` blue
and Cormorant) is preserved at tag
[`v1.0-brand2020`](https://github.com/benkirk/NCAR_beamer_template/tree/v1.0-brand2020)
and on branch `brand-2020`. Documents that use its color names (`NCARBlue`,
`CoolGray11`, `DeepBlue`, ...) still compile with this version; those names
map onto the nearest 2026 colors.
