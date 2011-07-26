##########################
### Versioning:
###   * Set VERSION below.
###   * make version.
#
VERSION=1.3hg

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
GROWLTUNES_DIR=$(BUILD_DIR)/GrowlTunes
HARDWAREGROWLER_DIR=$(BUILD_DIR)/HardwareGrowler
GROWLNOTIFY_DIR=$(BUILD_DIR)/growlnotify
SDK_DIR=$(BUILD_DIR)/SDK
SAMPLE_DIR=$(BUILD_DIR)/DisplaySample
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
else
	TARGET_BUILD_DIR=$(PRODUCT_DIR)/$(BUILDSTYLE)
	GROWL_BUILD_DIR=$(TARGET_BUILD_DIR)
	GROWLNOTIFY_BUILD_DIR=$(TARGET_BUILD_DIR)
	GROWLTUNES_BUILD_DIR=$(TARGET_BUILD_DIR)
	HARDWAREGROWLER_BUILD_DIR=$(TARGET_BUILD_DIR)
endif
# Use these variables instead of using dir/notdir calls all over the place.
DSYM_DIR_NAME=Growl-dSYM-$(VERSION)
DSYM_PARENT_DIR=$(BUILD_DIR)
DSYM_DIR=$(DSYM_PARENT_DIR)/$(DSYM_DIR_NAME)
DSYM_TBZ=$(DSYM_DIR).tbz
PACKAGE_MAKER=/Developer/Applications/Utilities/PackageMaker.app/Contents/MacOS/PackageMaker
ART_DIR=Artwork

#########################

.PHONY: all all-withlocalchanges assertnochanges assertnoconflicts version clean-all compile compile-growl compile-growlnotify compile-hardwaregrowler compile-growltunes compile-beephammer clean build-dir-clean realclean release release-dsym release-growl release-growltunes release-growlnotify release-hardwaregrowler release-sdk displaysample framework-archive 

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

