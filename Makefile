CONTRIBUTION := regulatory
VERSION := $(shell git describe --tags --always)
TAR_BALL := $(CONTRIBUTION)-$(VERSION).tar.gz

package: $(TAR_BALL)
	@echo "Created $(TAR_BALL)"

build-docs:
	$(MAKE) -C doc -f Makefile all clean

extra-docs:
	$(MAKE) -C doc -f Makefile extra clean

$(TAR_BALL): build-docs
	tar --transform 's,^\.,regulatory,' -czvf $(TAR_BALL) --exclude 'Makefile' --exclude '_markdown*' ./README.md ./doc ./tex