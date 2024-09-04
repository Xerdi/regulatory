CNF_LINE = -cnf-line TEXMFHOME={../,$(shell kpsewhich --var-value TEXMFHOME)}
COMPILER ?= lualatex --interaction=nonstopmode --shell-escape $(CNF_LINE)
RM = rm -f
ifeq ($(OS),Windows_NT)
	RM = del
endif


.PHONY: all extra clean clean-all clean-leftovers
.DELETE_ON_ERROR:

all: clean-all regulatory-nl.pdf regulatory-en.pdf

extra: all md-example.pdf

%.aux: %.tex
	$(COMPILER) $*

%.glstex: %.aux
	bib2gls $*

%.pdf: %.glstex
	$(COMPILER) $*

example1-nl.aux: example2-nl.glstex

example1-en.aux: example2-en.glstex

regulatory-nl.pdf: example1-nl.pdf example2-nl.pdf

regulatory-en.pdf: example1-en.pdf example2-en.pdf

md-example.pdf: example1-nl.pdf example2-nl.pdf

clean-%:
	latexmk -f -c $*-en
	latexmk -f -c $*-nl

clean-all-%:
	latexmk -f -C $*-en
	latexmk -f -C $*-nl

clean: clean-example1 clean-example2 clean-regulatory
	rm -f *.glstex

clean-all: clean-all-example1 clean-all-example2 clean-all-regulatory
	rm -f *.glstex