clean-all:
	@# Note: We need to use .../* in order to not descend into .hg and corrupt the repository.
	find $(SRC_DIR)/* -name build -prune -print0 | xargs -0 rm -R

compile: compile-growl compile-growlnotify compile-hardwaregrowler compile-growltunes compile-beephammer
compile-growl: build-dir-clean
	$(MAKE) $(BUILDFLAGS) -C $(SRC_DIR)
# All of these depend on the hgRevision.h header, and most depend on the Growl framework.
compile-growlnotify: compile-growl
	$(MAKE) $(BUILDFLAGS) -C $(SRC_DIR)/Extras/growlnotify
compile-hardwaregrowler: compile-growl
	$(MAKE) $(BUILDFLAGS) -C $(SRC_DIR)/Extras/HardwareGrowler
compile-growltunes: compile-growl
	$(MAKE) $(BUILDFLAGS) -C $(SRC_DIR)/Extras/GrowlTunes
compile-beephammer: compile-growl
	$(MAKE) $(BUILDFLAGS) -C $(SRC_DIR)/Developer\ Tools/BeepHammer

clean:
	rm -rf $(BUILD_DIR)
build-dir-clean: clean-all
	mkdir $(BUILD_DIR)

realclean: clean
	../build.sh clean

$(DSYM_TBZ): $(DSYM_DIR)
	tar -C $(DSYM_PARENT_DIR) -cjf $(DSYM_TBZ) $(DSYM_DIR_NAME)
$(DSYM_DIR):
	mkdir $(DSYM_DIR)
	mv $(GROWL_BUILD_DIR)/*.dSYM $(DSYM_DIR)
	mv $(GROWLNOTIFY_BUILD_DIR)/*.dSYM $(DSYM_DIR)
	mv $(GROWLTUNES_BUILD_DIR)/*.dSYM $(DSYM_DIR)
	mv $(HARDWAREGROWLER_BUILD_DIR)/*.dSYM $(DSYM_DIR)

$(GROWL_DIR):
	mkdir '$@'
$(GROWL_DIR)/Uninstall\ Growl.app: $(GROWL_DIR)
	cp -R "Uninstall Growl.app" $(GROWL_DIR)
	/Developer/Tools/SetFile -a E $(GROWL_DIR)/Uninstall\ Growl.app
$(GROWL_DIR)/Growl\ Documentation.webloc $(GROWL_DIR)/Growl\ version\ history.webloc $(GROWL_DIR)/Get\ more\ styles.webloc: $(GROWL_DIR)
	cp '$(notdir $@)' '$@'
	/Developer/Tools/SetFile -a E '$@'
$(GROWL_DIR)/Growl.pkg: $(GROWL_DIR)
	$(PACKAGE_MAKER) --no-relocate --doc Growl/Growl\ Installer.pmdoc --out $(GROWL_DIR)/Growl.pkg --version $(VERSION) --id com.growl.growl.pkg -v
# These are temporary; they'll go away once we have an Extras tab.
$(GROWL_DIR)/Extras: $(GROWL_DIR) compile-growltunes compile-hardwaregrowler compile-growlnotify
	mkdir '$@'
$(GROWL_DIR)/Extras/GrowlTunes: $(GROWL_DIR)/Extras $(GROWLTUNES_DIR)
	cp -R '$(GROWLTUNES_DIR)' '$@'
$(GROWL_DIR)/Extras/HardwareGrowler: $(GROWL_DIR)/Extras $(HARDWAREGROWLER_DIR)
	cp -R '$(HARDWAREGROWLER_DIR)' '$@'
$(GROWL_DIR)/Extras/growlnotify: $(GROWL_DIR)/Extras $(GROWLNOTIFY_DIR)
	cp -R '$(GROWLNOTIFY_DIR)' '$@'

$(GROWLTUNES_DIR):
	mkdir '$@'
	cp -R '$(GROWLTUNES_BUILD_DIR)/GrowlTunes.app' '$@'
	cp -R '$(SRC_DIR)'/Extras/GrowlTunes/*.rtfd '$@'
$(HARDWAREGROWLER_DIR):
	mkdir '$@'
	cp -R '$(HARDWAREGROWLER_BUILD_DIR)/HardwareGrowler.app' '$@'
	cp '$(SRC_DIR)'/Extras/HardwareGrowler/*.txt '$@'
$(GROWLNOTIFY_DIR):
	mkdir '$@'
	$(PACKAGE_MAKER) --no-relocate --doc growlnotify/growlnotify.pmdoc --out '$@'/growlnotify.pkg --version $(GROWLNOTIFY_VERSION) --id info.growl.growlnotify.pkg -v	

$(SDK_DIR):
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
	cp -R $(GROWL_BUILD_DIR)/Growl.framework $(SDK_DIR)/Frameworks
	
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

$(BUILD_DIR)/$(RELEASE_FILENAME).dmg: compile-growl $(GROWL_DIR)/Uninstall\ Growl.app $(GROWL_DIR)/Growl\ Documentation.webloc $(GROWL_DIR)/Growl\ version\ history.webloc $(GROWL_DIR)/Get\ more\ styles.webloc $(GROWL_DIR)/Growl.pkg $(GROWL_DIR)/Extras/GrowlMail/GrowlMail.webloc $(GROWL_DIR)/Extras/GrowlSafari $(GROWL_DIR)/Extras/GrowlTunes $(GROWL_DIR)/Extras/HardwareGrowler $(GROWL_DIR)/Extras/growlnotify
	@# make Growl disk image
	mkdir $(GROWL_DIR)/.background
	cp $(SRC_DIR)/images/dmg/GrowlDiskImageBackground.png $(GROWL_DIR)/.background
	./ensureCustomIconsExtracted $(ART_DIR)
	./make-diskimage.sh $(BUILD_DIR)/$(RELEASE_FILENAME).dmg $(GROWL_DIR) $(RELEASE_NAME) dmg_growl.applescript $(ART_DIR)
	rm $(ART_DIR)/GrowlIcon
	
$(BUILD_DIR)/$(RELEASE_FILENAME)-SDK.dmg: $(SDK_DIR)
	@# make SDK disk image
	mkdir $(SDK_DIR)/.background
	cp $(SRC_DIR)/images/dmg/growlSDK.png $(SDK_DIR)/.background
	./make-diskimage.sh $(BUILD_DIR)/$(RELEASE_FILENAME)-SDK.dmg $(SDK_DIR) $(RELEASE_SDK_NAME) dmg_sdk.applescript


release: build-dir-clean release-dsym release-growl release-growltunes release-hardwaregrowler release-growlnotify release-sdk
release-dsym: build-dir-clean $(DSYM_TBZ)
release-growl: build-dir-clean $(BUILD_DIR)/$(RELEASE_FILENAME).dmg
	@echo Build finished
	-growlnotify -n 'Growl Release Makefile' 'Growl disk image built successfully' -m $(RELEASE_FILENAME).dmg --iconpath $(BUILD_DIR)/$(RELEASE_FILENAME).dmg
release-growltunes:
	@#TODO
release-growlnotify:
	@#TODO
release-hardwaregrowler:
	@#TODO
release-sdk: build-dir-clean $(BUILD_DIR)/$(RELEASE_FILENAME)-SDK.dmg

displaysample : 
	@# make the DisplaySample zip
	mkdir -p $(SAMPLE_DIR)
	
	@# copy the Display plugin sample
	cp -R $(SRC_DIR)/Developer\ Tools/SampleDisplay/* $(SAMPLE_DIR)

	@# copy the necessary headers and source files into the bundle
	cp $(SRC_DIR)/Common/Source/CFDictionaryAdditions.h $(SAMPLE_DIR)/source/Growl/
	cp $(SRC_DIR)/Common/Source/CFDictionaryAdditions.c $(SAMPLE_DIR)/source/Growl/
	cp $(SRC_DIR)/Common/Source/CFGrowlDefines.h $(SAMPLE_DIR)/source/Growl/
	cp $(SRC_DIR)/Core/Source/GrowlAbstractSingletonObject.h $(SAMPLE_DIR)/source/Growl/
	cp $(SRC_DIR)/Core/Source/GrowlApplicationNotification.h $(SAMPLE_DIR)/source/Growl/
	cp $(SRC_DIR)/Common/Source/GrowlDefines.h $(SAMPLE_DIR)/source/Growl
	cp $(SRC_DIR)/Common/Source/GrowlDefinesInternal.h $(SAMPLE_DIR)/source/Growl
	cp $(SRC_DIR)/Plugins/Displays/GrowlDisplayPlugin.h $(SAMPLE_DIR)/source/Growl
	cp $(SRC_DIR)/Plugins/Displays/GrowlDisplayWindowController.h $(SAMPLE_DIR)/source/Growl
	cp $(SRC_DIR)/Core/Source/GrowlImageAdditions.h $(SAMPLE_DIR)/source/Growl
	cp $(SRC_DIR)/Core/Source/GrowlImageAdditions.m $(SAMPLE_DIR)/source/Growl
	cp $(SRC_DIR)/Plugins/Displays/GrowlNotificationDisplayBridge.h $(SAMPLE_DIR)/source/Growl
	cp $(SRC_DIR)/Plugins/GrowlPlugin.h $(SAMPLE_DIR)/source/Growl
	cp $(SRC_DIR)/Core/Source/GrowlPositionController.h $(SAMPLE_DIR)/source/Growl
	cp $(SRC_DIR)/Framework/Source/GrowlPositioningDefines.h $(SAMPLE_DIR)/source/Growl
	cp $(SRC_DIR)/Common/Source/NSWindow+Transforms.h $(SAMPLE_DIR)/source/Growl

	cp $(SRC_DIR)/Plugins/Displays/Animation\ \&\ Transitions/Window\ Transitions/GrowlFadingWindowTransition.h $(SAMPLE_DIR)/source/Growl/Transitions
	cp $(SRC_DIR)/Plugins/Displays/Animation\ \&\ Transitions/Window\ Transitions/GrowlFlippingWindowTransition.h $(SAMPLE_DIR)/source/Growl/Transitions
	cp $(SRC_DIR)/Plugins/Displays/Animation\ \&\ Transitions/Window\ Transitions/GrowlScaleWindowTransition.h $(SAMPLE_DIR)/source/Growl/Transitions
	cp $(SRC_DIR)/Plugins/Displays/Animation\ \&\ Transitions/Window\ Transitions/GrowlShrinkingWindowTransition.h $(SAMPLE_DIR)/source/Growl/Transitions
	cp $(SRC_DIR)/Plugins/Displays/Animation\ \&\ Transitions/Window\ Transitions/GrowlSlidingWindowTransition.h $(SAMPLE_DIR)/source/Growl/Transitions
	cp $(SRC_DIR)/Plugins/Displays/Animation\ \&\ Transitions/Window\ Transitions/GrowlWipeWindowTransition.h $(SAMPLE_DIR)/source/Growl/Transitions
	cp $(SRC_DIR)/Plugins/Displays/Animation\ \&\ Transitions/GrowlWindowTransition.h $(SAMPLE_DIR)/source/Growl/Transitions

	@# delete svn and backup files
	find $(BUILD_DIR)/. \( -name ".svn" -or -name build \) -type d -exec rm -rf {} \; -prune
	find $(BUILD_DIR)/. \( -name "*~" -or -name .DS_Store \) -type f -delete

	cd build && zip -r DisplaySample.zip DisplaySample && cd ..

framework-archive: assertnochanges clean-all
	-mkdir "$(BUILD_DIR)"
	-rm -R "$(FMWK_DIR)"
	mkdir "$(FMWK_DIR)"
	-rm "$(BUILD_DIR)/$(FMWK_TBZ_NAME)"
	
	$(MAKE) $(BUILDFLAGS) -C "$(SRC_DIR)" growlapplicationbridge
	
	cp -R "$(GROWL_BUILD_DIR)/Growl.framework" "$(GROWL_BUILD_DIR)/Growl.framework.dSYM" "$(SRC_DIR)/License.txt" "$(FMWK_DIR)"
	
	tar cjf "$(BUILD_DIR)/$(FMWK_TBZ_NAME)" -C "$(dir $(FMWK_DIR))" "$(notdir $(FMWK_DIR))"
