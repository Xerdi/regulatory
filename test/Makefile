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

# max_print_line as well: TeX wraps what it writes to the log at 79 characters,
# and an assertion that reads a line back would fail on the wrap rather than on
# what the line says.
CNF_LINE = -cnf-line TEXMFHOME=$(PROJECT) -cnf-line max_print_line=9999
export TEXINPUTS := $(PROJECT)/tex:$(TESTDIR):$(TEXINPUTS)
export BIBINPUTS := $(TESTDIR):$(BIBINPUTS)

# The sources are copied in rather than reached through TEXINPUTS: \markdownInput
# opens its file with Lua, which does not consult kpathsea, so at least that one
# has to be there for real. Copying all of them keeps the rule simple and the
# build directory self-contained.
SOURCES := $(notdir $(wildcard $(TESTDIR)/*.tex) $(wildcard $(TESTDIR)/*.bib)) example.md latexmkrc

# Populates a build directory and runs a target in it. The markdown cache goes
# with the sources: it is keyed by the conversion options, which name the syntax
# extension by filename rather than by what is in it, so an edited extension is
# answered from the cache as if nothing had changed. Its files also outlive the
# source they came from, which would leave an assertion reading a conversion that
# no longer exists.
define run_in
	@echo "== $(1)"
	@mkdir -p $(OUT)/$(1)
	@cp $(addprefix $(TESTDIR)/,$(SOURCES)) $(OUT)/$(1)/
	@rm -rf $(OUT)/$(1)/_markdown_*
	@$(MAKE) -C $(OUT)/$(1) -f $(TESTDIR)/Makefile $(2)
endef

# The package is meant for both engines that produce PDF directly, so both of
# them have to get through every example.
ENGINE ?= lualatex
ENGINES ?= lualatex pdflatex
COMPILER ?= $(ENGINE) --interaction=nonstopmode --shell-escape $(CNF_LINE)

# Which examples hand their definitions to bib2gls, and which have none to hand
# over: md-example declares its own, in the metadata and in the definition list of
# its Markdown source, and sign-example has no definitions at all. For those,
# calling bib2gls would be an error rather than a no-op.
BIBEXAMPLES = example1-nl example2-nl example1-en example2-en
BIBFILES = example1.bib example2.bib
PLAINEXAMPLES = md-example sign-example source-example
# Two documents that are meant to fail: a bib with a required field missing, and
# one with a line the reader does not accept. They are not examples, they are the
# other half of the reader's guarantee.
BADEXAMPLES = badsource badsyntax
EXAMPLES = $(BIBEXAMPLES) $(PLAINEXAMPLES)

# make4ht ships with TeX Live, so the HTML test stays within what `test' promises:
# a TeX installation and nothing else.
MAKE4HT ?= make4ht
BIB2GLS ?= bib2gls
HTML_EXAMPLE = example1-nl
# The second one covers the definitions declared in the document itself, which no
# other check would see disappear: they fail by being absent, not by erroring.
HTML_DEFS_EXAMPLE = example2-nl
# And the Markdown one, which is the only place where the module of that name and
# the syntax extension meet tex4ht. It is converted with lualatex, where the
# markdown package reads its source through the Lua interpreter it is already
# running in; under another engine it would reach for shell escape, which this
# suite does not ask for.
HTML_MD_EXAMPLE = md-example

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
        test-engines test-html html-checks md-checks ref-checks sign-checks log-checks \
        source-checks \
        conformance conformance-run \
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
	$(call run_in,$*,all ref-checks log-checks md-checks sign-checks source-checks ENGINE=$*)

.DELETE_ON_ERROR:

# Nothing is thrown away as intermediate: a build directory is meant to be looked
# at afterwards, and the aux and glstex files of a run are part of what one looks
# at when a reference or a definition came out wrong.
.SECONDARY:

all: $(addsuffix .pdf,$(EXAMPLES))

%.aux: %.tex
	$(COMPILER) $*

# Same story one link down: bib2gls reads the aux, but what changes what it writes
# is the document and the bib file it names. Following the aux instead would make
# this rule run on every make, since the run that typesets rewrites that aux.
%.glstex: %.tex $(BIBFILES) | %.aux
	bib2gls $*

# Twice, because the examples refer to each other's articles and definitions.
#
# The aux and the glstex are prerequisites of the order-only kind: they have to
# exist before the PDF is made, but their timestamps say nothing about whether it
# is out of date. An aux file is both an input and an output -- the run that writes
# the PDF rewrites it, and writes it last -- so a normal prerequisite would make
# every one of these documents older than its own aux the moment it was built, and
# the cascade through the glstex of the other document rebuilt all five on every
# make. What the PDF really follows is the source.
$(addsuffix .pdf,$(BIBEXAMPLES)): %.pdf: %.tex | %.glstex
	$(COMPILER) $*
	$(COMPILER) $*

$(addsuffix .pdf,$(PLAINEXAMPLES)): %.pdf: %.tex | %.aux
	$(COMPILER) $*
	$(COMPILER) $*

# Both example documents refer to each other, so the labels of the second one
# have to be on disk before the first one is typeset. Order-only for the reason
# above: what has to be settled here is the order, not the age.
example1-nl.aux: | example2-nl.glstex

example1-en.aux: | example2-en.glstex

md-example.pdf: | example1-nl.pdf example2-nl.pdf

# A reference that resolved to nothing prints two question marks and warns; the run
# succeeds either way, so the warning is what is read here. Over every example, not
# only the Markdown one: a label with a space in it resolved to nothing while every
# example here used labels without one, so the suite had nothing to notice it with.
ref-checks: $(addsuffix .pdf,$(EXAMPLES))
	@undef=$$(cat $(addsuffix .log,$(EXAMPLES)) | grep -c 'Reference .* undefined' || true); \
	 dup=$$(cat $(addsuffix .log,$(EXAMPLES)) | grep -c 'multiply defined' || true); \
	 echo "refs: $$undef undefined, $$dup defined twice"; \
	 if [ "$$undef" -gt 0 ]; then \
	     echo "refs: a reference resolved to nothing; see the example logs" >&2; exit 1; \
	 fi; \
	 if [ "$$dup" -gt 0 ]; then \
	     echo "refs: a label was defined twice; see the example logs" >&2; exit 1; \
	 fi

# The package says nothing about a document it has no reason to complain about, so
# anything it does say here is a defect: a language it has no definitions for, a
# tex4ht run without its configuration, PDF management where it costs the lists.
# Those warnings exist to be read by someone, and a suite that lets them pass is a
# suite that reads nothing.
log-checks: $(addsuffix .pdf,$(EXAMPLES))
	@warned=$$(cat $(addsuffix .log,$(EXAMPLES)) \
	     | grep -c 'Package regulatory\(-[a-z]*\)\? Warning' || true); \
	 echo "log: $$warned package warnings"; \
	 if [ "$$warned" -gt 0 ]; then \
	     echo "log: the package reported something; see the example logs" >&2; exit 1; \
	 fi

# The reader of bib files is the one place in this bundle where we own a parser,
# so it is asserted from both sides. The wording of a citation is asserted word for
# word as well: every one of these forms comes from a source that prescribes it,
# and a citation in the wrong register is a citation that fails nowhere. What it read is checked field by field --
# a field that silently did not arrive is a citation that comes out empty -- and
# the two files that are wrong on purpose have to make the run fail. A reader that
# skips what it cannot read is worse than no reader.
SOURCE_EXPECT = 'SRC bw6 type = regeling' \
                'SRC bw6 citeertitel = Burgerlijk Wetboek' \
                'SRC bw6 boek = 6' \
                'SRC bw6 bwbid = BWBR0005289' \
                'SRC avg type = euhandeling' \
                'SRC avg roepnaam = Algemene verordening gegevensbescherming' \
                'SRC avg pb = PbEU 2016, L 119/1' \
                'SRC uavg citeertitel = Uitvoeringswet Algemene verordening gegevensbescherming' \
                'SRC bw6 leeg = []' \
                'SRC avg bestaat' \
                'SRC onbekend ontbreekt' \
                'CITE nl-voluit = artikel 96,~tweede lid,~onderdeel~c,~van~Boek 6 van het Burgerlijk Wetboek' \
                'CITE nl-verkort = art. 6:96~lid~2~onder~c~BW' \
                'CITE eu-voluit = artikel 6,~lid~1,~punt~a),~van~de Algemene verordening gegevensbescherming' \
                'CITE eu-verkort = art. 6~lid~1~punt~a)~AVG' \
                'CITE bron-voluit = de Algemene verordening gegevensbescherming' \
                'CITE bron-verkort = AVG'

source-checks: source-example.pdf
	@missing=0; read_back=0; \
	 for want in $(SOURCE_EXPECT); do \
	     if grep -qF "$$want" source-example.log; then \
	         read_back=$$((read_back + 1)); \
	     else \
	         echo "source: not read back: $$want" >&2; missing=1; \
	     fi; \
	 done; \
	 if [ "$$missing" -gt 0 ]; then exit 1; fi; \
	 rejected=0; \
	 for bad in $(BADEXAMPLES); do \
	     if $(COMPILER) $$bad >/dev/null 2>&1; then \
	         echo "source: $$bad was accepted, and it should not be" >&2; exit 1; \
	     fi; \
	     rejected=$$((rejected + 1)); \
	 done; \
	 echo "source: $$read_back fields read back, $$rejected bad files rejected"

# A signature field is a PDF annotation over a drawn box. The box is drawn by TeX
# and shows up whatever happens; the annotation is what makes it a field, and its
# absence is invisible on paper -- it only shows when someone tries to sign. The
# example is therefore written uncompressed, so that the field can be read back
# out of the PDF here without a PDF tool.
sign-checks: sign-example.pdf
	@fields=$$(grep -ac '/FT /Sig' sign-example.pdf || true); \
	 echo "sign: $$fields signature fields"; \
	 if [ "$$fields" -lt 2 ]; then \
	     echo "sign: the box was drawn but no field was placed over it" >&2; exit 1; \
	 fi

# What a Markdown source loses when something is wrong with it, it loses quietly:
# raw TeX is typeset as its own characters, a reference that resolved to nothing
# prints two question marks, and a definition list that is declared but never
# printed leaves an empty article. None of that stops a run, so each is asserted
# on what the run leaves behind. Everything here is read from files TeX itself
# wrote, so the suite still needs nothing but a TeX installation.
md-checks: md-example.pdf
	@raw=$$(cat _markdown_md-example/*.md.tex | grep -o 'markdownRendererBackslash' | wc -l); \
	 ext=$$(cat _markdown_md-example/*.md.tex | grep -o 'markdownRendererRegulatoryLabel' | wc -l); \
	 warn=$$(grep -c 'regulatory-md Warning' md-example.log || true); \
	 echo "md: $$raw raw TeX, $$ext extension labels, $$warn module warnings"; \
	 if [ "$$raw" -gt 0 ]; then \
	     echo "md: the source still holds TeX, which is now typeset rather than obeyed" >&2; exit 1; \
	 fi; \
	 if [ "$$ext" -lt 1 ]; then \
	     echo "md: no standalone identifier was read; was the syntax extension found?" >&2; exit 1; \
	 fi; \
	 if [ "$$warn" -gt 0 ]; then \
	     echo "md: the module reported something; see md-example.log" >&2; exit 1; \
	 fi

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

# The one refers to the other, so the labels of the second have to be on disk
# before the first is converted -- the same order the PDF suite needs, for the same
# reason. Without it the references between the two documents come out as question
# marks on a first run and quietly repair themselves on a second, which is the kind
# of result that says nothing about the state of the package.
$(HTML_EXAMPLE).html: $(HTML_DEFS_EXAMPLE).html
$(HTML_MD_EXAMPLE).html: $(HTML_DEFS_EXAMPLE).html

html-checks: $(HTML_EXAMPLE).html $(HTML_DEFS_EXAMPLE).html $(HTML_MD_EXAMPLE).html
	@sections=$$(grep -o '<section' $(HTML_EXAMPLE).html | wc -l); \
	 headings=$$(grep -oE '<h[1-6]' $(HTML_EXAMPLE).html | wc -l); \
	 items=$$(grep -o 'enumitem-paras' $(HTML_EXAMPLE).html | wc -l); \
	 defs=$$(grep -o 'glo_def1' $(HTML_EXAMPLE).html | wc -l); \
	 inline=$$(grep -o "id='glo_inline'" $(HTML_DEFS_EXAMPLE).html | wc -l); \
	 deflist=$$(grep -o "dl class='description'" $(HTML_DEFS_EXAMPLE).html | wc -l); \
	 undef=$$(cat $(HTML_EXAMPLE).log $(HTML_DEFS_EXAMPLE).log $(HTML_MD_EXAMPLE).log \
	     | grep -c 'Reference .* undefined' || true); \
	 warned=$$(cat $(HTML_EXAMPLE).log $(HTML_DEFS_EXAMPLE).log $(HTML_MD_EXAMPLE).log \
	     | grep 'Package regulatory\(-[a-z]*\)\? Warning' \
	     | grep -vc 'Attachments need the PDF management' || true); \
	 labeling=$$(grep -o 'regulatory-definitions' $(HTML_EXAMPLE).html | wc -l); \
	 mdsections=$$(grep -o '<section' $(HTML_MD_EXAMPLE).html | wc -l); \
	 mditems=$$(grep -o 'enumitem-paras' $(HTML_MD_EXAMPLE).html | wc -l); \
	 mddefs=$$(grep -o "id='glo_" $(HTML_MD_EXAMPLE).html | wc -l); \
	 echo "html: $$sections sections, $$headings headings, $$items paras items, $$defs definitions, $$inline inline, $$deflist description list, $$labeling labeling list, $$undef undefined, $$warned unexpected warnings"; \
	 echo "html md: $$mdsections sections, $$mditems paras items, $$mddefs definitions"; \
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
	 if [ "$$undef" -gt 0 ]; then \
	     echo "html: a reference resolved to nothing; are the zref labels written?" >&2; exit 1; \
	 fi; \
	 if [ "$$warned" -gt 0 ]; then \
	     echo "html: the package reported something beyond the attachments it cannot embed" >&2; exit 1; \
	 fi; \
	 if [ "$$labeling" -lt 1 ]; then \
	     echo "html: the labeling style produced no list of its own" >&2; exit 1; \
	 fi; \
	 if [ "$$mdsections" -lt 1 ] || [ "$$mditems" -lt 1 ] || [ "$$mddefs" -lt 1 ]; then \
	     echo "html: the Markdown example lost its structure or its definitions" >&2; exit 1; \
	 fi; \
	 if [ "$$deflist" -lt 1 ]; then \
	     echo "html: the definitions are not a list; did the defstyle survive?" >&2; exit 1; \
	 fi

# Four steps, one more than the PDF needs: the definitions come from bib2gls,
# which needs the aux of a first run, and the labels of the examples settle a run
# later than they do under pdflatex.
%.html: %.tex $(PROJECT)/tex/regulatory.4ht
	TEXMFHOME=$(PROJECT) $(MAKE4HT) $<
	$(BIB2GLS) $*
	TEXMFHOME=$(PROJECT) $(MAKE4HT) $<
	TEXMFHOME=$(PROJECT) $(MAKE4HT) $<

# The Markdown example declares its own definitions, so bib2gls has nothing to
# read here either; -l converts with lualatex, which is what lets the markdown
# package work without shell escape.
$(HTML_MD_EXAMPLE).html: $(HTML_MD_EXAMPLE).tex $(PROJECT)/tex/regulatory.4ht \
                         $(PROJECT)/tex/regulatory-syntax.lua
	TEXMFHOME=$(PROJECT) $(MAKE4HT) -l $<
	TEXMFHOME=$(PROJECT) $(MAKE4HT) -l $<

# Clears the test directory itself, where `all' builds the examples that the
# documentation lists and attaches. Keeps out/ standing: the suites build there,
# and their results are meant to survive a documentation build so they can be
# looked at afterwards.
clean-examples:
	@cd $(TESTDIR) && for example in $(EXAMPLES) $(BADEXAMPLES); do latexmk -f -c $$example; done
	rm -rf $(TESTDIR)/_markdown_*
	rm -f $(TESTDIR)/*.glstex $(TESTDIR)/*.luabridge.lua $(TESTDIR)/conformance.check.tex
	rm -f $(TESTDIR)/*.html $(TESTDIR)/*.css $(TESTDIR)/*.4ct $(TESTDIR)/*.4tc
	rm -f $(TESTDIR)/*.idv $(TESTDIR)/*.lg $(TESTDIR)/*.tmp $(TESTDIR)/*.xref

# The same, but the PDF files go too. The documentation asks for this before it
# builds the examples: with the PDF files still standing make considers them up to
# date and rebuilds nothing, and the manual would read no aux file at all.
clean-all-examples:
	@cd $(TESTDIR) && for example in $(EXAMPLES) $(BADEXAMPLES); do latexmk -f -C $$example; done
	@$(MAKE) -f $(TESTDIR)/Makefile clean-examples

# Both places: the examples and every build directory under out/.
clean: clean-examples
	rm -rf $(OUT)

clean-all: clean-all-examples
	rm -rf $(OUT)
