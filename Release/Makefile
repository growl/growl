##########################
### Versioning:
###   * Set VERSION and BETA below. BETA should be TRUE or FALSE.
###   * make version.
#
VERSION=1.2b5
BETA=TRUE

#
#########################
#
# No changes should be needed below this line
#
#########################
RELEASE_FILENAME=Growl-$(VERSION)
RELEASE_NAME="Growl-$(VERSION)"
RELEASE_SDK_NAME="Growl $(VERSION) SDK"

SRC_DIR=$(PWD)/..
BUILD_DIR=build
GROWL_DIR=$(BUILD_DIR)/Growl
SDK_DIR=$(BUILD_DIR)/SDK
FMWK_DIR=$(BUILD_DIR)/Growl-$(VERSION)-Framework
FMWK_TBZ_NAME=Growl-$(VERSION)-Framework.tbz
BUILDSTYLE=Release
BUILDFLAGS="BUILDCONFIGURATION=$(BUILDSTYLE)"
PRODUCT_DIR=$(shell defaults read com.apple.Xcode PBXApplicationwideBuildSettings 2> /dev/null | cat > XcodeBuildSettings.plist && defaults read $PWD/XcodeBuildSettings SYMROOT 2> /dev/null; rm XcodeBuildSettings.plist)
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
DSYM_DIR=$(BUILD_DIR)/Growl-dSYM-$(VERSION)
PACKAGE_MAKER=/Developer/Applications/Utilities/PackageMaker.app/Contents/MacOS/PackageMaker
ART_DIR=Artwork

#########################

.PHONY: all assertnochanges assertnoconflicts compile clean release source version

all: assertnochanges version compile release
all-withlocalchanges: assertnoconflicts version compile release

assertnochanges:
	if [[ 0 -ne `hg st | wc -l` ]]; then \
		echo 'You have local changes. Please do not build releases from an unclean working copy. You must revert the changes, commit them, or clone your repository and build from that.' 1>&2; \
		exit 1; \
	fi
assertnoconflicts:
	if [[ 0 -ne `hg resolve --list | grep -E '^U' | wc -l` ]]; then \
		echo 'You have conflicts in your working copy. You will not be able to build until these are resolved. Also, remember that even after you have fixed all conflict marks, you must use "hg resolve" to re-try your last update or merge; otherwise, hg will still believe the files are conflicted.' 1>&2; \
		exit 2; \
	fi

version:
	sed -e "s/INSERT_VERSION_HERE/$(VERSION)/" < "$(SRC_DIR)/GrowlVersion.h.tmpl" > "$(SRC_DIR)/GrowlVersion.h"

compile:
	find $(SRC_DIR) -name build -prune -print0 | xargs -0 rm -R
	$(MAKE) $(BUILDFLAGS) -C $(SRC_DIR)
	$(MAKE) $(BUILDFLAGS) -C $(SRC_DIR)/Extras/GrowlMail
	$(MAKE) $(BUILDFLAGS) -C $(SRC_DIR)/Extras/GrowlSafari
	$(MAKE) $(BUILDFLAGS) -C $(SRC_DIR)/Extras/growlnotify
	$(MAKE) $(BUILDFLAGS) -C $(SRC_DIR)/Extras/HardwareGrowler
	$(MAKE) $(BUILDFLAGS) -C $(SRC_DIR)/Extras/GrowlTunes
	$(MAKE) $(BUILDFLAGS) -C $(SRC_DIR)/Developer\ Tools/BeepHammer


clean:
	rm -rf $(BUILD_DIR)

realclean: clean
	../build.sh clean

