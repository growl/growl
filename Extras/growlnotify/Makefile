DESTDIR =

DEFAULT_BUILDSTYLE=Deployment

BUILDSTYLE?=$(DEFAULT_BUILDSTYLE)

all:
	xcodebuild -alltargets -buildstyle $(BUILDSTYLE) build

clean:
	xcodebuild -alltargets clean

install:
	xcodebuild -alltargets -buildstyle $(BUILDSTYLE) install DSTROOT=$(DESTDIR)
	mkdir -p $(DESTDIR)/opt/growl/man/man1
	cp growlnotify.1 $(DESTDIR)/opt/growl/man/man1
