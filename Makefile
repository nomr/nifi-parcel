
CSD_VERSION=0.0.1
NIFI_VERSION=1.4.0
BUILD_NUMBER=0
PARCEL_VERSION=$(NIFI_VERSION)-$(BUILD_NUMBER)
DISTRO=el7

.INTERMEDIATE:
.DELETE_ON_ERROR:
.PHONY: release

all:

release: release/manifest.json
	ghr -u nomr -r nifi-parcel

release/manifest.json: release/NIFI-$(PARCEL_VERSION)-$(DISTRO).parcel
	python make_manifest.py release

release/NIFI-$(PARCEL_VERSION)-$(DISTRO).parcel:  release/NIFI-$(PARCEL_VERSION)/meta
	tar zcvf $@ --owner root --group=root -C release NIFI-$(PARCEL_VERSION)
	java -jar validator.jar -f $@
	rm -rf release/NIFI-$(PARCEL_VERSION)

release/NIFI-$(PARCEL_VERSION)/meta: parcel validator.jar release/NIFI-$(PARCEL_VERSION)
	mkdir -p $@
	cat parcel/parcel.json | jq ".version=\"$(PARCEL_VERSION)\"" > $@/parcel.json
	java -jar validator.jar -p $@/parcel.json || (rm -rf $@ && false)
	cp parcel/nifi_env.sh $@

release/NIFI-$(PARCEL_VERSION): nifi-$(NIFI_VERSION)-bin.tar.gz
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

nifi-$(NIFI_VERSION)-bin.tar.gz:
	wget http://apache.claz.org/nifi/$(NIFI_VERSION)/nifi-$(NIFI_VERSION)-bin.tar.gz

nifi16.ico:
	wget https://nifi.apache.org/assets/images/nifi16.ico
