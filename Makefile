PREFERENCEPANES_DIR=$(HOME)/Library/PreferencePanes
FRAMEWORKS_DIR=/Library/Frameworks
GROWL_PREFPANE=Growl.prefPane
GROWL_FRAMEWORK=GrowlAppBridge.framework
BUILD_DIR=build
GROWL_HELPER_APP=$(PREFERENCEPANES_DIR)/$(GROWL_PREFPANE)/Contents/Resources/GrowlHelperApp.app

CP=ditto --rsrc

default: growlappbridge
	xcodebuild -project Growl.xcode -target Growl -buildstyle Deployment build

all: growlappbridge
	xcodebuild -project Growl.xcode -alltargets -buildstyle Deployment build

growl:
	xcodebuild -project Growl.xcode -target Growl -buildstyle Development build

growlhelperapp:
	xcodebuild -project Growl.xcode -target GrowlHelperApp -buildstyle Development build

growlappbridge:
	xcodebuild -project GrowlAppBridge.xcode -target GrowlAppBridge -buildstyle Deployment build

display: bubblesnotificationview

bubblesnotificationview:
	xcodebuild -project Growl.xcode -target BubblesNotificationView -buildstyle Development build

clean:
	xcodebuild -project Growl.xcode -alltargets clean

install:
	-killall GrowlHelperApp
	rm -rf $(PREFERENCEPANES_DIR)/$(GROWL_PREFPANE) $(FRAMEWORKS_DIR)/$(GROWL_FRAMEWORK)
	$(CP) $(BUILD_DIR)/$(GROWL_PREFPANE) $(PREFERENCEPANES_DIR)/$(GROWL_PREFPANE)
	$(CP) $(BUILD_DIR)/$(GROWL_FRAMEWORK) $(FRAMEWORKS_DIR)/$(GROWL_FRAMEWORK)
	open $(GROWL_HELPER_APP)
