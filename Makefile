# NSF NCAR / UCAR beamer theme
#
#   make            talk.pdf             (your deck: talk.tex, XeLaTeX via latexmk)
#   make quarto     talk-quarto.pdf      (your deck: talk-quarto.qmd, needs quarto)
#   make html       talk-quarto.html, examples/quarto-demo.html  (revealjs, needs quarto)
#   make examples   examples/template.pdf, examples/paper.pdf, examples/quarto-demo.pdf
#   make variants   brand/title/aspect-ratio/engine variants of examples/template.tex
#   make diagrams   examples/diagrams/*.pdf from their .dot/.mmd (needs Graphviz, npx)
#   make clean
#
# The theme lives in _extensions/ncar/ -- the same files that
# `quarto add benkirk/NCAR_beamer_template` installs.  LaTeX finds the .sty
# files and logos through TEXINPUTS, and the bundled Poppins through TTFONTS.
#
THEME   := $(CURDIR)/_extensions/ncar
ENGINE  ?= xelatex
TEXENV  := TEXINPUTS=$(THEME)//:$(CURDIR)/: TTFONTS=$(THEME)//:
LATEXMK := latexmk -interaction=nonstopmode -halt-on-error

VARIANTS := template-ucar template-ncarucar template-light template-43 template-pdflatex

# latexmk tracks \input files, images and the theme itself -- always ask it (FORCE)
default: talk.pdf

talk.pdf: talk.tex FORCE
	$(TEXENV) $(LATEXMK) -$(ENGINE) talk.tex

quarto: talk-quarto.pdf
talk-quarto.pdf: talk-quarto.qmd FORCE
	quarto render talk-quarto.qmd --to ncar-beamer

html: talk-quarto.html examples/quarto-demo.html
talk-quarto.html: talk-quarto.qmd FORCE
	quarto render talk-quarto.qmd --to ncar-revealjs

examples/quarto-demo.html: examples/quarto-demo.qmd FORCE
	cd examples && quarto render quarto-demo.qmd --to ncar-revealjs

examples: examples/template.pdf examples/paper.pdf examples/quarto-demo.pdf

examples/%.pdf: examples/%.tex FORCE
	cd examples && $(TEXENV) $(LATEXMK) -$(ENGINE) $*.tex

examples/quarto-demo.pdf: examples/quarto-demo.qmd FORCE
	cd examples && quarto render quarto-demo.qmd --to ncar-beamer

# \ncarthemeoptions / \ncaraspectratio are hooks in examples/template.tex
opts_template-ucar       := brand=ucar
opts_template-ncarucar   := brand=ncarucar,footer=full
opts_template-light      := title=light,fonts=bundled
opts_template-43         :=
opts_template-pdflatex   :=
aspect_template-43       := 43
engine_template-pdflatex := pdflatex

variants: $(addprefix examples/,$(addsuffix .pdf,$(VARIANTS)))

examples/template-%.pdf: examples/template.tex FORCE
	cd examples && $(TEXENV) $(LATEXMK) -$(or $(engine_template-$*),$(ENGINE)) -jobname=template-$* \
	  -usepretex='\def\ncarthemeoptions{$(opts_template-$*)}\def\ncaraspectratio{$(or $(aspect_template-$*),169)}' \
	  template.tex

# One source per example diagram: quarto-demo.qmd renders it itself, and
# template.tex includes the PDF built here (committed, so `make examples`
# needs neither tool).  mermaid-cli fetches a headless Chrome on first use.
DIAGRAMS := examples/diagrams
MMDC     ?= npx -y @mermaid-js/mermaid-cli
diagrams: $(DIAGRAMS)/systems.pdf $(DIAGRAMS)/render.pdf

$(DIAGRAMS)/%.pdf: $(DIAGRAMS)/%.dot
	dot -Tpdf $< -o $@

$(DIAGRAMS)/%.pdf: $(DIAGRAMS)/%.mmd
	$(MMDC) -i $< -o $@

clean:
	latexmk -C -quiet talk.tex 2>/dev/null; rm -f talk-quarto.pdf talk-quarto.tex talk-quarto.html
	rm -rf talk-quarto_files examples/quarto-demo_files examples/quarto-demo.html
	cd examples && latexmk -C -quiet template.tex paper.tex $(addsuffix .tex,$(VARIANTS)) 2>/dev/null; \
	  rm -f *.pdf *.nav *.snm *.vrb *.xdv quarto-demo.tex

FORCE:
.PHONY: default quarto html examples variants diagrams clean FORCE
