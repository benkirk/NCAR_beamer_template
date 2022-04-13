template_sources := $(shell find ./common -name "*.sty")

default: template.pdf

template.pdf: template.tex Makefile $(template_sources)
	echo "Foo"
	TEXINPUTS=common//:$$TEXINPUTS xelatex $< && \
	  TEXINPUTS=common//:$$TEXINPUTS xelatex $<

clean:
	rm *~

echo:
	echo "template_sources: " && echo $(template_sources) && echo
