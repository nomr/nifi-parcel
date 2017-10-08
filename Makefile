
CSD_VERSION=0.0.1

VERSION:=$(shell git tag | tail -1)
NIFI_VERSION=$(shell echo $(VERSION) | sed -e 's/-.*$$//')
BUILD_NUMBER=$(shell echo $(VERSION) | sed -e 's/^.*-//')

DISTRO=el7

.INTERMEDIATE: %-SHA256
.DELETE_ON_ERROR:
.PHONY: release

all: version release

version:
	@echo 'Parcel version: $(VERSION)'
	@echo '  NiFi version: $(NIFI_VERSION)'
	@echo '  Build number: $(BUILD_NUMBER)'

release: release/manifest.json

release/manifest.json: release/NIFI-$(VERSION)-$(DISTRO).parcel
	python make_manifest.py release

release/NIFI-$(VERSION)-%.parcel:  release/NIFI-$(VERSION)/meta
	tar zcvf $@ --owner root --group=root -C release NIFI-$(VERSION)
	java -jar validator.jar -f $@
	rm -rf release/NIFI-$(VERSION)

release/NIFI-$(VERSION)/meta: meta validator.jar release/NIFI-$(VERSION)
	mkdir -p $@
	cat meta/parcel.json | jq ".version=\"$(VERSION)\"" > $@/parcel.json
	java -jar validator.jar -p $@/parcel.json || (rm -rf $@ && false)
	cp meta/nifi_env.sh $@

release/NIFI-$(VERSION): nifi-$(NIFI_VERSION)-bin.tar.gz
	mkdir -p release
	tar -zxvf $< -C release
	mv release/nifi-$(NIFI_VERSION) $@


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
	sha256sum -c $<

nifi16.ico:
	wget https://nifi.apache.org/assets/images/nifi16.ico

# Auto Rules
%-SHA256:
	grep $(subst -SHA256,,$@) SHA256SUMS > $@
