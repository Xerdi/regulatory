COMPILER ?= lualatex --interaction=nonstopmode --shell-escape

all: regulatory-nl.pdf regulatory-en.pdf

extra: all md-example.pdf

.DELETE_ON_ERROR:

%.aux: %.tex
	$(COMPILER) $*

%.glstex: %.aux
	bib2gls $*

%.pdf: %.glstex
	@echo $*.log
	$(COMPILER) $*
	while grep 'Rerun to get ' $*.log ; do $(COMPILER) $* ; done

example1-nl.aux: example2-nl.glstex

example1-en.aux: example2-en.glstex

regulatory-nl.pdf: example1-nl.pdf example2-nl.pdf

regulatory-en.pdf: example1-en.pdf example2-en.pdf

md-example.pdf: example1-nl.pdf example2-nl.pdf
