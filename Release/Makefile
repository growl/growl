BUILD_DIR=build
GROWL_DIR=$(BUILD_DIR)/Growl
SDK_DIR=$(BUILD_DIR)/SDK
RELEASE_NAME=Growl-0.7
BUILDSTYLE="\"Deployment\""
BUILDFLAGS="BUILDSTYLE=$(BUILDSTYLE)"

# What to do before running this script:
# - gcc_select 3.3
# - Set version number in GHA
# - Set RELEASE_NAME

.PHONY: all compile clean release

all: compile release

compile:
	$(MAKE) $(BUILDFLAGS) -C .. 
	$(MAKE) $(BUILDFLAGS) -C ../Extras/GrowlMail
	$(MAKE) $(BUILDFLAGS) -C ../Extras/GrowlSafari
	$(MAKE) $(BUILDFLAGS) -C ../Extras/GrowlDict
	$(MAKE) $(BUILDFLAGS) -C ../Extras/growlnotify
	$(MAKE) $(BUILDFLAGS) -C ../Extras/HardwareGrowler
	$(MAKE) $(BUILDFLAGS) -C ../Extras/growlctl
	$(MAKE) $(BUILDFLAGS) -C ../Extras/GrowlWidget
	$(MAKE) $(BUILDFLAGS) -C ../Extras/GrowlTunes

clean:
	rm -rf $(BUILD_DIR)

