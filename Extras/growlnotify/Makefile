DESTDIR=/

DEFAULT_BUILDSTYLE=Deployment

BUILDSTYLE?=$(DEFAULT_BUILDSTYLE)

all:
	xcodebuild -alltargets -buildstyle $(BUILDSTYLE) build

clean:
	xcodebuild -alltargets clean

install:
	xcodebuild -alltargets -buildstyle $(BUILDSTYLE) install DSTROOT=$(DESTDIR)
	mkdir -p $(DESTDIR)/usr/local/share/man/man1/
	cp growlnotify.1 /usr/local/share/man/man1/
