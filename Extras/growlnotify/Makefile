DESTDIR=/
destroot=$(DESTDIR:/=)/

DEFAULT_BUILDCONFIGURATION=Deployment

BUILDCONFIGURATION?=$(DEFAULT_BUILDCONFIGURATION)

all:
	xcodebuild -alltargets -configuration $(BUILDCONFIGURATION) build

clean:
	xcodebuild -alltargets clean

install:
	xcodebuild -alltargets -configuration $(BUILDCONFIGURATION) install DSTROOT=$(destroot)
	mkdir -p $(destroot)usr/local/share/man/man1/
	cp growlnotify.1 $(destroot)usr/local/share/man/man1/
	gzip -f $(destroot)usr/local/share/man/man1/growlnotify.1
