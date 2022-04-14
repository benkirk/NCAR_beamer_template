template_sources := $(shell find ./common -name "*.sty")
latexprog := $(shell which xelatex 2>/dev/null || which pdflatex)

default: template.pdf

template.pdf: template.tex Makefile $(template_sources)
	echo "Foo"
	TEXINPUTS=common//:$$TEXINPUTS $(latexprog) $< && \
	  TEXINPUTS=common//:$$TEXINPUTS $(latexprog) $<

clean:
	rm *~

echo:
	echo "template_sources: " && echo $(template_sources) && echo
	echo "latexprog: " && echo $(latexprog)
