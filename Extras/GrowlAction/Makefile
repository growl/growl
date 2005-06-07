DEFAULT_BUILDCONFIGURATION=Deployment

BUILDCONFIGURATION?=$(DEFAULT_BUILDCONFIGURATION)

DESTDIR="/Library/Automator/Show Growl Notification.action"

all:
	xcodebuild -alltargets -configuration $(BUILDCONFIGURATION) build

install:
	-rm -rf $(DESTDIR)
	mkdir -p /Library/Automator
	cp -R "build/Show Growl Notification.action" $(DESTDIR)

clean:
	xcodebuild -alltargets clean
