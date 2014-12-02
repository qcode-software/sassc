NAME=sassc
DPKG_NAME=$(NAME)-$(VERSION)
RELEASE=0
TMP_DIR=/tmp/$(NAME)
LIB_DIR=/usr/local/lib
INSTALL_DIR =/usr/local/bin
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
	mkdir $(TMP_DIR)/libsass
	curl --fail -K ~/.curlrc_github -L -o v$(VERSION).tar.gz https://api.github.com/repos/qcode-software/libsass/tarball/v$(VERSION)
	tar --strip-components=1 -xzvf v$(VERSION).tar.gz -C $(TMP_DIR)/libsass

	fakeroot checkinstall -D --deldoc --backup=no --install=no --pkgname=$(DPKG_NAME) --pkgversion=$(VERSION) --pkgrelease=$(RELEASE) --pkglicense="PUBLIC" -A all -y --maintainer $(MAINTAINER) --reset-uids=yes --requires "libsass" --replaces none --conflicts none make install

install: $(OBJECTS) $(LIB_DIR)/libsass.so
	cd $(TMP_DIR) && gcc -O2 -o $(INSTALL_DIR)/$(NAME)  $^ 

%.o: %.c
	cd $(TMP_DIR) && gcc -c -Wall -O2 -I $(TMP_DIR)/libsass $< -o $@

upload: check-version
	scp $(DPKG_NAME)_$(VERSION)-$(RELEASE)_all.deb "$(REMOTE_USER)@$(REMOTE_HOST):$(REMOTE_DIR)/debs"	
	ssh $(REMOTE_USER)@$(REMOTE_HOST) reprepro -b $(REMOTE_DIR) includedeb squeeze $(REMOTE_DIR)/debs/$(DPKG_NAME)_$(VERSION)-$(RELEASE)_all.deb
	ssh $(REMOTE_USER)@$(REMOTE_HOST) reprepro -b $(REMOTE_DIR) includedeb wheezy $(REMOTE_DIR)/debs/$(DPKG_NAME)_$(VERSION)-$(RELEASE)_all.deb

clean: 
	rm -f $(DPKG_NAME)*_all.deb v$(VERSION).tar.gz

.PHONY: all

check-version:
ifndef VERSION
    $(error VERSION is undefined. Usage make VERSION=x.x.x LIBSASS_REPO_PATH=x/x/x)
endif
