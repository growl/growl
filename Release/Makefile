SRC_DIR=..
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

.PHONY: all compile clean release source

all: compile release source

compile:
	$(MAKE) $(BUILDFLAGS) -C $(SRC_DIR)
	$(MAKE) $(BUILDFLAGS) -C $(SRC_DIR)/Extras/GrowlMail
	$(MAKE) $(BUILDFLAGS) -C $(SRC_DIR)/Extras/GrowlSafari
	$(MAKE) $(BUILDFLAGS) -C $(SRC_DIR)/Extras/GrowlDict
	$(MAKE) $(BUILDFLAGS) -C $(SRC_DIR)/Extras/growlnotify
	$(MAKE) $(BUILDFLAGS) -C $(SRC_DIR)/Extras/HardwareGrowler
	$(MAKE) $(BUILDFLAGS) -C $(SRC_DIR)/Extras/growlctl
	$(MAKE) $(BUILDFLAGS) -C $(SRC_DIR)/Extras/GrowlWidget
	$(MAKE) $(BUILDFLAGS) -C $(SRC_DIR)/Extras/GrowlTunes

clean:
	rm -rf $(BUILD_DIR)

source:
	rm -rf $(BUILD_DIR)/source
	mkdir $(BUILD_DIR)/source
	cp -R $(SRC_DIR)/Bindings $(BUILD_DIR)/source
	cp -R $(SRC_DIR)/Common $(BUILD_DIR)/source
	cp -R $(SRC_DIR)/Core $(BUILD_DIR)/source
	cp -R $(SRC_DIR)/Display\ Plugins $(BUILD_DIR)/source
	cp -R $(SRC_DIR)/Docs $(BUILD_DIR)/source
	cp -R $(SRC_DIR)/Examples $(BUILD_DIR)/source
	cp -R $(SRC_DIR)/Extras $(BUILD_DIR)/source
	cp -R $(SRC_DIR)/Framework $(BUILD_DIR)/source
	cp -R $(SRC_DIR)/Growl\ Readme.rtfd $(BUILD_DIR)/source
	cp -R $(SRC_DIR)/Growl.xcode $(BUILD_DIR)/source
	cp -R $(SRC_DIR)/Prefpane\ TestHarness $(BUILD_DIR)/source
	cp -R $(SRC_DIR)/Scripts $(BUILD_DIR)/source
	cp -R $(SRC_DIR)/images $(BUILD_DIR)/source
	cp $(SRC_DIR)/HACKING.txt $(BUILD_DIR)/source
	cp $(SRC_DIR)/License.txt $(BUILD_DIR)/source
	cp $(SRC_DIR)/Makefile $(BUILD_DIR)/source
	cp $(SRC_DIR)/README.rtf $(BUILD_DIR)/source
	cp $(SRC_DIR)/build.sh $(BUILD_DIR)/source
	cp $(SRC_DIR)/changes.txt $(BUILD_DIR)/source
	cp $(SRC_DIR)/generateSVNRevision.sh $(BUILD_DIR)/source
	cp $(SRC_DIR)/headerDoc2HTML.config $(BUILD_DIR)/source
	find $(BUILD_DIR)/source \( -name build -or -name .svn \) -exec rm -rf {} \; -prune
	find $(BUILD_DIR)/source \( -name "*~" -or -name .DS_Store \) -delete
	tar -c -C $(BUILD_DIR)/source -f $(BUILD_DIR)/$(RELEASE_NAME)-src.tar .
	bzip2 $(BUILD_DIR)/$(RELEASE_NAME)-src.tar

