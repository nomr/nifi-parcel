
VERSION=1.4.0
DISTRO=el7

.INTERMEDIATE: nifi-$(VERSION)-bin.tar.gz nifi16.ico
.DELETE_ON_ERROR:

all:

nifi-$(VERSION)-$(DISTRO).parcel: nifi-$(VERSION)-bin.tar.gz nifi-$(VERSION)/meta
	gunzip nifi-$(VERSION)-bin.tar.gz
	tar rvf nifi-$(VERSION)-bin.tar --owner root --group=root nifi-$(VERSION)
	gzip -1 nifi-$(VERSION)-bin.tar
	mv nifi-$(VERSION)-bin.tar.gz $@
	java -jar validator.jar -f $@

nifi-$(VERSION)/meta: parcel validator.jar
	mkdir -p $@
	cat parcel/parcel.json | jq ".version=\"$(VERSION)\"" > $@/parcel.json
	java -jar validator.jar -p $@/parcel.json || (rm -rf $@ && false)
	cp parcel/nifi_env.sh $@

NIFI-$(VERSION)-$(BUILD_NUMBER): nifi-$(VERSION) validator.jar
	mv nifi-$(VERSION)/lib nifi-$(VERSION)/docs nifi-$(VERSION)/LICENSE nifi-$(VERSION)/NOTICE $@ 

csd/images/icon.png:
	convert nifi16.ico $@

# Remote dependencies
validator.jar:
	cd tools/cm_ext && mvn install && cd -
	ln -s tools/cm_ext/validator/target/validator.jar .

nifi-$(VERSION)-bin.tar.gz:
	wget http://apache.claz.org/nifi/$(VERSION)/nifi-$(VERSION)-bin.tar.gz

nifi16.ico:
	wget https://nifi.apache.org/assets/images/nifi16.ico


