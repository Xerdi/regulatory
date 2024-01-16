CONTRIBUTION := regulatory
VERSION := $(shell git describe --tags --always)
TAR_BALL := $(CONTRIBUTION)-$(VERSION).tar.gz

package: $(TAR_BALL)
	@echo "Created $(TAR_BALL)"

build-docs: remove-docs
	$(MAKE) -C doc -f Makefile all

extra-docs: remove-docs
	$(MAKE) -C doc -f Makefile extra

clean-docs:
	cd doc && $(foreach file,$(wildcard doc/*.pdf),latexmk -c $(shell basename $(file));)
	rm -f doc/*.glg doc/*.atfi doc/*.glstex

remove-docs:
	cd doc && $(foreach file,$(wildcard doc/*.pdf),latexmk -C $(shell basename $(file));)
	rm -f doc/*.glg doc/*.atfi doc/*.glstex

$(TAR_BALL): build-docs clean-docs
	tar --transform 's,^\.,regulatory,' -czvf $(TAR_BALL) --exclude 'Makefile' --exclude '_markdown*' ./README.md ./doc ./tex