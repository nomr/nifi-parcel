TAG:=$(shell git describe --tags | sed -e 's/^v//')
TAG_DIST=$(shell echo $(TAG) | sed -r -e 's/.*-([[:digit:]]+)-g.*/\1/')
TAG_HASH=$(shell echo $(TAG) | sed -r -e 's/^.*(g[0-9a-f]+|$$)/\1/')
NIFI_VERSION=$(shell echo $(TAG) | sed -r -e 's/\+nifi.*//')
VERSION=$(subst +,-,$(TAG))

ifeq ($(TRAVIS), true)
  DISTROS=el7
else
  DISTROS=el7
endif
PARCELS=$(foreach DISTRO,$(DISTROS),NIFI-$(VERSION)-$(DISTRO).parcel)

.INTERMEDIATE: %-SHA256
.DELETE_ON_ERROR:
.PHONY: release

all: info release

info:
	@echo '       Git Tag: $(TAG)'
	@[ ! -z $(TAG) ]
	@echo '      Tag dist: $(TAG_DIST)'
	@echo '      Tag hash: $(TAG_HASH)'
	@echo '  NiFi version: $(NIFI_VERSION)'
	@echo 'Parcel version: $(VERSION)'
	@echo '       Parcels: $(PARCELS)'

clean:
	rm -rf release NIFI-*

release: $(foreach PARCEL,$(PARCELS),release/$(PARCEL)) release/manifest.json

%/manifest.json: make_manifest.py
	@mkdir -p $(shell dirname $@)
	python make_manifest.py $(shell dirname $@)

NIFI-$(VERSION)-%.parcel: NIFI-$(VERSION).parcel
	@mkdir -p $(shell dirname $@)
	ln $< $@
	java -jar validator.jar -f $@

NIFI-$(VERSION).parcel: NIFI-$(VERSION)/meta
	@mkdir -p $(shell dirname $@)
	tar zcvf $@ --owner root --group=root $(shell dirname $<)

NIFI-$(VERSION)/meta: NIFI-$(VERSION) meta validator.jar 
	@mkdir $@
	cp meta/nifi_env.sh $@
	cat meta/parcel.json | jq ".version=\"$(VERSION)\"" > $@/parcel.json
	java -jar validator.jar -p $@/parcel.json || (rm -rf $@ && false)

NIFI-$(VERSION): nifi-$(NIFI_VERSION) nifi-toolkit-$(NIFI_VERSION)
	rm -rf $@
	mkdir -p $@/lib
	mv nifi-$(NIFI_VERSION) $@/lib/nifi
	mv nifi-toolkit-$(NIFI_VERSION) $@/lib/nifi-toolkit

# Remote dependencies
validator.jar:
	cd tools/cm_ext && mvn -q install && cd -
	ln tools/cm_ext/validator/target/validator.jar .

make_manifest.py:
	ln tools/cm_ext/make_manifest/make_manifest.py

nifi-$(NIFI_VERSION)-bin.tar.gz: nifi-$(NIFI_VERSION)-bin.tar.gz-SHA256
	wget 'https://www.apache.org/dyn/mirrors/mirrors.cgi?action=download&filename=nifi/$(NIFI_VERSION)/$@' -O $@
	touch $@
	sha256sum -c $<

nifi-toolkit-$(NIFI_VERSION)-bin.tar.gz: nifi-toolkit-$(NIFI_VERSION)-bin.tar.gz-SHA256
	wget 'https://www.apache.org/dyn/mirrors/mirrors.cgi?action=download&filename=nifi/$(NIFI_VERSION)/$@' -O $@
	touch $@
	sha256sum -c $<


# Implicit rules
%-SHA256: SHA256SUMS
	grep $(subst -SHA256,,$@) SHA256SUMS > $@

%: %-bin.tar.gz
	tar -zxvf $<
	find $@/lib -type f -exec chmod o+r {} \;
