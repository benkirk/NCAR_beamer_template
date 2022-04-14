# NCAR LaTeX Beamer Template

This work provides a sample LaTeX/Beamer presentation template intended to be compliant with the [NCAR/UCAR Brand Standards](https://news.ucar.edu/brand).

## Quick Start
The following bash shell commands should suffice to get started:
```bash
# Clone the repo
git clone https://github.com/benkirk/NCAR_beamer_template.git && \
   cd NCAR_beamer_template
# If we have a 'module' command, attempt to load a texlive package
# (In NCAR's environment, this will 'do the right thing' on Casper.)
type module >/dev/null 2>&1 && \
   module try-load texlive || \
   echo "no module command"
# Build the template presentation
make
ls -l template.pdf
```

## Fonts & XeTeX vs. pdfLaTeX
The UCAR/NCAR branding prefers specific fonts: 
* Poppins OTF is to be used for all header and body text [download](https://fonts.google.com/specimen/Poppins?selection.family=Poppins:100,100i,200,200i,300,300i,400,400i,500,500i,600,600i,700,700i,800,800i,900,900i).
* Cormorant TTF is to be used for fine print and asterisk notations [download](https://fonts.google.com/specimen/Cormorant?selection.family=Cormorant:300,300i,400,400i,500,500i,600,600i,700,700i).

It is unlikely these fonts are ncluded on your system by default, but they can be downloaded from the links above.  On Mac OSX, these fonts can then be installed using the *Font Book* application for general use.  In this case it is necessary to use [XeTeX](https://ctan.org/pkg/xetex) to typeset the slides.  Since this requires some effort to set up properly, it is not the default behavior of the package, but rather controlled from the optional parameter `brandedfonts`:
```latex
% speciy the optional parameter to prefer NCAR/UCAR Brand Standard fonts (requires XeTeX),
% otherwise 'Helvetica' will be used.
\usepackage[brandedfonts]{ncar_branding}
```
If you are on a system without XeTeX, or prefer pdfLaTeX, the package falls back to the ['helvet'](https://ctan.org/pkg/helvet) package, (see `ncar_branding.sty`, even this package can be removed if not included on your system).


## External Resources


### Branding
* https://news.ucar.edu/brand
* https://news.ucar.edu/sites/default/files/documents/related-links/2020-03/NCAR-UCAR_BrandStandards_031020-Spreads.pdf
* https://internal.ucar.edu/communications

### Imagery
* https://www.instagram.com/ncar_ucar
* https://photolib.noaa.gov/
* https://earthobservatory.nasa.gov/images
* https://www.nps.gov/aboutus/news/photosmultimedia.htm

Consider the environments `NCARtitleframe` and `NCARprettyframe`, which are very similar.  (The former includes logos and a standard footer.) Both accept an optional argument, an image to be used for the background.  The links above provide a few ideas for imagery related to Earth Science.  Be creative!
```latex
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
\begin{NCARprettyframe}[common/images/wallpaper/mesa_lab.jpg]
  \begin{exampleblock}{}
      \centering
      \relsize{+4}
      \textbf{Backup}
  \end{exampleblock}{}
\end{NCARprettyframe}
```

