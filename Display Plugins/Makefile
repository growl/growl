LIBRARY?=$(HOME)/Library

PLUGINS_DIR?=$(LIBRARY)/Application Support/Growl/Plugins
PREFERENCEPANES_DIR?=$(LIBRARY)/PreferencePanes

BUILD_DIR=build
NSLOGGING_NAME=NSLogging.growlView
NSLOGGING_BUILD=$(BUILD_DIR)/$(NSLOGGING_NAME)
NSLOGGING_PATH=$(PLUGINS_DIR)/$(NSLOGGING_NAME)
BEZEL_NAME=Bezel.growlView
BEZEL_BUILD=$(BUILD_DIR)/$(BEZEL_NAME)
BEZEL_PATH=$(PLUGINS_DIR)/$(BEZEL_NAME)
SMOKE_NAME=Smoke.growlView
SMOKE_BUILD=$(BUILD_DIR)/$(SMOKE_NAME)
SMOKE_PATH=$(PLUGINS_DIR)/$(SMOKE_NAME)
MAILME_NAME=MailMe.growlView
MAILME_BUILD=$(BUILD_DIR)/$(MAILME_NAME)
MAILME_PATH=$(PLUGINS_DIR)/$(MAILME_NAME)
MUSICVIDEO_NAME=MusicVideo.growlView
MUSICVIDEO_BUILD=$(BUILD_DIR)/$(MUSICVIDEO_NAME)
MUSICVIDEO_PATH=$(PLUGINS_DIR)/$(MUSICVIDEO_NAME)
BUBBLES_NAME=Bubbles.growlView
BUBBLES_BUILD=$(BUILD_DIR)/$(BUBBLES_NAME)
BUBBLES_PATH=$(PLUGINS_DIR)/$(BUBBLES_NAME)

GROWL_PREFPANE=Growl.prefPane
GROWL_HELPER_APP=$(PREFERENCEPANES_DIR)/$(GROWL_PREFPANE)/Contents/Resources/GrowlHelperApp.app

DEFAULT_BUILDSTYLE=Deployment
#DEFAULT_BUILDSTYLE=Development

BUILDSTYLE?=$(DEFAULT_BUILDSTYLE)

CP?=ditto --rsrc
RM?=rm

.PHONY : all clean clean-nslogging clean-bezel clean-smoke clean-mailme clean-musicvideo install install-nslogging install-mailme uninstall uninstall-nslogging uninstall-smoke uninstall-mailme uninstall-musicvideo

all: nslogging bezel smoke mailme musicvideo
	xcodebuild -alltargets -buildstyle $(BUILDSTYLE) build

nslogging: $(NSLOGGING_BUILD)
$(NSLOGGING_BUILD):
	xcodebuild -target NSLogging -buildstyle $(BUILDSTYLE) build

bezel: $(BEZEL_BUILD)
$(BEZEL_BUILD):
	xcodebuild -target Bezel -buildstyle $(BUILDSTYLE) build

smoke: $(SMOKE_BUILD)
$(SMOKE_BUILD):
	xcodebuild -target Smoke -buildstyle $(BUILDSTYLE) build

mailme: $(MAILME_BUILD)
$(MAILME_BUILD):
	xcodebuild -target MailMe -buildstyle $(BUILDSTYLE) build

musicvideo: $(MUSICVIDEO_BUILD)
$(MUSICVIDEO_BUILD):
	xcodebuild -target MusicVideo -buildstyle $(BUILDSTYLE) build

bubbles: $(BUBBLES_BUILD)
$(BUBBLES_BUILD):
	xcodebuild -target BubblesNotificationView -buildstyle $(BUILDSTYLE) build

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

clean-bubbles:
	xcodebuild -target BubblesNotificationView clean

#install:
#	-killall GrowlHelperApp
#	-$(RM) -rf "$(NSLOGGING_PATH)" "$(MAILME_PATH)"
#	if [[ -d "$(NSLOGGING_BUILD)" ]]; then $(CP) "$(NSLOGGING_BUILD)" "$(NSLOGGING_PATH)"; fi
#	if [[ -d "$(MAILME_BUILD)" ]]; then $(CP) "$(MAILME_BUILD)" "$(MAILME_PATH)"; fi
#	open "$(GROWL_HELPER_APP)"

install: all
	xcodebuild -alltargets install
	-killall GrowlHelperApp
	open "$(GROWL_HELPER_APP)"

install-nslogging: $(NSLOGGING_BUILD)
	xcodebuild -target NSLogging install
	-killall GrowlHelperApp
	open "$(GROWL_HELPER_APP)"

install-bezel: $(NSLOGGING_BUILD)
	xcodebuild -target Bezel install
	-killall GrowlHelperApp
	open "$(GROWL_HELPER_APP)"

install-smoke: $(NSLOGGING_BUILD)
	xcodebuild -target Smoke install
	-killall GrowlHelperApp
	open "$(GROWL_HELPER_APP)"

install-mailme: $(NSLOGGING_BUILD)
	xcodebuild -target MailMe install
	-killall GrowlHelperApp
	open "$(GROWL_HELPER_APP)"

install-musicvideo: $(NSLOGGING_BUILD)
	xcodebuild -target MusicVideo install
	-killall GrowlHelperApp
	open "$(GROWL_HELPER_APP)"

install-bubbles: $(BUBBLES_BUILD)
	xcodebuild -target BubblesNotificationView install
	-killall GrowlHelperApp
	open "$(GROWL_HELPER_APP)"

uninstall:
	-killall GrowlHelperApp
	-$(RM) -rf "$(NSLOGGING_PATH)" "$(SMOKE_PATH)" "$(MAILME_PATH)" "$(MUSICVIDEO_PATH)"
	open "$(GROWL_HELPER_APP)"

uninstall-nslogging: $(NSLOGGING_PATH)
	-killall GrowlHelperApp
	$(RM) -rf "$(NSLOGGING_PATH)"
	open "$(GROWL_HELPER_APP)"

uninstall-bezel: $(BEZEL_PATH)
	-killall GrowlHelperApp
	$(RM) -rf "$(BEZEL_PATH)"
	open "$(GROWL_HELPER_APP)"

uninstall-smoke: $(SMOKE_PATH)
	-killall GrowlHelperApp
	$(RM) -rf "$(SMOKE_PATH)"
	open "$(GROWL_HELPER_APP)"

uninstall-mailme: $(MAILME_PATH)
	-killall GrowlHelperApp
	$(RM) -rf "$(MAILME_PATH)"
	open "$(GROWL_HELPER_APP)"

uninstall-musicvideo: $(MUSICVIDEO_PATH)
	-killall GrowlHelperApp
	$(RM) -rf "$(MUSICVIDEO_PATH)"
	open "$(GROWL_HELPER_APP)"

uninstall-bubbles: $(BUBBLES_PATH)
	-killall GrowlHelperApp
	$(RM) -rf "$(BUBBLES_PATH)"
	open "$(GROWL_HELPER_APP)"
