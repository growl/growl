PREFERENCEPANES_DIR=$(HOME)/Library/PreferencePanes
FRAMEWORKS_DIR=/Library/Frameworks
GROWL_PREFPANE=Growl.prefPane
GROWL_FRAMEWORK=GrowlAppBridge.framework
BUILD_DIR=build
GROWL_HELPER_APP=$(PREFERENCEPANES_DIR)/$(GROWL_PREFPANE)/Contents/Resources/GrowlHelperApp.app

DEFAULT_BUILDSTYLE=Deployment
#DEFAULT_BUILDSTYLE=Development

BUILDSTYLE?=$(DEFAULT_BUILDSTYLE)

CP=ditto --rsrc
RM=rm

.PHONY : default all growl growlhelperapp growlappbridge clean install

default: growlappbridge
	xcodebuild -project Growl.xcode -target Growl -buildstyle $(BUILDSTYLE) build

all: growlappbridge
	xcodebuild -project Growl.xcode -alltargets -buildstyle $(BUILDSTYLE) build

growl:
	xcodebuild -project Growl.xcode -target Growl -buildstyle $(BUILDSTYLE) build

growlhelperapp:
	xcodebuild -project Growl.xcode -target GrowlHelperApp -buildstyle $(BUILDSTYLE) build

growlappbridge:
	xcodebuild -project GrowlAppBridge.xcode -target GrowlAppBridge -buildstyle $(BUILDSTYLE) build

clean:
	xcodebuild -project Growl.xcode -alltargets clean

install:
	killall GrowlHelperApp || true
	-$(RM) -rf $(PREFERENCEPANES_DIR)/$(GROWL_PREFPANE) $(FRAMEWORKS_DIR)/$(GROWL_FRAMEWORK)
	$(CP) $(BUILD_DIR)/$(GROWL_PREFPANE) $(PREFERENCEPANES_DIR)/$(GROWL_PREFPANE)
	$(CP) $(BUILD_DIR)/$(GROWL_FRAMEWORK) $(FRAMEWORKS_DIR)/$(GROWL_FRAMEWORK)
	open $(GROWL_HELPER_APP)
