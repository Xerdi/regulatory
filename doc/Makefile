# Two trees: the project, for the package it documents, and TEXMFHOME as it stands
# here, for the listings and colours the manual is styled with. CI mounts
# Xerdi/texmf-packaging at ~/texmf, so there the second one resolves by itself; a
# working copy has to say where that checkout is, with TEXMFHOME in the
# environment, or the manual is built against a personal tree and is not the one
# CI makes. Read once, when make parses this file.
CNF_LINE = -cnf-line TEXMFHOME={../,$(shell kpsewhich --var-value TEXMFHOME)}
# The dtx sources are documented with \DocInput from this directory, the examples
# of the appendix are listed and attached from test/, and the generated package
# has to win from any installed release of it: the project keeps its files in
# tex/, which kpathsea only reaches after $TEXMFDIST/tex/latex.
export TEXINPUTS := ../src:../tex:../test:$(TEXINPUTS)
export BIBINPUTS := ../test:$(BIBINPUTS)
COMPILER ?= lualatex --interaction=nonstopmode --shell-escape $(CNF_LINE)
RM = rm -f
ifeq ($(OS),Windows_NT)
	RM = del
endif


.PHONY: all examples clean clean-all
.DELETE_ON_ERROR:

all: clean-all examples regulatory-nl.pdf regulatory-en.pdf

# Both manuals list, refer to and attach every example, so those are built first.
# From scratch, and not only when a source changed: the manual reads the aux files
# of the examples for its external references, `make build-docs' clears those
# afterwards, and with the PDF files still standing make would rebuild nothing. The
# references would then come out as ?? without anything having failed.
examples:
	$(MAKE) -C ../test -f Makefile clean-all-examples
	$(MAKE) -C ../test -f Makefile all

%.aux: %.tex
	$(COMPILER) $*

%.glstex: %.aux
	bib2gls $*

# Twice, because the page references of the appendix and of the attachments only
# settle on the run after the one that wrote them. makeindex comes after those two
# and before a third: the index is written from the idx file of the run before it,
# so that file has to come from a run whose page numbers had already settled, and the
# index itself is at the end of the document, where it shifts nothing in front of it.
# gind.ist is what reads back the separators doc.sty writes into an idx file.
#
# And a run after that one, because the index puts its own line in the table of
# contents: that line is written by the run that typesets the index and read by the
# one after it.
%.pdf: %.glstex
	$(COMPILER) $*
	$(COMPILER) $*
	makeindex -q -s gind.ist $*
	$(COMPILER) $*
	$(COMPILER) $*

clean-%:
	latexmk -f -c $*-en
	latexmk -f -c $*-nl

clean-all-%:
	latexmk -f -C $*-en
	latexmk -f -C $*-nl

clean: clean-regulatory
	rm -f *.glstex

clean-all: clean-all-regulatory
	rm -f *.glstex
