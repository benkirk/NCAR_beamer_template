default: template.pdf

template.pdf: template.tex Makefile
	echo "Foo"
	TEXINPUTS=common/beamer_themes:$$TEXINPUTS xelatex $< && \
	  TEXINPUTS=common/beamer_themes:$$TEXINPUTS xelatex $<
clean:
	rm *~
