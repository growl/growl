PLUGINS_DIR=$(HOME)/Library/Application Support/Growl/Plugins
BUILD_DIR=build
NSLOGGING_NAME=NSLogging.growlView
NSLOGGING_BUILD=$(BUILD_DIR)/$(NSLOGGING_NAME)
NSLOGGING_PATH=$(PLUGINS_DIR)/$(NSLOGGING_NAME)
SMOKE_NAME=Smoke.growlView
SMOKE_BUILD=$(BUILD_DIR)/$(SMOKE_NAME)
SMOKE_PATH=$(PLUGINS_DIR)/$(SMOKE_NAME)

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

smoke:
	xcodebuild -target Smoke -buildstyle $(DEFAULT_BUILDSTYLE) build

clean:
	xcodebuild -project "Display Plugins.xcode" -alltargets clean

install:
	killall GrowlHelperApp || true
	-$(RM) -rf "$(NSLOGGING_PATH)" "$(SMOKE_PATH)"
	if [[ -d $(NSLOGGING_BUILD) ]]; then $(CP) $(NSLOGGING_BUILD) "$(NSLOGGING_PATH)"; fi
	if [[ -d $(SMOKE_BUILD) ]]; then $(CP) $(SMOKE_BUILD) "$(SMOKE_PATH)"; fi
	open $(GROWL_HELPER_APP)

install-nslogging:
	killall GrowlHelperApp || true
	-$(RM) -rf "$(NSLOGGING_PATH)"
	$(CP) $(NSLOGGING_BUILD) "$(NSLOGGING_PATH)"
	open $(GROWL_HELPER_APP)

install-smoke:
	killall GrowlHelperApp || true
	-$(RM) -rf "$(SMOKE_PATH)"
	$(CP) $(SMOKE_BUILD) "$(SMOKE_PATH)"
	open $(GROWL_HELPER_APP)