release:
	@# clean build directory
	rm -rf $(BUILD_DIR)
	mkdir $(BUILD_DIR)
	mkdir $(GROWL_DIR)
	
	@# Archive dSYM bundles.
	mkdir $(DSYM_DIR)
	mv $(GROWL_BUILD_DIR)/*.dSYM $(DSYM_DIR)
	mv $(GROWLNOTIFY_BUILD_DIR)/*.dSYM $(DSYM_DIR)
	mv $(GROWLTUNES_BUILD_DIR)/*.dSYM $(DSYM_DIR)
	mv $(HARDWAREGROWLER_BUILD_DIR)/*.dSYM $(DSYM_DIR)
	mv $(GROWLMAIL_BUILD_DIR)/*.dSYM $(DSYM_DIR)
	mv $(GROWLSAFARI_BUILD_DIR)/*.dSYM $(DSYM_DIR)
	@# Note: -C only applies to the input names, not -f, so it is correct to use notdir on the directory name and leave it off of the tarball name.
	tar -C $(dir $(DSYM_DIR)) -cjf $(DSYM_DIR).tbz $(notdir $(DSYM_DIR))
	
	@# copy uninstaller
	cp -R "Uninstall Growl.app" $(GROWL_DIR)
	/Developer/Tools/SetFile -a E $(GROWL_DIR)/Uninstall\ Growl.app
	
	@# copy webloc files
	cp "Growl Documentation.webloc" "Growl version history.webloc" "Get more styles.webloc" $(GROWL_DIR)
	
	@# hide extensions of webloc files
	/Developer/Tools/SetFile -a E $(GROWL_DIR)/*.webloc
	
	@# build the prefpane package
	$(PACKAGE_MAKER) --no-relocate --doc Growl/Growl\ Installer.pmdoc --out $(GROWL_DIR)/Growl.pkg --version $(VERSION) --id com.growl.growl.pkg -v
	
	@# copy the extras
	mkdir $(GROWL_DIR)/Extras
	mkdir $(GROWL_DIR)/Extras/growlnotify
	cp $(GROWLNOTIFY_BUILD_DIR)/growlnotify $(GROWL_DIR)/Extras/growlnotify
	cp $(SRC_DIR)/Extras/growlnotify/growlnotify.1 $(GROWL_DIR)/Extras/growlnotify
	cp $(SRC_DIR)/Extras/growlnotify/install.sh $(GROWL_DIR)/Extras/growlnotify
	cp $(SRC_DIR)/Extras/growlnotify/*.txt $(GROWL_DIR)/Extras/growlnotify
	mkdir $(GROWL_DIR)/Extras/GrowlTunes
	cp -R $(GROWLTUNES_BUILD_DIR)/GrowlTunes.app $(GROWL_DIR)/Extras/GrowlTunes
	cp -R $(SRC_DIR)/Extras/GrowlTunes/*.rtfd $(GROWL_DIR)/Extras/GrowlTunes
	mkdir $(GROWL_DIR)/Extras/HardwareGrowler
	cp -R $(HARDWAREGROWLER_BUILD_DIR)/HardwareGrowler.app $(GROWL_DIR)/Extras/HardwareGrowler
	cp $(SRC_DIR)/Extras/HardwareGrowler/*.txt $(GROWL_DIR)/Extras/HardwareGrowler
	
	@# build GrowlMail package
	mkdir $(GROWL_DIR)/Extras/GrowlMail
	$(PACKAGE_MAKER) --no-relocate --doc GrowlMail/GrowlMail\ Installer.pmdoc --out $(GROWL_DIR)/Extras/GrowlMail/GrowlMail.pkg --version $(VERSION) --id com.growl.growlmail.pkg -v	
	cp -R "Uninstall GrowlMail.app" $(GROWL_DIR)/Extras/GrowlMail
	/Developer/Tools/SetFile -a E $(GROWL_DIR)/Extras/GrowlMail/Uninstall\ GrowlMail.app
	cp $(SRC_DIR)/Extras/GrowlMail/*.rtf $(GROWL_DIR)/Extras/GrowlMail
	
	@# build GrowlSafari package
	mkdir $(GROWL_DIR)/Extras/GrowlSafari
	$(PACKAGE_MAKER) --no-relocate --doc GrowlSafari/GrowlSafari\ Installer.pmdoc --out $(GROWL_DIR)/Extras/GrowlSafari/GrowlSafari.pkg --version $(VERSION) --id com.growl.growlsafari.pkg -v	
	
	@# build the SDK
	mkdir $(SDK_DIR)
	
	@# copy the webloc files
	cp "Growl Developer Documentation.webloc" "Growl version history for developers.webloc" $(SDK_DIR)
	
	@# hide extensions of webloc files
	/Developer/Tools/SetFile -a E $(SDK_DIR)/*.webloc
	
	@# copy the scripts
	#cp -R $(SRC_DIR)/Scripts $(GROWL_DIR)
	
	@# copy over beep hammer
	mkdir $(SDK_DIR)/BeepHammer
	cp -R $(SRC_DIR)/Developer\ Tools/BeepHammer/build/$(BUILDSTYLE)/BeepHammer.app $(SDK_DIR)/BeepHammer
	
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
	find $(BUILD_DIR) \( -name "*~" -or -name .DS_Store \) -type f -delete

	@# make Growl disk image
	mkdir $(GROWL_DIR)/.background
	cp $(SRC_DIR)/images/dmg/growlDMGBackground.png $(GROWL_DIR)/.background
	./ensureCustomIconsExtracted $(ART_DIR)
	./make-diskimage.sh $(BUILD_DIR)/$(RELEASE_FILENAME).dmg $(GROWL_DIR) $(RELEASE_NAME) dmg_growl.applescript $(ART_DIR)
	rm $(ART_DIR)/GrowlIcon
	
	@# make SDK disk image
	mkdir $(SDK_DIR)/.background
	cp $(SRC_DIR)/images/dmg/growlSDK.png $(SDK_DIR)/.background
	./make-diskimage.sh $(BUILD_DIR)/$(RELEASE_FILENAME)-SDK.dmg $(SDK_DIR) $(RELEASE_SDK_NAME) dmg_sdk.applescript
	
	@echo Build finished
	-growlnotify -n 'Growl Release Makefile' 'Growl disk image built successfully' -m $(RELEASE_FILENAME).dmg --iconpath $(BUILD_DIR)/$(RELEASE_FILENAME).dmg

framework-archive: assertnochanges
	-mkdir "$(BUILD_DIR)"
	-rm -R "$(FMWK_DIR)"
	mkdir "$(FMWK_DIR)"
	-rm "$(BUILD_DIR)/$(FMWK_TBZ_NAME)"
	
	$(MAKE) $(BUILDFLAGS) -C "$(SRC_DIR)" growlapplicationbridge
	
	cp -R "$(GROWL_BUILD_DIR)/Growl.framework" "$(GROWL_BUILD_DIR)/Growl.framework.dSYM" "$(SRC_DIR)/License.txt" "$(FMWK_DIR)"
	
	tar cjf "$(BUILD_DIR)/$(FMWK_TBZ_NAME)" -C "$(dir $(FMWK_DIR))" "$(notdir $(FMWK_DIR))"
