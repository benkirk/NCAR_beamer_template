default: template.pdf

template.pdf: template.tex Makefile
	echo "Foo"
	TEXINPUTS=common//:$$TEXINPUTS xelatex $< && \
	  TEXINPUTS=common//:$$TEXINPUTS xelatex $<
clean:
	rm *~
