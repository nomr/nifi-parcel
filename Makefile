
VERSION=1.4.0

nifi-$(VERSION)-bin.tar.gz:
	wget http://apache.claz.org/nifi/$(VERSION)/nifi-$(VERSION)-bin.tar.gz

nifi-$(VERSION): nifi-$(VERSION)-bin.tar.gz
	tar -xvf nifi-$(VERSION)-bin.tar.gz