release:
	@# clean build directory
	rm -rf $(BUILD_DIR)
	mkdir $(BUILD_DIR)
	mkdir $(GROWL_DIR)
	@# copy uninstaller
	cp -R "Uninstall Growl.app" $(GROWL_DIR)
	/Developer/Tools/SetFile -a E $(GROWL_DIR)/Uninstall\ Growl.app
	@# copy webloc files
	cp "Growl Documentation.webloc" "Growl version history.webloc" "Get more styles.webloc" $(GROWL_DIR)
	@# hide extensions of webloc files
	/Developer/Tools/SetFile -a E $(GROWL_DIR)/*.webloc
	@# copy the prefpane
	cp -R $(SRC_DIR)/build/Growl.prefPane $(GROWL_DIR)
	@# copy the extras
	mkdir $(GROWL_DIR)/Extras
	mkdir $(GROWL_DIR)/Extras/growlctl
	cp $(SRC_DIR)/Extras/growlctl/build/growlctl $(GROWL_DIR)/Extras/growlctl
	cp $(SRC_DIR)/Extras/growlctl/growlctl.1 $(GROWL_DIR)/Extras/growlctl
	cp $(SRC_DIR)/Extras/growlctl/install.sh $(GROWL_DIR)/Extras/growlctl
	mkdir $(GROWL_DIR)/Extras/GrowlDict
	cp -R $(SRC_DIR)/Extras/GrowlDict/build/GrowlDict.app $(GROWL_DIR)/Extras/GrowlDict
	cp $(SRC_DIR)/Extras/GrowlDict/README.txt $(GROWL_DIR)/Extras/GrowlDict
	mkdir $(GROWL_DIR)/Extras/GrowlMail
	cp -R $(SRC_DIR)/Extras/GrowlMail/build/GrowlMail.mailbundle $(GROWL_DIR)/Extras/GrowlMail
	cp $(SRC_DIR)/Extras/GrowlMail/GrowlMail\ Installation.rtf $(GROWL_DIR)/Extras/GrowlMail
	mkdir $(GROWL_DIR)/Extras/growlnotify
	cp $(SRC_DIR)/Extras/growlnotify/build/growlnotify $(GROWL_DIR)/Extras/growlnotify
	cp $(SRC_DIR)/Extras/growlnotify/growlnotify.1 $(GROWL_DIR)/Extras/growlnotify
	cp $(SRC_DIR)/Extras/growlnotify/install.sh $(GROWL_DIR)/Extras/growlnotify
	cp $(SRC_DIR)/Extras/growlnotify/README.txt $(GROWL_DIR)/Extras/growlnotify
	mkdir $(GROWL_DIR)/Extras/GrowlTunes
	cp -R $(SRC_DIR)/Extras/GrowlTunes/build/GrowlTunes.app $(GROWL_DIR)/Extras/GrowlTunes
	cp -R $(SRC_DIR)/Extras/GrowlTunes/ReadMe.rtfd $(GROWL_DIR)/Extras/GrowlTunes
	mkdir $(GROWL_DIR)/Extras/HardwareGrowler
	cp -R $(SRC_DIR)/Extras/HardwareGrowler/build/HardwareGrowler.app $(GROWL_DIR)/Extras/HardwareGrowler
	cp $(SRC_DIR)/Extras/HardwareGrowler/readme.txt $(GROWL_DIR)/Extras/HardwareGrowler
	@# build GrowlSafari package
	mkdir $(GROWL_DIR)/Extras/GrowlSafari
	cp -R GrowlSafari.mpkg $(GROWL_DIR)/Extras/GrowlSafari
	mkdir $(BUILD_DIR)/GrowlSafari
	cp -R $(SRC_DIR)/Extras/GrowlSafari/build/GrowlSafari.bundle $(BUILD_DIR)/GrowlSafari
	sudo chown -Rh root:admin $(BUILD_DIR)/GrowlSafari
	/Developer/Tools/packagemaker -build -p $(GROWL_DIR)/Extras/GrowlSafari/GrowlSafari.mpkg/Contents/Packages/GrowlSafari.pkg -f $(BUILD_DIR)/GrowlSafari -ds -v -i GrowlSafari-Info.plist -d GrowlSafari-Description.plist
	sudo rm -rf $(BUILD_DIR)/GrowlSafari
	cp -R $(SRC_DIR)/Extras/GrowlSafari/README.txt $(GROWL_DIR)/Extras/GrowlSafari
	@# build the SDK
	mkdir $(SDK_DIR)
	@# copy the webloc files
	cp "Growl Developer Documentation.webloc" "Growl version history for developers.webloc" $(SDK_DIR)
	@# hide extensions of webloc files
	/Developer/Tools/SetFile -a E $(SDK_DIR)/*.webloc
	@# copy the scripts
	cp -R $(SRC_DIR)/Scripts $(GROWL_DIR)
	@# copy the frameworks
	mkdir $(SDK_DIR)/Frameworks
	cp -R $(SRC_DIR)/build/Growl.framework $(SRC_DIR)/build/Growl-WithInstaller.framework $(SDK_DIR)/Frameworks
	@# copy the bindings
	cp -R $(SRC_DIR)/Bindings $(SDK_DIR)
	@# remove the AppleScript binding
	rm -rf $(SDK_DIR)/Bindings/applescript
	@# remove some symlinks
	rm $(SDK_DIR)/Bindings/realbasic/GrowlDefines.h
	rm $(SDK_DIR)/Bindings/tcl/GrowlDefines.h
	rm $(SDK_DIR)/Bindings/tcl/GrowlApplicationBridge.h
	rm $(SDK_DIR)/Bindings/tcl/GrowlApplicationBridge.m
	@# delete svn and backup files
	find $(BUILD_DIR) -name ".svn" -exec rm -rf {} \; -prune
	find $(BUILD_DIR) \( -name "*~" -or -name .DS_Store \) -delete
	@# make Growl disk image
	mkdir $(GROWL_DIR)/.background
	cp $(SRC_DIR)/images/dmg/growl07DMGBackground.png $(GROWL_DIR)/.background
	./make-diskimage.sh $(BUILD_DIR)/$(RELEASE_NAME).dmg $(GROWL_DIR) Growl dmg_growl.scpt
	@# make SDK disk image
	mkdir $(SDK_DIR)/.background
	cp $(SRC_DIR)/images/dmg/growlSDK.png $(SDK_DIR)/.background
	./make-diskimage.sh $(BUILD_DIR)/$(RELEASE_NAME)-SDK.dmg $(SDK_DIR) Growl-SDK dmg_sdk.scpt
	@echo Build finished

