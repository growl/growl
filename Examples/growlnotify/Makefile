all:
	xcodebuild -alltargets -buildstyle Deployment build

install:
	xcodebuild -alltargets -buildstyle Deployment install DSTROOT=/
	cp growlnotify.1 /usr/local/man/man1/
