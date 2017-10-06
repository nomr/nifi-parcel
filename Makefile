
VERSION=1.4.0
BUILD_NUMBER=1
DISTRO=el7

.INTERMEDIATE: nifi-$(VERSION)-bin.tar.gz
.DELETE_ON_ERROR:

NIFI-$(VERSION)-$(BUILD_NUMBER)-$(DISTRO).parcel: NIFI-$(VERSION)-$(BUILD_NUMBER)
	tar zcvf NIFI-$(VERSION)-$(BUILD_NUMBER)-$(DISTRO).parcel $< --owner root --group=root
	java -jar validator.jar -f $@
	rm -rf $<

NIFI-$(VERSION)-$(BUILD_NUMBER): nifi-$(VERSION) validator.jar
	mkdir -p $@/meta
	cat parcel/parcel.json | jq ".version=\"$(VERSION)-$(BUILD_NUMBER)\"" > $@/meta/parcel.json
	cp parcel/nifi_env.sh $@/meta
	mv nifi-$(VERSION)/lib nifi-$(VERSION)/docs nifi-$(VERSION)/LICENSE nifi-$(VERSION)/NOTICE $@ && rm -rf nifi-$(VERSION)
	java -jar validator.jar -d $@ || rm -rf $@

nifi-$(VERSION)-bin.tar.gz:
	wget http://apache.claz.org/nifi/$(VERSION)/nifi-$(VERSION)-bin.tar.gz

nifi-$(VERSION): nifi-$(VERSION)-bin.tar.gz
	tar -xvf nifi-$(VERSION)-bin.tar.gz

validator.jar:
	cd tools/cm_ext && mvn install && cd -
	ln -s tools/cm_ext/validator/target/validator.jar .
