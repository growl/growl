SRC_DIR=..
BUILD_DIR=build
GROWL_DIR=$(BUILD_DIR)/Growl
SDK_DIR=$(BUILD_DIR)/SDK
RELEASE_NAME=Growl-0.8
BUILDSTYLE=Deployment
BUILDFLAGS="BUILDCONFIGURATION=$(BUILDSTYLE)"
PRODUCT_DIR=$(shell defaults read com.apple.Xcode PBXProductDirectory 2> /dev/null)
ifeq ($(strip $(PRODUCT_DIR)),)
	GROWL_BUILD_DIR=$(SRC_DIR)/build/$(BUILDSTYLE)
	GROWLNOTIFY_BUILD_DIR=$(SRC_DIR)/Extras/growlnotify/build/$(BUILDSTYLE)
	GROWLTUNES_BUILD_DIR=$(SRC_DIR)/Extras/GrowlTunes/build/$(BUILDSTYLE)
	HARDWAREGROWLER_BUILD_DIR=$(SRC_DIR)/Extras/HardwareGrowler/build/$(BUILDSTYLE)
	GROWLMAIL_BUILD_DIR=$(SRC_DIR)/Extras/GrowlMail/build/$(BUILDSTYLE)
	GROWLSAFARI_BUILD_DIR=$(SRC_DIR)/Extras/GrowlSafari/build/$(BUILDSTYLE)
else
	TARGET_BUILD_DIR=$(PRODUCT_DIR)/$(BUILDSTYLE)
	GROWL_BUILD_DIR=$(TARGET_BUILD_DIR)
	GROWLNOTIFY_BUILD_DIR=$(TARGET_BUILD_DIR)
	GROWLTUNES_BUILD_DIR=$(TARGET_BUILD_DIR)
	HARDWAREGROWLER_BUILD_DIR=$(TARGET_BUILD_DIR)
	GROWLMAIL_BUILD_DIR=$(TARGET_BUILD_DIR)
	GROWLSAFARI_BUILD_DIR=$(TARGET_BUILD_DIR)
endif

# What to do before running this script:
# - Set version number in GHA. You can do this in GrowlController.m. Look for the "static struct Version version" line.
# - Set RELEASE_NAME
# - Edit the following two plist keys
#       - Core/Resources/Info.plist
#       - Core/Resources/GrowlHelperApp-Info.plist

.PHONY: all assertnochanges assertnoconflicts compile clean release source

all: assertnochanges compile release
all-withlocalchanges: assertnoconflicts compile release

assertnochanges:
	if [[ 0 -ne `svn st $(SRC_DIR) | wc -l` ]]; then \
		echo 'You have local changes. Please do not build releases from an unclean checkout. You must revert the changes, commit them, or check out another working copy and build from that.' 1>&2; \
		exit 1; \
	fi
assertnoconflicts:
	if [[ 0 -ne `svn st $(SRC_DIR) | egrep '^C' | wc -l` ]]; then \
		echo 'You have conflicts in your checkout. You will not be able to build until these are resolved. Also, remember that even after you have fixed all conflict marks, you must use "svn resolved"; otherwise, svn will still believe the files are conflicted.' 1>&2; \
		exit 2; \
	fi

compile:
	$(MAKE) $(BUILDFLAGS) -C $(SRC_DIR)
	$(MAKE) $(BUILDFLAGS) -C $(SRC_DIR)/Extras/GrowlMail
	$(MAKE) $(BUILDFLAGS) -C $(SRC_DIR)/Extras/GrowlSafari
	$(MAKE) $(BUILDFLAGS) -C $(SRC_DIR)/Extras/growlnotify
	$(MAKE) $(BUILDFLAGS) -C $(SRC_DIR)/Extras/HardwareGrowler
	$(MAKE) $(BUILDFLAGS) -C $(SRC_DIR)/Extras/GrowlTunes

clean:
	rm -rf $(BUILD_DIR)

realclean: clean
	../build.sh clean

