PLUGINS_DIR=$(HOME)/Library/Application Support/Growl/Plugins
BUILD_DIR=build
NSLOGGING_NAME=NSLogging.growlView
NSLOGGING_BUILD=$(BUILD_DIR)/$(NSLOGGING_NAME)
NSLOGGING_PATH=$(PLUGINS_DIR)/$(NSLOGGING_NAME)
SMOKE_NAME=Smoke.growlView
SMOKE_BUILD=$(BUILD_DIR)/$(SMOKE_NAME)
SMOKE_PATH=$(PLUGINS_DIR)/$(SMOKE_NAME)
MAILME_NAME=MailMe.growlView
MAILME_BUILD=$(BUILD_DIR)/$(MAILME_NAME)
MAILME_PATH=$(PLUGINS_DIR)/$(MAILME_NAME)
MUSICVIDEO_NAME=MusicVideo.growlView
MUSICVIDEO_BUILD=$(BUILD_DIR)/$(MUSICVIDEO_NAME)
MUSICVIDEO_PATH=$(PLUGINS_DIR)/$(MUSICVIDEO_NAME)

PREFERENCEPANES_DIR=$(HOME)/Library/PreferencePanes
GROWL_PREFPANE=Growl.prefPane
GROWL_HELPER_APP=$(PREFERENCEPANES_DIR)/$(GROWL_PREFPANE)/Contents/Resources/GrowlHelperApp.app

DEFAULT_BUILDSTYLE=Deployment
#DEFAULT_BUILDSTYLE=Development

CP=ditto --rsrc
RM=rm

.PHONY : all nslogging bezel smoke mailme musicvideo clean clean-nslogging clean-bezel clean-smoke clean-mailme clean-musicvideo install install-nslogging install-mailme uninstall uninstall-nslogging uninstall-smoke uninstall-mailme uninstall-musicvideo

all:
	xcodebuild -alltargets -buildstyle $(DEFAULT_BUILDSTYLE) build

nslogging:
	xcodebuild -target NSLogging -buildstyle $(DEFAULT_BUILDSTYLE) build

bezel:
	xcodebuild -target Bezel -buildstyle $(DEFAULT_BUILDSTYLE) build

smoke:
	xcodebuild -target Smoke -buildstyle $(DEFAULT_BUILDSTYLE) build

mailme:
	xcodebuild -target MailMe -buildstyle $(DEFAULT_BUILDSTYLE) build

musicvideo:
	xcodebuild -target MusicVideo -buildstyle $(DEFAULT_BUILDSTYLE) build

clean:
	xcodebuild -alltargets clean

clean-nslogging:
	xcodebuild -target NSLogging clean

clean-bezel:
	xcodebuild -target Bezel clean

clean-smoke:
	xcodebuild -target Smoke clean

clean-mailme:
	xcodebuild -target MailMe clean

clean-musicvideo:
	xcodebuild -target MusicVideo clean

install:
	killall GrowlHelperApp || true
	-$(RM) -rf "$(NSLOGGING_PATH)" "$(MAILME_PATH)"
	if [[ -d "$(NSLOGGING_BUILD)" ]]; then $(CP) "$(NSLOGGING_BUILD)" "$(NSLOGGING_PATH)"; fi
	if [[ -d "$(MAILME_BUILD)" ]]; then $(CP) "$(MAILME_BUILD)" "$(MAILME_PATH)"; fi
	open "$(GROWL_HELPER_APP)"

install-nslogging:
	killall GrowlHelperApp || true
	-$(RM) -rf "$(NSLOGGING_PATH)"
	$(CP) "$(NSLOGGING_BUILD)" "$(NSLOGGING_PATH)"
	open "$(GROWL_HELPER_APP)"

install-mailme:
	killall GrowlHelperApp || true
	-$(RM) -rf "$(MAILME_PATH)"
	$(CP) "$(MAILME_BUILD)" "$(MAILME_PATH)"
	open "$(GROWL_HELPER_APP)"

uninstall:
	killall GrowlHelperApp || true
	-$(RM) -rf "$(NSLOGGING_PATH)" "$(SMOKE_PATH)" "$(MAILME_PATH)" "$(MUSICVIDEO_PATH)"
	open "$(GROWL_HELPER_APP)"

uninstall-nslogging:
	killall GrowlHelperApp || true
	$(RM) -rf "$(NSLOGGING_PATH)"
	open "$(GROWL_HELPER_APP)"

uninstall-smoke:
	killall GrowlHelperApp || true
	$(RM) -rf "$(SMOKE_PATH)"
	open "$(GROWL_HELPER_APP)"

uninstall-mailme:
	killall GrowlHelperApp || true
	$(RM) -rf "$(MAILME_PATH)"
	open "$(GROWL_HELPER_APP)"

uninstall-musicvideo:
	killall GrowlHelperApp || true
	$(RM) -rf "$(MUSICVIDEO_PATH)"
	open "$(GROWL_HELPER_APP)"
