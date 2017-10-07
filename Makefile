
CSD_VERSION=0.0.1
PARCEL_VERSION=1.4.0
DISTRO=el7

.INTERMEDIATE: nifi-$(PARCEL_VERSION)-bin.tar.gz nifi-$(PARCEL_VERSION)/meta nifi16.ico
.DELETE_ON_ERROR:
.PHONY: parcels

all:

NIFI-$(CSD_VERSION).jar: csd
	java -jar validator.jar -s csd/descriptor/service.sdl
	jar -cf $@ -C $< .

parcels: parcels/manifest.json
	cd parcels
	python -m SimpleHTTPServer 8080

parcels/manifest.json: parcels/nifi-$(PARCEL_VERSION)-$(DISTRO).parcel
	python make_manifest.py parcels

parcels/nifi-$(PARCEL_VERSION)-$(DISTRO).parcel: nifi-$(PARCEL_VERSION)-bin.tar.gz nifi-$(PARCEL_VERSION)/meta
	mkdir -p target
	gunzip nifi-$(PARCEL_VERSION)-bin.tar.gz
	tar rvf nifi-$(PARCEL_VERSION)-bin.tar --owner root --group=root nifi-$(PARCEL_VERSION)
	gzip -1 nifi-$(PARCEL_VERSION)-bin.tar
	mv nifi-$(PARCEL_VERSION)-bin.tar.gz $@
	java -jar validator.jar -f $@

nifi-$(PARCEL_VERSION)/meta: parcel validator.jar
	mkdir -p $@
	cat parcel/parcel.json | jq ".version=\"$(PARCEL_VERSION)\"" > $@/parcel.json
	java -jar validator.jar -p $@/parcel.json || (rm -rf $@ && false)
	cp parcel/nifi_env.sh $@

csd/images/icon.png:
	convert nifi16.ico $@

# Remote dependencies
validator.jar:
	cd tools/cm_ext && mvn install && cd -
	ln -s tools/cm_ext/validator/target/validator.jar .

make_manifest.py:
	ln -s tools/cm_ext/make_manifest/make_manifest.py

nifi-$(PARCEL_VERSION)-bin.tar.gz:
	wget http://apache.claz.org/nifi/$(PARCEL_VERSION)/nifi-$(PARCEL_VERSION)-bin.tar.gz

nifi16.ico:
	wget https://nifi.apache.org/assets/images/nifi16.ico
