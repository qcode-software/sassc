NAME=sassc
DPKG_NAME=$(NAME)-$(VERSION)
LIBSASS_VERSION=$(VERSION)
RELEASE=0
TMP_DIR=/tmp/$(NAME)
LIBSASS_DIR=$(TMP_DIR)/libsass
INSTALL_DIR=/usr/local/bin
MAINTAINER=hackers@qcode.co.uk
REMOTE_USER=debian.qcode.co.uk
REMOTE_HOST=debian.qcode.co.uk
REMOTE_DIR=debian.qcode.co.uk

SOURCES = $(TMP_DIR)/sassc.c
OBJECTS = $(SOURCES:.c=.o)

all: check-version package upload clean

package: check-version
	# Copy sassc files to pristine temporary directory
	rm -rf $(TMP_DIR)
	mkdir $(TMP_DIR)
	curl --fail -K ~/.curlrc_github -L -o v$(VERSION).tar.gz https://api.github.com/repos/qcode-software/$(NAME)/tarball/v$(VERSION)
	tar --strip-components=1 -xzvf v$(VERSION).tar.gz -C $(TMP_DIR)

	# Copy libsass files to pristine temporary directory
	mkdir $(LIBSASS_DIR)
	curl --fail -K ~/.curlrc_github -L -o v$(VERSION).tar.gz https://api.github.com/repos/qcode-software/libsass/tarball/v$(VERSION)
	tar --strip-components=1 -xzvf v$(LIBSASS_VERSION).tar.gz -C $(LIBSASS_DIR)

	fakeroot checkinstall -D --deldoc --backup=no --install=no --pkgname=$(DPKG_NAME) --pkgversion=$(VERSION) --pkgrelease=$(RELEASE) --pkglicense="PUBLIC" -A all -y --maintainer $(MAINTAINER) --reset-uids=yes --requires "libsass-$(LIBSASS_VERSION)" --replaces none --conflicts none make install

install: $(OBJECTS) /usr/local/lib/libsass.so
	gcc -O2 -o $(INSTALL_DIR)/$(NAME)  $^

/usr/local/lib/libsass.so:
	$(error Missing /usr/local/lib/libsass.so. Please install libsass-x.x.x)

%.o: %.c
	gcc -c -Wall -O2 -I $(LIBSASS_DIR) $< -o $@

upload: check-version
	scp $(DPKG_NAME)_$(VERSION)-$(RELEASE)_all.deb "$(REMOTE_USER)@$(REMOTE_HOST):$(REMOTE_DIR)/debs"	
	ssh $(REMOTE_USER)@$(REMOTE_HOST) reprepro -b $(REMOTE_DIR) includedeb squeeze $(REMOTE_DIR)/debs/$(DPKG_NAME)_$(VERSION)-$(RELEASE)_all.deb
	ssh $(REMOTE_USER)@$(REMOTE_HOST) reprepro -b $(REMOTE_DIR) includedeb wheezy $(REMOTE_DIR)/debs/$(DPKG_NAME)_$(VERSION)-$(RELEASE)_all.deb

clean: 
	rm -rf $(DPKG_NAME)*_all.deb v$(VERSION).tar.gz /tmp/$(NAME)

.PHONY: all

check-version:
ifndef VERSION
    $(error VERSION is undefined. Usage make VERSION=x.x.x)
endif
