PLUGINS_DIR=$(HOME)/Library/Application Support/Growl/Plugins
BUILD_DIR=build
BEZEL_NAME=Bezel.growlView
BEZEL_BUILD=$(BUILD_DIR)/$(BEZEL_NAME)
BEZEL_PATH=$(PLUGINS_DIR)/$(BEZEL_NAME)
NSLOGGING_NAME=NSLogging.growlView
NSLOGGING_BUILD=$(BUILD_DIR)/$(NSLOGGING_NAME)
NSLOGGING_PATH=$(PLUGINS_DIR)/$(NSLOGGING_NAME)

PREFERENCEPANES_DIR=$(HOME)/Library/PreferencePanes
GROWL_PREFPANE=Growl.prefPane
GROWL_HELPER_APP=$(PREFERENCEPANES_DIR)/$(GROWL_PREFPANE)/Contents/Resources/GrowlHelperApp.app

#DEFAULT_BUILDSTYLE=Deployment
DEFAULT_BUILDSTYLE=Development

CP=ditto --rsrc
RM=rm

all:
	xcodebuild -alltargets -buildstyle $(DEFAULT_BUILDSTYLE) build

nslogging:
	xcodebuild -target NSLogging -buildstyle $(DEFAULT_BUILDSTYLE) build

bezel:
	xcodebuild -target Bezel -buildstyle $(DEFAULT_BUILDSTYLE) build

install:
	-killall GrowlHelperApp; exit 0
	-$(RM) -rf "$(BEZEL_PATH)" "$(NSLOGGING_PATH)"
	$(CP) $(BEZEL_BUILD) "$(BEZEL_PATH)"
	$(CP) $(NSLOGGING_BUILD) "$(NSLOGGING_PATH)"
	open $(GROWL_HELPER_APP)