release:
	@# clean build directory
	rm -rf $(BUILD_DIR)
	mkdir $(BUILD_DIR)
	mkdir $(GROWL_DIR)
	@# copy uninstaller
	cp -R "Uninstall Growl.app" $(GROWL_DIR)
	@# copy webloc files
	cp "Growl Documentation.webloc" "Growl version history.webloc" $(GROWL_DIR)
	@# hide extensions of webloc files
	/Developer/Tools/SetFile -a E $(GROWL_DIR)/*.webloc
	@# copy the prefpane
	cp -R ../build/Growl.prefPane $(GROWL_DIR)
	@# copy the extras
	mkdir $(GROWL_DIR)/Extras
	mkdir $(GROWL_DIR)/Extras/growlctl
	cp ../Extras/growlctl/build/growlctl $(GROWL_DIR)/Extras/growlctl
	cp ../Extras/growlctl/growlctl.1 $(GROWL_DIR)/Extras/growlctl
	cp ../Extras/growlctl/install.sh $(GROWL_DIR)/Extras/growlctl
	mkdir $(GROWL_DIR)/Extras/GrowlDict
	cp -R ../Extras/GrowlDict/build/GrowlDict.app $(GROWL_DIR)/Extras/GrowlDict
	cp ../Extras/GrowlDict/README.txt $(GROWL_DIR)/Extras/GrowlDict
	mkdir $(GROWL_DIR)/Extras/GrowlMail
	cp -R ../Extras/GrowlMail/build/GrowlMail.mailbundle $(GROWL_DIR)/Extras/GrowlMail
	cp ../Extras/GrowlMail/GrowlMail\ Installation.rtf $(GROWL_DIR)/Extras/GrowlMail
	mkdir $(GROWL_DIR)/Extras/growlnotify
	cp ../Extras/growlnotify/build/growlnotify $(GROWL_DIR)/Extras/growlnotify
	cp ../Extras/growlnotify/growlnotify.1 $(GROWL_DIR)/Extras/growlnotify
	cp ../Extras/growlnotify/install.sh $(GROWL_DIR)/Extras/growlnotify
	cp ../Extras/growlnotify/README.txt $(GROWL_DIR)/Extras/growlnotify
	mkdir $(GROWL_DIR)/Extras/GrowlTunes
	cp -R ../Extras/GrowlTunes/build/GrowlTunes.app $(GROWL_DIR)/Extras/GrowlTunes
	cp -R ../Extras/GrowlTunes/ReadMe.rtfd $(GROWL_DIR)/Extras/GrowlTunes
	mkdir $(GROWL_DIR)/Extras/HardwareGrowler
	cp -R ../Extras/HardwareGrowler/build/HardwareGrowler.app $(GROWL_DIR)/Extras/HardwareGrowler
	cp ../Extras/HardwareGrowler/readme.txt $(GROWL_DIR)/Extras/HardwareGrowler
	@# build GrowlSafari package
	mkdir $(GROWL_DIR)/Extras/GrowlSafari
	cp -R GrowlSafari.mpkg $(GROWL_DIR)/Extras/GrowlSafari
	mkdir $(BUILD_DIR)/GrowlSafari
	cp -R ../Extras/GrowlSafari/build/GrowlSafari.bundle $(BUILD_DIR)/GrowlSafari
	/Developer/Tools/packagemaker -build -p $(GROWL_DIR)/Extras/GrowlSafari/GrowlSafari.mpkg/Contents/Packages/GrowlSafari.pkg -f $(BUILD_DIR)/GrowlSafari -ds -v -i GrowlSafari-Info.plist -d GrowlSafari-Description.plist
	cp -R ../Extras/GrowlSafari/README.txt $(GROWL_DIR)/Extras/GrowlSafari
	@# build the SDK
	mkdir $(SDK_DIR)
	@# copy the webloc files
	cp "Growl Developer Documentation.webloc" "Growl version history for developers.webloc" $(SDK_DIR)
	@# hide extensions of webloc files
	/Developer/Tools/SetFile -a E $(SDK_DIR)/*.webloc
	@# copy the scripts
	cp -R ../Scripts $(GROWL_DIR)
	@# copy the frameworks
	mkdir $(SDK_DIR)/Frameworks
	cp -R ../build/Growl.framework ../build/Growl-WithInstaller.framework $(SDK_DIR)/Frameworks
	@# copy the bindings
	cp -R ../Bindings $(SDK_DIR)
	@# remove the AppleScript binding
	rm -rf $(SDK_DIR)/Bindings/applescript%
	@# remove some symlinks
	rm $(SDK_DIR)/Bindings/realbasic/GrowlDefines.h
	rm $(SDK_DIR)/Bindings/tcl/GrowlDefines.h
	rm $(SDK_DIR)/Bindings/tcl/GrowlApplicationBridge.h
	rm $(SDK_DIR)/Bindings/tcl/GrowlApplicationBridge.m
	@# delete svn and backup files
	find $(BUILD_DIR) -name ".svn" -exec rm -rf {} \; -prune
	find $(BUILD_DIR) -name "*~" -delete
	find $(BUILD_DIR) -name ".DS_Store" -delete
	@# make Growl disk image
	cp DS_Store $(GROWL_DIR)/.DS_Store
	mkdir $(GROWL_DIR)/.background
	cp ../images/dmg/growl07DMGBackground.png $(GROWL_DIR)/.background
	hdiutil create -srcfolder $(GROWL_DIR) -volname Growl -fs HFS+ -fsargs "-c c=64,a=16,e=16" -format UDZO $(BUILD_DIR)/tmp.dmg
	hdiutil convert -format UDZO -imagekey zlib-level=9 -o "$(BUILD_DIR)/$(RELEASE_NAME).dmg" $(BUILD_DIR)/tmp.dmg
	rm $(BUILD_DIR)/tmp.dmg
	@# make SDK disk image
	cp DS_Store_SDK $(SDK_DIR)/.DS_Store
	mkdir $(SDK_DIR)/.background
	cp ../images/dmg/growlSDK.png $(SDK_DIR)/.background
	hdiutil create -srcfolder $(SDK_DIR) -volname Growl-SDK -fs HFS+ -fsargs "-c c=64,a=16,e=16" -format UDZO "$(BUILD_DIR)/tmp.dmg"
	hdiutil convert -format UDZO -imagekey zlib-level=9 -o "$(BUILD_DIR)/$(RELEASE_NAME)-SDK.dmg" $(BUILD_DIR)/tmp.dmg
	rm $(BUILD_DIR)/tmp.dmg
	@echo Build finished

