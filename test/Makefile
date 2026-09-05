# The examples are plain documents: whatever is in TeX Live, plus the package of
# this project. Pointing TEXMFHOME at the project itself keeps a personal texmf
# tree -- a regulatory.cfg or a hyperref.cfg of your own -- out of the test, so
# what fails here fails for everyone. The tex directory is named once more in
# TEXINPUTS, since kpathsea only reaches it after $TEXMFDIST/tex/latex.
#
# Every suite builds in a directory of its own under out/, so the results keep
# existing next to each other and can be looked at afterwards.
TESTDIR := $(patsubst %/,%,$(dir $(abspath $(firstword $(MAKEFILE_LIST)))))
PROJECT := $(abspath $(TESTDIR)/..)
OUT := $(TESTDIR)/out

CNF_LINE = -cnf-line TEXMFHOME=$(PROJECT)
export TEXINPUTS := $(PROJECT)/tex:$(TESTDIR):$(TEXINPUTS)
export BIBINPUTS := $(TESTDIR):$(BIBINPUTS)

# The sources are copied in rather than reached through TEXINPUTS: \markdownInput
# opens its file with Lua, which does not consult kpathsea, so at least that one
# has to be there for real. Copying all of them keeps the rule simple and the
# build directory self-contained.
SOURCES := $(notdir $(wildcard $(TESTDIR)/*.tex) $(wildcard $(TESTDIR)/*.bib)) example.md latexmkrc

# Populates a build directory and runs a target in it.
define run_in
	@echo "== $(1)"
	@mkdir -p $(OUT)/$(1)
	@cp $(addprefix $(TESTDIR)/,$(SOURCES)) $(OUT)/$(1)/
	@$(MAKE) -C $(OUT)/$(1) -f $(TESTDIR)/Makefile $(2)
endef

# The package is meant for both engines that produce PDF directly, so both of
# them have to get through every example.
ENGINE ?= lualatex
ENGINES ?= lualatex pdflatex
COMPILER ?= $(ENGINE) --interaction=nonstopmode --shell-escape $(CNF_LINE)

EXAMPLES = example1-nl example2-nl example1-en example2-en md-example

# make4ht ships with TeX Live, so the HTML test stays within what `test' promises:
# a TeX installation and nothing else.
MAKE4HT ?= make4ht
BIB2GLS ?= bib2gls
HTML_EXAMPLE = example1-nl
# The second one covers the definitions declared in the document itself, which no
# other check would see disappear: they fail by being absent, not by erroring.
HTML_DEFS_EXAMPLE = example2-nl

# One suite is one build directory and one target, so they can be asked for
# together or one at a time. Conformance is not among them: it needs Docker and
# takes minutes, so it joins only when it is asked for, with
#
#     make test WITH_CONFORMANCE=1
SUITES ?= $(ENGINES) html
ifdef WITH_CONFORMANCE
SUITES += conformance
endif

.PHONY: all test $(addprefix suite-,$(ENGINES) html conformance) \
        test-engines test-html html-checks conformance conformance-run \
        conformance-check conformance-check-run conformance-stale \
        clean-examples clean-all-examples clean clean-all

# The suites share nothing: each copies the sources into a directory of its own
# and writes nowhere else, so they run side by side. The parallelism is asked for
# here rather than left to the caller, since `make test' is meant to be the whole
# thing; --output-sync keeps the output of a suite together instead of letting the
# lines of three engines interleave.
test:
	@$(MAKE) -f $(TESTDIR)/Makefile --jobs=$(words $(SUITES)) --output-sync=target \
	    $(addprefix suite-,$(SUITES))

# What a suite is made of. The engine ones are generated, so that adding an engine
# to ENGINES is enough.
$(foreach engine,$(ENGINES),$(eval suite-$(engine): build-$(engine)))
suite-html: test-html
suite-conformance: conformance

# Runs `all' in a build directory of its own. The Makefile is re-entered there,
# which is why every path above is absolute. The directory is named after the
# engine, and so is the engine it builds with: `make build-pdflatex' is pdflatex.
build-%:
	$(call run_in,$*,all ENGINE=$*)

.DELETE_ON_ERROR:

# Nothing is thrown away as intermediate: a build directory is meant to be looked
# at afterwards, and the aux and glstex files of a run are part of what one looks
# at when a reference or a definition came out wrong.
.SECONDARY:

all: $(addsuffix .pdf,$(EXAMPLES))

%.aux: %.tex
	$(COMPILER) $*

%.glstex: %.aux
	bib2gls $*

# Twice, because the examples refer to each other's articles and definitions.
%.pdf: %.glstex
	$(COMPILER) $*
	$(COMPILER) $*

# Both example documents refer to each other, so the labels of the second one
# have to be on disk before the first one is typeset.
example1-nl.aux: example2-nl.glstex

example1-en.aux: example2-en.glstex

md-example.pdf: example1-nl.pdf example2-nl.pdf

# Runs every example through every supported engine, each in out/<engine>, so both
# results survive and can be compared. The engines are a subset of the suites, kept
# as a target of its own for when only they are of interest.
test-engines:
	@$(MAKE) -f $(TESTDIR)/Makefile --jobs=$(words $(ENGINES)) --output-sync=target \
	    $(addprefix build-,$(ENGINES))

# Builds the examples once per PDF standard and validates them with veraPDF in
# Docker, and writes conformance.tex, which the manual reads. Kept out of `test',
# which needs nothing but a TeX installation, and out of CI, which has no veraPDF.
#
# The examples are built in that directory first: without the sibling .aux files
# the external references do not resolve, and a document without external links is
# not the one we measure.
conformance:
	$(call run_in,conformance,conformance-run)

conformance-run: all
	COMPILER="$(COMPILER)" $(TESTDIR)/conformance.sh

# Fails when the sources no longer match the ones the committed table was made
# from. Costs a hash of a handful of files: no Docker, no LaTeX, no rebuild, which
# is what makes it usable in a pre-commit hook.
conformance-stale:
	@$(TESTDIR)/conformance.sh --check-stale
	@echo "conformance: table is current"

# Fails when the committed table no longer matches what veraPDF says. Rebuilds
# everything and revalidates, so it takes minutes; for a release, not a commit.
conformance-check:
	$(call run_in,conformance,conformance-check-run)

conformance-check-run: all
	COMPILER="$(COMPILER)" CONFORMANCE_TABLE=$(TESTDIR)/conformance.check.tex \
	    $(TESTDIR)/conformance.sh
	diff -u $(TESTDIR)/conformance.tex $(TESTDIR)/conformance.check.tex
	rm -f $(TESTDIR)/conformance.check.tex

# The tex4ht configuration is what turns an article into a section with a heading.
# Without it the conversion still succeeds and produces neither, so counting the
# elements is the only way to see that the configuration was found and applied.
#
# The second example covers a definition declared with \newdefinition. That one is
# checked on the anchor the listing writes, not on its text: a citation elsewhere
# carries the name too, and a phrase can be broken across lines by the converter,
# while this id appears once, where the entry is printed.
#
# It prints its definitions with the description style, which is what the check on
# the dl element is for: the alttree style of glossaries is written in boxes and
# widths and comes out of tex4ht as plain paragraphs, so a style that fell back to
# it would still produce definitions, and only the markup would say so.
#
# One target, one recipe: make keeps only the last recipe given for a target, so a
# second `test-html:' block with its own recipe would silently discard this one.
test-html:
	$(call run_in,html,html-checks)

html-checks: $(HTML_EXAMPLE).html $(HTML_DEFS_EXAMPLE).html
	@sections=$$(grep -o '<section' $(HTML_EXAMPLE).html | wc -l); \
	 headings=$$(grep -oE '<h[1-6]' $(HTML_EXAMPLE).html | wc -l); \
	 items=$$(grep -o 'enumitem-paras' $(HTML_EXAMPLE).html | wc -l); \
	 defs=$$(grep -o 'glo_def1' $(HTML_EXAMPLE).html | wc -l); \
	 inline=$$(grep -o "id='glo_inline'" $(HTML_DEFS_EXAMPLE).html | wc -l); \
	 deflist=$$(grep -o "dl class='description'" $(HTML_DEFS_EXAMPLE).html | wc -l); \
	 echo "html: $$sections sections, $$headings headings, $$items paras items, $$defs definitions, $$inline inline, $$deflist description list"; \
	 if [ "$$sections" -lt 1 ] || [ "$$headings" -lt 1 ]; then \
	     echo "html: no structure in the output; was regulatory.4ht found?" >&2; exit 1; \
	 fi; \
	 if [ "$$items" -lt 1 ]; then \
	     echo "html: a paras item became plain text; is \\DocumentMetadata declared?" >&2; exit 1; \
	 fi; \
	 if [ "$$defs" -lt 1 ]; then \
	     echo "html: no definitions in the output; did bib2gls run?" >&2; exit 1; \
	 fi; \
	 if [ "$$inline" -lt 1 ]; then \
	     echo "html: the inline definition did not reach the list" >&2; exit 1; \
	 fi; \
	 if [ "$$deflist" -lt 1 ]; then \
	     echo "html: the definitions are not a list; did the defstyle survive?" >&2; exit 1; \
	 fi

# Three steps, as for the PDF: the definitions come from bib2gls, which needs the
# aux of a first run.
%.html: %.tex $(PROJECT)/tex/regulatory.4ht
	TEXMFHOME=$(PROJECT) $(MAKE4HT) $<
	$(BIB2GLS) $*
	TEXMFHOME=$(PROJECT) $(MAKE4HT) $<

# Clears the test directory itself, where `all' builds the examples that the
# documentation lists and attaches. Keeps out/ standing: the suites build there,
# and their results are meant to survive a documentation build so they can be
# looked at afterwards.
clean-examples:
	@cd $(TESTDIR) && for example in $(EXAMPLES); do latexmk -f -c $$example; done
	rm -rf $(TESTDIR)/_markdown_*
	rm -f $(TESTDIR)/*.glstex $(TESTDIR)/*.luabridge.lua $(TESTDIR)/conformance.check.tex
	rm -f $(TESTDIR)/*.html $(TESTDIR)/*.css $(TESTDIR)/*.4ct $(TESTDIR)/*.4tc
	rm -f $(TESTDIR)/*.idv $(TESTDIR)/*.lg $(TESTDIR)/*.tmp $(TESTDIR)/*.xref

# The same, but the PDF files go too. The documentation asks for this before it
# builds the examples: with the PDF files still standing make considers them up to
# date and rebuilds nothing, and the manual would read no aux file at all.
clean-all-examples:
	@cd $(TESTDIR) && for example in $(EXAMPLES); do latexmk -f -C $$example; done
	@$(MAKE) -f $(TESTDIR)/Makefile clean-examples

# Both places: the examples and every build directory under out/.
clean: clean-examples
	rm -rf $(OUT)

clean-all: clean-all-examples
	rm -rf $(OUT)
