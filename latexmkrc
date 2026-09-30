# latexmk reads this file when run from this directory -- Overleaf does, for a
# project uploaded from this repository (or `make overleaf`'s zip).  It points
# TeX at the theme, its logos and the bundled Poppins in _extensions/ncar/,
# as the Makefile's TEXINPUTS/TTFONTS do; Overleaf has no other way to set
# them.  The engine is not set here: Overleaf's Menu > Compiler (XeLaTeX)
# overrides it anyway, and the Makefile passes -xelatex.
$ENV{'TEXINPUTS'} = './_extensions/ncar//:' . ($ENV{'TEXINPUTS'} // '');
$ENV{'TTFONTS'}   = './_extensions/ncar//:' . ($ENV{'TTFONTS'}   // '');
