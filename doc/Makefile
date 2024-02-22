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

clean: clean-leftovers
	$(foreach auxfile,$(wildcard *.aux),latexmk -f -c $(auxfile),)

clean-all: clean-leftovers
	$(foreach file,$(wildcard *.pdf),latexmk -f -C $(basename $(file)).aux,)

clean-leftovers:
	$(foreach file,$(wildcard *.glg),$(RM) $(file))
	$(foreach file,$(wildcard *.atfi),$(RM) $(file))
	$(foreach file,$(wildcard *.glstex),$(RM) $(file))
