DEFAULT_BUILDSTYLE=Deployment

BUILDSTYLE?=$(DEFAULT_BUILDSTYLE)

all:
	xcodebuild -alltargets -buildstyle $(BUILDSTYLE) build

clean:
	xcodebuild -alltargets clean

install:
	xcodebuild -alltargets -buildstyle $(BUILDSTYLE) install DSTROOT=/
	cp growlnotify.1 /usr/local/man/man1/
