DEFAULT_BUILDCONFIGURATION=Deployment

BUILDCONFIGURATION?=$(DEFAULT_BUILDCONFIGURATION)

DESTDIR=/Library/Spotlight/GrowlImpoter.mdimporter

all:
	xcodebuild -alltargets -configuration $(BUILDCONFIGURATION) build

install:
	rm -rf $(DESTDIR)
	cp -R build/GrowlImporter.mdimporter $(DESTDIR)
	/usr/bin/mdimport -r $(DESTDIR)

clean:
	xcodebuild -alltargets clean
