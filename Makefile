
CSD_VERSION=0.0.1

#DISTROS=el6 el7 trusty wheezy
DISTROS=el7

VERSION:=$(shell git tag | tail -1)
NIFI_VERSION=$(shell echo $(VERSION) | sed -e 's/-.*$$//')
BUILD_NUMBER=$(shell echo $(VERSION) | sed -e 's/^.*-//')

PARCELS=$(foreach DISTRO,$(DISTROS),NIFI-$(VERSION)-$(DISTRO).parcel)

.INTERMEDIATE: %-SHA256
.DELETE_ON_ERROR:
.PHONY: release

all: info release

info:
	@echo 'Parcel version: $(VERSION)'
	@[ ! -z $(VERSION) ]
	@echo '  NiFi version: $(NIFI_VERSION)'
	@echo '  Build number: $(BUILD_NUMBER)'
	@echo '       Parcels: $(PARCELS)'

clean:
	rm -rf release NIFI-$(VERSION) NIFI-$(VERSION).parcel

release: release/manifest.json

%/manifest.json: $(foreach PARCEL,$(PARCELS),%/$(PARCEL))
	mkdir -p $(shell dirname $@)
	python make_manifest.py $(shell dirname $@)

NIFI-$(VERSION)-%.parcel: NIFI-$(VERSION).parcel
	mkdir -p $(shell dirname $@)
	ln $< $@
	java -jar validator.jar -f $@

NIFI-$(VERSION).parcel: NIFI-$(VERSION)/meta
	mkdir -p $(shell dirname $@)
	tar zcvf $@ --owner root --group=root $(shell dirname $<)

NIFI-$(VERSION)/meta: NIFI-$(VERSION) meta validator.jar 
	mkdir $@
	cp meta/nifi_env.sh $@
	cat meta/parcel.json | jq ".version=\"$(VERSION)\"" > $@/parcel.json
	java -jar validator.jar -p $@/parcel.json || (rm -rf $@ && false)

NIFI-$(VERSION): nifi-$(NIFI_VERSION)-bin.tar.gz
	rm -rf $@
	tar -zxvf $<
	mv nifi-$(NIFI_VERSION) $@


csd/images/icon.png:
	convert nifi16.ico $@

# Remote dependencies
ghr:
	wget https://github.com/tcnksm/ghr/releases/download/v0.5.4/ghr_v0.5.4_linux_amd64.zip -O ghr.zip
	unzip ghr.zip
	rm ghr.zip

gh-release:
	wget https://github.com/progrium/gh-release/releases/download/v2.2.1/gh-release_2.2.1_linux_x86_64.tgz -O gh-release.tgz
	tar -xvf gh-release.tgz
	rm gh-release.tgz

validator.jar:
	cd tools/cm_ext && mvn install && cd -
	ln -s tools/cm_ext/validator/target/validator.jar .

make_manifest.py:
	ln -s tools/cm_ext/make_manifest/make_manifest.py

nifi-$(NIFI_VERSION)-bin.tar.gz: nifi-$(NIFI_VERSION)-bin.tar.gz-SHA256
	wget http://apache.claz.org/nifi/$(NIFI_VERSION)/nifi-$(NIFI_VERSION)-bin.tar.gz
	touch $@
	sha256sum -c $<

nifi16.ico:
	wget https://nifi.apache.org/assets/images/nifi16.ico

# Auto Rules
%-SHA256: SHA256SUMS
	grep $(subst -SHA256,,$@) SHA256SUMS > $@