#source:
#	rm -rf $(BUILD_DIR)/source
#	mkdir $(BUILD_DIR)/source
#	cp -R $(SRC_DIR)/Bindings $(BUILD_DIR)/source
#	cp -R $(SRC_DIR)/Common $(BUILD_DIR)/source
#	cp -R $(SRC_DIR)/Core $(BUILD_DIR)/source
#	cp -R $(SRC_DIR)/Plugins $(BUILD_DIR)/source
#	cp -R $(SRC_DIR)/Docs $(BUILD_DIR)/source
#	cp -R $(SRC_DIR)/Examples $(BUILD_DIR)/source
#	cp -R $(SRC_DIR)/Extras $(BUILD_DIR)/source
#	cp -R $(SRC_DIR)/Framework $(BUILD_DIR)/source
#	cp -R $(SRC_DIR)/Growl\ Readme.rtfd $(BUILD_DIR)/source
#	cp -R $(SRC_DIR)/Growl.xcodeproj $(BUILD_DIR)/source
#	cp -R $(SRC_DIR)/Prefpane\ TestHarness $(BUILD_DIR)/source
#	#cp -R $(SRC_DIR)/Scripts $(BUILD_DIR)/source
#	cp -R $(SRC_DIR)/images $(BUILD_DIR)/source
#	cp $(SRC_DIR)/HACKING.txt $(BUILD_DIR)/source
#	cp $(SRC_DIR)/License.txt $(BUILD_DIR)/source
#	cp $(SRC_DIR)/Makefile $(BUILD_DIR)/source
#	cp $(SRC_DIR)/README.rtf $(BUILD_DIR)/source
#	cp $(SRC_DIR)/build.sh $(BUILD_DIR)/source
#	cp $(SRC_DIR)/changes.txt $(BUILD_DIR)/source
#	cp $(SRC_DIR)/generateSVNRevision.sh $(BUILD_DIR)/source
#	cp $(SRC_DIR)/headerDoc2HTML.config $(BUILD_DIR)/source
#	find $(BUILD_DIR)/source \( -name build -or -name .svn -or -name "*~.nib" \) -type d -exec rm -rf {} \; -prune
#	find $(BUILD_DIR)/source \( -name "*~" -or -name .DS_Store \) -type f -delete
#	tar -c -C $(BUILD_DIR)/source -f $(BUILD_DIR)/$(RELEASE_NAME)-src.tar .
#	bzip2 $(BUILD_DIR)/$(RELEASE_NAME)-src.tar

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
	cp -R $(GROWL_BUILD_DIR)/Growl.prefPane $(GROWL_DIR)
	@# copy the extras
	mkdir $(GROWL_DIR)/Extras
	mkdir $(GROWL_DIR)/Extras/growlnotify
	cp $(GROWLNOTIFY_BUILD_DIR)/growlnotify $(GROWL_DIR)/Extras/growlnotify
	cp $(SRC_DIR)/Extras/growlnotify/growlnotify.1 $(GROWL_DIR)/Extras/growlnotify
	cp $(SRC_DIR)/Extras/growlnotify/install.sh $(GROWL_DIR)/Extras/growlnotify
	cp $(SRC_DIR)/Extras/growlnotify/README.txt $(GROWL_DIR)/Extras/growlnotify
	mkdir $(GROWL_DIR)/Extras/GrowlTunes
	cp -R $(GROWLTUNES_BUILD_DIR)/GrowlTunes.app $(GROWL_DIR)/Extras/GrowlTunes
	cp -R $(SRC_DIR)/Extras/GrowlTunes/ReadMe.rtfd $(GROWL_DIR)/Extras/GrowlTunes
	mkdir $(GROWL_DIR)/Extras/HardwareGrowler
	cp -R $(HARDWAREGROWLER_BUILD_DIR)/HardwareGrowler.app $(GROWL_DIR)/Extras/HardwareGrowler
	cp $(SRC_DIR)/Extras/HardwareGrowler/readme.txt $(GROWL_DIR)/Extras/HardwareGrowler
	@# build GrowlMail package
	mkdir $(GROWL_DIR)/Extras/GrowlMail
	mkdir $(BUILD_DIR)/GrowlMail
	mkdir $(BUILD_DIR)/GrowlMail-Resources
	cp -R $(GROWLMAIL_BUILD_DIR)/GrowlMail.mailbundle $(BUILD_DIR)/GrowlMail
	cp GrowlMail/InstallationCheck $(BUILD_DIR)/GrowlMail-Resources
	cp GrowlMail/postflight $(BUILD_DIR)/GrowlMail-Resources
	cp -R GrowlMail/English.lproj $(BUILD_DIR)/GrowlMail-Resources
	cp -R GrowlMail/German.lproj $(BUILD_DIR)/GrowlMail-Resources
	sudo chown -Rh root:admin $(BUILD_DIR)/GrowlMail
	sudo chmod -R g+w $(BUILD_DIR)/GrowlMail
	/Developer/Tools/packagemaker -build -p $(GROWL_DIR)/Extras/GrowlMail/GrowlMail.pkg -f $(BUILD_DIR)/GrowlMail -ds -v -i GrowlMail/Info.plist -d GrowlMail/Description.plist -r $(BUILD_DIR)/GrowlMail-Resources
	sudo rm -rf $(BUILD_DIR)/GrowlMail
	rm -rf $(BUILD_DIR)/GrowlMail-Resources
	cp $(SRC_DIR)/Extras/GrowlMail/GrowlMail\ Installation.rtf $(GROWL_DIR)/Extras/GrowlMail
	@# build GrowlSafari package
	mkdir $(GROWL_DIR)/Extras/GrowlSafari
	mkdir $(BUILD_DIR)/GrowlSafari
	mkdir $(BUILD_DIR)/GrowlSafari-Resources
	cp -R $(GROWLSAFARI_BUILD_DIR)/GrowlSafari $(BUILD_DIR)/GrowlSafari
	cp GrowlSafari/postupgrade $(BUILD_DIR)/GrowlSafari-Resources
	sudo chown -Rh root:admin $(BUILD_DIR)/GrowlSafari
	sudo chmod -R g+w $(BUILD_DIR)/GrowlSafari
	/Developer/Tools/packagemaker -build -p $(GROWL_DIR)/Extras/GrowlSafari/GrowlSafari.pkg -f $(BUILD_DIR)/GrowlSafari -ds -v -i GrowlSafari/Info.plist -d GrowlSafari/Description.plist -r $(BUILD_DIR)/GrowlSafari-Resources
	sudo rm -rf $(BUILD_DIR)/GrowlSafari
	rm -rf $(BUILD_DIR)/GrowlSafari-Resources
	cp -R $(SRC_DIR)/Extras/GrowlSafari/README.txt $(GROWL_DIR)/Extras/GrowlSafari
	@# build the SDK
	mkdir $(SDK_DIR)
	@# copy the webloc files
	cp "Growl Developer Documentation.webloc" "Growl version history for developers.webloc" $(SDK_DIR)
	@# hide extensions of webloc files
	/Developer/Tools/SetFile -a E $(SDK_DIR)/*.webloc
	@# copy the scripts
	#cp -R $(SRC_DIR)/Scripts $(GROWL_DIR)
	@# copy over relevant files to compile directly into app
	mkdir $(SDK_DIR)/Built-In
	cp $(SRC_DIR)/Framework/Source/GrowlApplicationBridge.h $(SDK_DIR)/Built-In
	cp $(SRC_DIR)/Framework/Source/GrowlApplicationBridge.m $(SDK_DIR)/Built-In
	cp $(SRC_DIR)/Common/Source/GrowlDefines.h $(SDK_DIR)/Built-In
	cp $(SRC_DIR)/Common/Source/GrowlDefinesInternal.h $(SDK_DIR)/Built-In
	cp $(SRC_DIR)/Common/Source/GrowlPathUtilities.h $(SDK_DIR)/Built-In
	cp $(SRC_DIR)/Common/Source/GrowlPathUtilities.m $(SDK_DIR)/Built-In 
	cp $(SRC_DIR)/Common/Source/CFGrowlAdditions.h $(SDK_DIR)/Built-In
	cp $(SRC_DIR)/Common/Source/CFGrowlAdditions.c $(SDK_DIR)/Built-In
	cp $(SRC_DIR)/Common/Source/CFGrowlDefines.h $(SDK_DIR)/Built-In
	cp $(SRC_DIR)/Common/Source/CFURLAdditions.h $(SDK_DIR)/Built-In
	cp $(SRC_DIR)/Common/Source/CFURLAdditions.c $(SDK_DIR)/Built-In
	cp $(SRC_DIR)/Common/Source/CFMutableDictionaryAdditions.h $(SDK_DIR)/Built-In
	cp $(SRC_DIR)/Common/Source/CFMutableDictionaryAdditions.c $(SDK_DIR)/Built-In
	cp $(SRC_DIR)/Core/Source/GrowlPreferencesController.h $(SDK_DIR)/Built-In
	cp $(SRC_DIR)/Core/Source/GrowlTicketController.h $(SDK_DIR)/Built-In
	@# copy the frameworks
	mkdir $(SDK_DIR)/Frameworks
	cp -R $(GROWL_BUILD_DIR)/Growl.framework $(GROWL_BUILD_DIR)/Growl-WithInstaller.framework $(SDK_DIR)/Frameworks
	@# copy the bindings
	cp -R $(SRC_DIR)/Bindings $(SDK_DIR)
	@# remove the AppleScript binding
	rm -rf $(SDK_DIR)/Bindings/applescript
	@# remove some symlinks
	rm $(SDK_DIR)/Bindings/tcl/GrowlDefines.h
	rm $(SDK_DIR)/Bindings/tcl/GrowlApplicationBridge.h
	rm $(SDK_DIR)/Bindings/tcl/GrowlApplicationBridge.m
	@# delete svn and backup files
	find $(BUILD_DIR) -name ".svn" -type d -exec rm -rf {} \; -prune
	find $(BUILD_DIR) \( -name "*~" -or -name .DS_Store -or -name classes.nib -or -name info.nib \) -type f -delete
	@# make Growl disk image
	mkdir $(GROWL_DIR)/.background
	cp $(SRC_DIR)/images/dmg/growl08DMGBackground.png $(GROWL_DIR)/.background
	./make-diskimage.sh $(BUILD_DIR)/$(RELEASE_NAME).dmg $(GROWL_DIR) Growl dmg_growl.scpt
	@# make SDK disk image
	mkdir $(SDK_DIR)/.background
	cp $(SRC_DIR)/images/dmg/growlSDK.png $(SDK_DIR)/.background
	./make-diskimage.sh $(BUILD_DIR)/$(RELEASE_NAME)-SDK.dmg $(SDK_DIR) Growl-SDK dmg_sdk.scpt
	@echo Build finished
