CONTRIBUTION := regulatory
VERSION := $(shell git describe --tags --always)
TAR_BALL := $(CONTRIBUTION)-$(VERSION).tar.gz

DTX_SOURCES := $(wildcard src/*.dtx)
INS_SOURCE := src/$(CONTRIBUTION).ins
GENERATED := tex/regulatory.sty tex/regulatory-struct.sty tex/regulatory-defs.sty \
             tex/regulatory-ref.sty \
             tex/regulatory-attachments.sty tex/regulatory-md.sty \
             tex/regulatory-sign.sty tex/regulatory-sources.sty \
             tex/regulatory.4ht

# The language definition files are written by hand, so they are copied rather
# than generated. Translators work in src/, the package reads them from tex/.
# The Markdown syntax extension is copied for the same reason: it is Lua read by
# the markdown package, not TeX, and it is documented from its own comments with
# comment2tex rather than through docstrip.
COPIED_SOURCES := $(wildcard src/*.def) $(wildcard src/*.lua)
COPIED_FILES := $(patsubst src/%,tex/%,$(COPIED_SOURCES))

.PHONY: package generate build-docs test conformance conformance-check conformance-stale install-hooks clean

package: $(TAR_BALL)
	@echo "Created $(TAR_BALL)"

# One docstrip run writes every generated file, and the rule that does so belongs
# to the first of them, so make cannot make any other one on its own: a file that
# went missing would stay missing while make reported there was nothing to do.
# Dropping the first file when any of them is absent puts the whole set back.
generate:
	@for file in $(GENERATED); do test -f $$file || rm -f tex/regulatory.sty; done
	@$(MAKE) $(GENERATED) $(COPIED_FILES)

# Docstrip writes every generated file in one run, so the remaining files
# are made along with the first one.
tex/regulatory.sty: $(DTX_SOURCES) $(INS_SOURCE)
	mkdir -p tex
	cd src && luatex --interaction=nonstopmode $(CONTRIBUTION).ins

$(filter-out tex/regulatory.sty,$(GENERATED)): tex/regulatory.sty

tex/%.def: src/%.def
	mkdir -p tex
	cp $< $@

tex/%.lua: src/%.lua
	mkdir -p tex
	cp $< $@

# Clears the examples afterwards, but not test/out: the suites build there and
# their results are meant to stay available for inspection.
build-docs: generate
	$(MAKE) -C doc -f Makefile all clean
	$(MAKE) -C test -f Makefile clean-examples

# Runs every example of test/ through every engine this package supports, and the
# HTML conversion, each suite in a directory of its own and all of them side by
# side. Add WITH_CONFORMANCE=1 to run the PDF standards along with them; that one
# needs Docker, which is why it is not there by default.
test: generate
	$(MAKE) -C test -f Makefile test

# Validates the examples against the PDF standards they can carry and writes
# test/conformance.tex, which the manual reads and which is kept in the
# repository. Needs Docker, so it is not part of the build and not run on CI.
conformance: generate
	$(MAKE) -C test -f Makefile conformance

# Fails when that table no longer matches what veraPDF says. Rebuilds and
# revalidates everything, so it takes minutes.
conformance-check: generate
	$(MAKE) -C test -f Makefile conformance-check

# Fails when the sources changed since the table was made. Costs a hash, so this
# is the one a pre-commit hook can afford.
conformance-stale:
	$(MAKE) -C test -f Makefile conformance-stale

# Makes the pre-commit hook of .githooks run conformance-check whenever the
# package or the examples change. Undo with: git config --unset core.hooksPath
install-hooks:
	git config core.hooksPath .githooks
	@echo "pre-commit hook installed"

$(TAR_BALL): build-docs
	tar --transform 's,^\.,regulatory,' -czvf $(TAR_BALL) --exclude 'Makefile' --exclude '*.log' --exclude '_markdown*' --exclude 'out' ./README.md ./doc ./src ./test ./tex

clean:
	$(MAKE) -C doc -f Makefile clean-all
	$(MAKE) -C test -f Makefile clean-all
	rm -f $(GENERATED) $(COPIED_FILES) src/*.log
	rm -f $(TAR_BALL)
