########################## 
### Versioning: 
###   * Set VERSION and BETA below. BETA should be TRUE or FALSE. 
###   * Update the version struct in Core/Source/GrowlApplicationController.m  
###       (needed for proper version checking) 
###   * Update the version string in Extras/growlnotify/main.m 
# 
VERSION=1.1b8
BETA=TRUE
# 
######################### 
# 
# No changes should be needed below this line 
# 
######################### 
RELEASE_NAME=Growl-$(VERSION)

# Why $(PWD), you ask? This is to accomodate our use of defaults write in editing Info.plist files.
# defaults write does its magic by cding to ~/Lib/Preferences, appending .plist to the domain, and opening and mutating and saving that resulting pathname.
#
# This is why that's a problem:
# 	Input domain: ../Core/Resources/GrowlHelperApp-Info.plist
# 	defaults write sets its WD to ~/Library/Preferences
# 	defaults write opens ../Core/Resources/GrowlHelperApp-Info.plist.plist
# 	(that is, ~/Library/Core/Resources/GrowlHelperApp-Info.plist.plist)
#
# Thus, we make sure to specify $(PWD) so that the path is absolute. We also leave off the .plist extension, since defaults write will add it regardless of whether it's there or not.
SRC_DIR=$(PWD)/..
BUILD_DIR=build
GROWL_DIR=$(BUILD_DIR)/Growl
SRC_BUILD_DIR_FILENAME=$(RELEASE_NAME)-src
SRC_BUILD_DIR=$(BUILD_DIR)/$(SRC_BUILD_DIR_FILENAME)
SDK_DIR=$(BUILD_DIR)/SDK
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

#########################

.PHONY: all clean release updateversion-Growl updateversion-GrowlMail updateversion-GrowlSafari updateversion-GrowlTunes updateversion-HardwareGrowler copy-weblocs copy-growlnotify copy-GrowlTunes copy-HardwareGrowler copy-GrowlMail copy-GrowlSafari copy-sdk-weblocs copy-sdk-builtin copy-sdk-frameworks clean-out-garbage source

all: updateversion-Growl updateversion-GrowlMail updateversion-GrowlSafari updateversion-GrowlTunes updateversion-HardwareGrowler $(GROWL_BUILD_DIR)/Growl.prefPane $(GROWLMAIL_BUILD_DIR)/GrowlMail.mailbundle $(GROWLSAFARI_BUILD_DIR)/GrowlSafari $(GROWLNOTIFY_BUILD_DIR)/growlnotify $(GROWLTUNES_BUILD_DIR)/GrowlTunes.app $(HARDWAREGROWLER_BUILD_DIR)/HardwareGrowler.app release $(BUILD_DIR)/$(RELEASE_NAME).dmg $(BUILD_DIR)/$(RELEASE_NAME)-SDK.dmg source $(BUILD_DIR)/$(SRC_BUILD_DIR_FILENAME).tar.bz2

# Update CFBundleVersion and CFBundleShortVersionString in Info.plist files.
updateversion-Growl:
	# First, GHA's.
	defaults write $(SRC_DIR)/Core/Resources/GrowlHelperApp-Info CFBundleVersion '$(VERSION)' 
	defaults write $(SRC_DIR)/Core/Resources/GrowlHelperApp-Info CFBundleShortVersionString '$(VERSION)' 
	plutil -convert xml1 $(SRC_DIR)/Core/Resources/GrowlHelperApp-Info.plist 
	# Then, Growl.prefPane's.
	defaults write $(SRC_DIR)/Core/Resources/Info CFBundleVersion '$(VERSION)' 
	defaults write $(SRC_DIR)/Core/Resources/Info CFBundleShortVersionString '$(VERSION)' 
	plutil -convert xml1 $(SRC_DIR)/Core/Resources/Info.plist 
	# Then, GrowlMenu's.
	defaults write $(SRC_DIR)/StatusItem/Resources/MenuExtra-Info CFBundleVersion '$(VERSION)' 
	defaults write $(SRC_DIR)/StatusItem/Resources/MenuExtra-Info CFBundleShortVersionString '$(VERSION)' 
	plutil -convert xml1 $(SRC_DIR)/StatusItem/Resources/MenuExtra-Info.plist 

updateversion-GrowlMail:
	defaults write $(SRC_DIR)/Extras/GrowlMail/Info CFBundleVersion '$(VERSION)' 
	defaults write $(SRC_DIR)/Extras/GrowlMail/Info CFBundleShortVersionString '$(VERSION)' 
	plutil -convert xml1 $(SRC_DIR)/Extras/GrowlMail/Info.plist 

updateversion-GrowlSafari:
	defaults write $(SRC_DIR)/Extras/GrowlSafari/Info CFBundleVersion '$(VERSION)' 
	defaults write $(SRC_DIR)/Extras/GrowlSafari/Info CFBundleShortVersionString '$(VERSION)' 
	plutil -convert xml1 $(SRC_DIR)/Extras/GrowlSafari/Info.plist 

updateversion-GrowlTunes:
	defaults write $(SRC_DIR)/Extras/GrowlTunes/Info CFBundleVersion '$(VERSION)' 
	defaults write $(SRC_DIR)/Extras/GrowlTunes/Info CFBundleShortVersionString '$(VERSION)' 
	plutil -convert xml1 $(SRC_DIR)/Extras/GrowlTunes/Info.plist 

updateversion-HardwareGrowler:
	defaults write $(SRC_DIR)/Extras/HardwareGrowler/Info CFBundleVersion '$(VERSION)' 
	defaults write $(SRC_DIR)/Extras/HardwareGrowler/Info CFBundleShortVersionString '$(VERSION)' 
	plutil -convert xml1 $(SRC_DIR)/Extras/HardwareGrowler/Info.plist 

$(GROWL_BUILD_DIR)/Growl.prefPane: updateversion-Growl
	$(MAKE) $(BUILDFLAGS) -C $(SRC_DIR)
$(GROWL_BUILD_DIR)/Growl.framework:
	$(MAKE) $(BUILDFLAGS) -C $(SRC_DIR) growlapplicationbridge
$(GROWL_BUILD_DIR)/Growl-WithInstaller.framework:
	$(MAKE) $(BUILDFLAGS) -C $(SRC_DIR) growlapplicationbridge-withinstaller

$(GROWLMAIL_BUILD_DIR)/GrowlMail.mailbundle: $(GROWL_BUILD_DIR)/Growl.prefPane updateversion-GrowlMail
	$(MAKE) $(BUILDFLAGS) -C $(SRC_DIR)/Extras/GrowlMail
$(GROWLSAFARI_BUILD_DIR)/GrowlSafari: $(GROWL_BUILD_DIR)/Growl.prefPane updateversion-GrowlSafari
	$(MAKE) $(BUILDFLAGS) -C $(SRC_DIR)/Extras/GrowlSafari
$(GROWLNOTIFY_BUILD_DIR)/growlnotify: $(GROWL_BUILD_DIR)/Growl.prefPane
	$(MAKE) $(BUILDFLAGS) -C $(SRC_DIR)/Extras/growlnotify
$(GROWLTUNES_BUILD_DIR)/GrowlTunes.app: $(GROWL_BUILD_DIR)/Growl.prefPane updateversion-GrowlTunes
	$(MAKE) $(BUILDFLAGS) -C $(SRC_DIR)/Extras/GrowlTunes
$(HARDWAREGROWLER_BUILD_DIR)/HardwareGrowler.app: $(GROWL_BUILD_DIR)/Growl.prefPane updateversion-HardwareGrowler
	$(MAKE) $(BUILDFLAGS) -C $(SRC_DIR)/Extras/HardwareGrowler

clean:
	-mv $(BUILD_DIR) build-old
	if test -e build-old; then \
		rm -Rf build-old & \
	fi

realclean: clean
	../build.sh clean

source: $(BUILD_DIR)/$(SRC_BUILD_DIR_FILENAME).tar.bz2
# We need this directory to be empty, so blow it away every time. That's why this is a phony target, rather than a real $(SRC_BUILD_DIR) target.
reset-source-dir:
	-rm -rf $(SRC_BUILD_DIR)
	svn export $(SRC_DIR) $(SRC_BUILD_DIR)
$(BUILD_DIR)/$(SRC_BUILD_DIR_FILENAME).tar.bz2: $(BUILD_DIR) reset-source-dir
	cd $(BUILD_DIR) && tar cjf "$(SRC_BUILD_DIR_FILENAME).tar.bz2" "$(SRC_BUILD_DIR_FILENAME)"

$(BUILD_DIR):
	mkdir $(BUILD_DIR)
$(GROWL_DIR): $(BUILD_DIR)
	mkdir $(GROWL_DIR)
$(SDK_DIR): $(BUILD_DIR)
	mkdir $(SDK_DIR)

release-Growl: $(GROWL_DIR)/Uninstall\ Growl.app copy-weblocs $(GROWL_DIR)/Growl.prefPane copy-growlnotify copy-GrowlTunes copy-HardwareGrowler copy-GrowlMail copy-GrowlSafari
release-SDK: copy-sdk-weblocs copy-sdk-builtin copy-sdk-frameworks $(SDK_DIR)/Bindings
# The two disk-image targets depend on release-Growl and release-SDK, respectively. Thus, making release will make release-Growl and release-SDK, then the disk images.
release: clean $(GROWL_DIR) $(SDK_DIR) $(BUILD_DIR)/$(RELEASE_NAME).dmg $(BUILD_DIR)/$(RELEASE_NAME)-SDK.dmg

# copy uninstaller
$(GROWL_DIR)/Uninstall\ Growl.app: $(GROWL_DIR)
	svn export "Uninstall Growl.app" "$@"
	/Developer/Tools/SetFile -a E "$@"

# copy webloc files
copy-weblocs: $(GROWL_DIR)/Growl\ Documentation.webloc $(GROWL_DIR)/Growl\ version\ history.webloc $(GROWL_DIR)/Get\ more\ styles.webloc 
$(GROWL_DIR)/Growl\ Documentation.webloc: $(GROWL_DIR)
	cp "Growl Documentation.webloc" $(GROWL_DIR)
	@# hide extension of webloc file
	/Developer/Tools/SetFile -a E "$@"
$(GROWL_DIR)/Growl\ version\ history.webloc: $(GROWL_DIR)
	cp "Growl version history.webloc" $(GROWL_DIR)
	@# hide extension of webloc file
	/Developer/Tools/SetFile -a E "$@"
$(GROWL_DIR)/Get\ more\ styles.webloc: $(GROWL_DIR)
	cp "Get more styles.webloc" $(GROWL_DIR)
	@# hide extension of webloc file
	/Developer/Tools/SetFile -a E "$@"

# copy the prefpane
$(GROWL_DIR)/Growl.prefPane: $(GROWL_BUILD_DIR)/Growl.prefPane $(GROWL_DIR)
	cp -R $(GROWL_BUILD_DIR)/Growl.prefPane $(GROWL_DIR)

# copy the extras
$(GROWL_DIR)/Extras: $(GROWL_DIR)
	mkdir $(GROWL_DIR)/Extras

copy-growlnotify: $(GROWL_DIR)/Extras/growlnotify $(GROWL_DIR)/Extras/growlnotify/growlnotify $(GROWL_DIR)/Extras/growlnotify/install.sh $(GROWL_DIR)/Extras/growlnotify/README.txt
$(GROWL_DIR)/Extras/growlnotify: $(GROWL_DIR)/Extras
	mkdir $(GROWL_DIR)/Extras/growlnotify
$(GROWL_DIR)/Extras/growlnotify/growlnotify: $(GROWLNOTIFY_BUILD_DIR)/growlnotify $(GROWL_DIR)/Extras/growlnotify
	cp $(GROWLNOTIFY_BUILD_DIR)/growlnotify $(GROWL_DIR)/Extras/growlnotify
$(GROWL_DIR)/Extras/growlnotify/growlnotify.1: $(GROWL_DIR)/Extras/growlnotify
	cp $(SRC_DIR)/Extras/growlnotify/growlnotify.1 $(GROWL_DIR)/Extras/growlnotify
$(GROWL_DIR)/Extras/growlnotify/install.sh: $(GROWL_DIR)/Extras/growlnotify
	cp $(SRC_DIR)/Extras/growlnotify/install.sh $(GROWL_DIR)/Extras/growlnotify
$(GROWL_DIR)/Extras/growlnotify/README.txt: $(GROWL_DIR)/Extras/growlnotify
	cp $(SRC_DIR)/Extras/growlnotify/README.txt $(GROWL_DIR)/Extras/growlnotify

copy-GrowlTunes: $(GROWL_DIR)/Extras/GrowlTunes $(GROWL_DIR)/Extras/GrowlTunes/GrowlTunes.app $(GROWL_DIR)/Extras/GrowlTunes/ReadMe.rtfd
$(GROWL_DIR)/Extras/GrowlTunes: $(GROWLTUNES_BUILD_DIR)/GrowlTunes.app $(GROWL_DIR)/Extras
	mkdir $(GROWL_DIR)/Extras/GrowlTunes
$(GROWL_DIR)/Extras/GrowlTunes/GrowlTunes.app: $(GROWL_DIR)/Extras/GrowlTunes
	cp -R $(GROWLTUNES_BUILD_DIR)/GrowlTunes.app $(GROWL_DIR)/Extras/GrowlTunes
$(GROWL_DIR)/Extras/GrowlTunes/ReadMe.rtfd: $(GROWL_DIR)/Extras/GrowlTunes
	svn export $(SRC_DIR)/Extras/GrowlTunes/ReadMe.rtfd $(GROWL_DIR)/Extras/GrowlTunes

copy-HardwareGrowler: $(GROWL_DIR)/Extras/HardwareGrowler
$(GROWL_DIR)/Extras/HardwareGrowler: $(HARDWAREGROWLER_BUILD_DIR)/HardwareGrowler.app $(GROWL_DIR)/Extras
	mkdir $(GROWL_DIR)/Extras/HardwareGrowler
$(GROWL_DIR)/Extras/HardwareGrowler/HardwareGrowler.app: $(GROWL_DIR)/Extras/HardwareGrowler
	cp -R $(HARDWAREGROWLER_BUILD_DIR)/HardwareGrowler.app $(GROWL_DIR)/Extras/HardwareGrowler
$(GROWL_DIR)/Extras/HardwareGrowler/readme.txt: $(GROWL_DIR)/Extras/HardwareGrowler
	cp $(SRC_DIR)/Extras/HardwareGrowler/readme.txt $(GROWL_DIR)/Extras/HardwareGrowler

# build GrowlMail package
copy-GrowlMail: $(GROWL_DIR)/Extras/GrowlMail $(GROWL_DIR)/Extras/GrowlMail/GrowlMail.pkg $(GROWL_DIR)/Extras/GrowlMail/GrowlMail\ Installation.rtf
$(GROWL_DIR)/Extras/GrowlMail: $(GROWL_DIR)/Extras
	mkdir $(GROWL_DIR)/Extras/GrowlMail
$(GROWL_DIR)/Extras/GrowlMail/GrowlMail.pkg: $(GROWLMAIL_BUILD_DIR)/GrowlMail.mailbundle $(GROWL_DIR)/Extras/GrowlMail
	mkdir $(BUILD_DIR)/GrowlMail
	mkdir $(BUILD_DIR)/GrowlMail-Resources
	cp -R $(GROWLMAIL_BUILD_DIR)/GrowlMail.mailbundle $(BUILD_DIR)/GrowlMail
	cp GrowlMail/InstallationCheck $(BUILD_DIR)/GrowlMail-Resources
	cp GrowlMail/postflight $(BUILD_DIR)/GrowlMail-Resources
	cp -R GrowlMail/English.lproj $(BUILD_DIR)/GrowlMail-Resources
	cp -R GrowlMail/German.lproj $(BUILD_DIR)/GrowlMail-Resources
	-sudo chown -Rh root:admin $(BUILD_DIR)/GrowlMail
	-sudo chmod -R g+w $(BUILD_DIR)/GrowlMail
	/Developer/Tools/packagemaker -build -p $@ -f $(BUILD_DIR)/GrowlMail -ds -v -i GrowlMail/Info.plist -d GrowlMail/Description.plist -r $(BUILD_DIR)/GrowlMail-Resources
	-sudo rm -rf $(BUILD_DIR)/GrowlMail
	rm -rf $(BUILD_DIR)/GrowlMail-Resources
$(GROWL_DIR)/Extras/GrowlMail/GrowlMail\ Installation.rtf: $(GROWL_DIR)/Extras/GrowlMail
	cp $(SRC_DIR)/Extras/GrowlMail/GrowlMail\ Installation.rtf $(GROWL_DIR)/Extras/GrowlMail

# build GrowlSafari package
copy-GrowlSafari: $(GROWL_DIR)/Extras/GrowlSafari $(GROWL_DIR)/Extras/GrowlSafari/GrowlSafari.pkg $(GROWL_DIR)/Extras/GrowlSafari/README.txt
$(GROWL_DIR)/Extras/GrowlSafari: $(GROWL_DIR)/Extras
	mkdir $(GROWL_DIR)/Extras/GrowlSafari
$(GROWL_DIR)/Extras/GrowlSafari/GrowlSafari.pkg: $(GROWLSAFARI_BUILD_DIR)/GrowlSafari $(GROWL_DIR)/Extras/GrowlSafari
	mkdir $(BUILD_DIR)/GrowlSafari
	mkdir $(BUILD_DIR)/GrowlSafari-Resources
	cp -R $(GROWLSAFARI_BUILD_DIR)/GrowlSafari $(BUILD_DIR)/GrowlSafari
	cp GrowlSafari/postupgrade $(BUILD_DIR)/GrowlSafari-Resources
	-sudo chown -Rh root:admin $(BUILD_DIR)/GrowlSafari
	-sudo chmod -R g+w $(BUILD_DIR)/GrowlSafari
	/Developer/Tools/packagemaker -build -p $@ -f $(BUILD_DIR)/GrowlSafari -ds -v -i GrowlSafari/Info.plist -d GrowlSafari/Description.plist -r $(BUILD_DIR)/GrowlSafari-Resources
	-sudo rm -rf $(BUILD_DIR)/GrowlSafari
	rm -rf $(BUILD_DIR)/GrowlSafari-Resources
$(GROWL_DIR)/Extras/GrowlSafari/README.txt: $(GROWL_DIR)/Extras/GrowlSafari
	cp $(SRC_DIR)/Extras/GrowlSafari/README.txt $(GROWL_DIR)/Extras/GrowlSafari

# copy the SDK webloc files
copy-sdk-weblocs: $(SDK_DIR)/Growl\ Developer\ Documentation.webloc $(SDK_DIR)/Growl\ version\ history\ for\ developers.webloc
$(SDK_DIR)/Growl\ Developer\ Documentation.webloc: $(SDK_DIR)
	cp "Growl Developer Documentation.webloc" $(SDK_DIR)
	@# hide extension of webloc file
	/Developer/Tools/SetFile -a E "$@"
$(SDK_DIR)/Growl\ version\ history\ for\ developers.webloc: $(SDK_DIR)
	cp "Growl version history for developers.webloc" $(SDK_DIR)
	@# hide extension of webloc file
	/Developer/Tools/SetFile -a E "$@"

# copy over relevant files to compile directly into app
copy-sdk-builtin: $(SDK_DIR)/Built-In $(SDK_DIR)/Built-In/GrowlApplicationBridge.h $(SDK_DIR)/Built-In/GrowlApplicationBridge.m $(SDK_DIR)/Built-In/GrowlDefines.h $(SDK_DIR)/Built-In/GrowlDefinesInternal.h $(SDK_DIR)/Built-In/GrowlPathUtilities.h $(SDK_DIR)/Built-In/GrowlPathUtilities.m $(SDK_DIR)/Built-In/CFGrowlAdditions.h $(SDK_DIR)/Built-In/CFGrowlAdditions.c $(SDK_DIR)/Built-In/CFGrowlDefines.h $(SDK_DIR)/Built-In/CFURLAdditions.h $(SDK_DIR)/Built-In/CFURLAdditions.c $(SDK_DIR)/Built-In/CFMutableDictionaryAdditions.h $(SDK_DIR)/Built-In/CFMutableDictionaryAdditions.c $(SDK_DIR)/Built-In/GrowlPreferencesController.h $(SDK_DIR)/Built-In/GrowlTicketController.h 

$(SDK_DIR)/Built-In: $(SDK_DIR)
	mkdir $(SDK_DIR)/Built-In
$(SDK_DIR)/Built-In/GrowlApplicationBridge.h: $(SDK_DIR)/Built-In
	cp $(SRC_DIR)/Framework/Source/GrowlApplicationBridge.h $(SDK_DIR)/Built-In
$(SDK_DIR)/Built-In/GrowlApplicationBridge.m: $(SDK_DIR)/Built-In
	cp $(SRC_DIR)/Framework/Source/GrowlApplicationBridge.m $(SDK_DIR)/Built-In
$(SDK_DIR)/Built-In/GrowlDefines.h: $(SDK_DIR)/Built-In
	cp $(SRC_DIR)/Common/Source/GrowlDefines.h $(SDK_DIR)/Built-In
$(SDK_DIR)/Built-In/GrowlDefinesInternal.h: $(SDK_DIR)/Built-In
	cp $(SRC_DIR)/Common/Source/GrowlDefinesInternal.h $(SDK_DIR)/Built-In
$(SDK_DIR)/Built-In/GrowlPathUtilities.h: $(SDK_DIR)/Built-In
	cp $(SRC_DIR)/Common/Source/GrowlPathUtilities.h $(SDK_DIR)/Built-In
$(SDK_DIR)/Built-In/GrowlPathUtilities.m: $(SDK_DIR)/Built-In
	cp $(SRC_DIR)/Common/Source/GrowlPathUtilities.m $(SDK_DIR)/Built-In 
$(SDK_DIR)/Built-In/CFGrowlAdditions.h: $(SDK_DIR)/Built-In
	cp $(SRC_DIR)/Common/Source/CFGrowlAdditions.h $(SDK_DIR)/Built-In
$(SDK_DIR)/Built-In/CFGrowlAdditions.c: $(SDK_DIR)/Built-In
	cp $(SRC_DIR)/Common/Source/CFGrowlAdditions.c $(SDK_DIR)/Built-In
$(SDK_DIR)/Built-In/CFGrowlDefines.h: $(SDK_DIR)/Built-In
	cp $(SRC_DIR)/Common/Source/CFGrowlDefines.h $(SDK_DIR)/Built-In
$(SDK_DIR)/Built-In/CFURLAdditions.h: $(SDK_DIR)/Built-In
	cp $(SRC_DIR)/Common/Source/CFURLAdditions.h $(SDK_DIR)/Built-In
$(SDK_DIR)/Built-In/CFURLAdditions.c: $(SDK_DIR)/Built-In
	cp $(SRC_DIR)/Common/Source/CFURLAdditions.c $(SDK_DIR)/Built-In
$(SDK_DIR)/Built-In/CFMutableDictionaryAdditions.h: $(SDK_DIR)/Built-In
	cp $(SRC_DIR)/Common/Source/CFMutableDictionaryAdditions.h $(SDK_DIR)/Built-In
$(SDK_DIR)/Built-In/CFMutableDictionaryAdditions.c: $(SDK_DIR)/Built-In
	cp $(SRC_DIR)/Common/Source/CFMutableDictionaryAdditions.c $(SDK_DIR)/Built-In
$(SDK_DIR)/Built-In/GrowlPreferencesController.h: $(SDK_DIR)/Built-In
	cp $(SRC_DIR)/Core/Source/GrowlPreferencesController.h $(SDK_DIR)/Built-In
$(SDK_DIR)/Built-In/GrowlTicketController.h: $(SDK_DIR)/Built-In
	cp $(SRC_DIR)/Core/Source/GrowlTicketController.h $(SDK_DIR)/Built-In

# copy the frameworks
copy-sdk-frameworks: $(SDK_DIR)/Frameworks $(SDK_DIR)/Frameworks/Growl.framework $(SDK_DIR)/Frameworks/Growl-WithInstaller.framework
$(SDK_DIR)/Frameworks: $(SDK_DIR)
	mkdir $(SDK_DIR)/Frameworks
$(SDK_DIR)/Frameworks/Growl.framework: $(GROWL_BUILD_DIR)/Growl.framework $(SDK_DIR)/Frameworks
	cp -R $(GROWL_BUILD_DIR)/Growl.framework $(SDK_DIR)/Frameworks
$(SDK_DIR)/Frameworks/Growl-WithInstaller.framework: $(GROWL_BUILD_DIR)/Growl-WithInstaller.framework $(SDK_DIR)/Frameworks
	cp -R $(GROWL_BUILD_DIR)/Growl-WithInstaller.framework $(SDK_DIR)/Frameworks

# copy the bindings
$(SDK_DIR)/Bindings: $(SDK_DIR)
	svn export $(SRC_DIR)/Bindings $@
	@# remove the AppleScript binding
	rm -rf $@/applescript
	@# remove some symlinks
	rm $@/tcl/GrowlDefines.h
	rm $@/tcl/GrowlApplicationBridge.h
	rm $@/tcl/GrowlApplicationBridge.m

# delete svn and backup files
clean-out-garbage:
	find $(BUILD_DIR) -name ".svn" -type d -exec rm -rf {} \; -prune
	find $(BUILD_DIR) \( -name "*~" -or -name .DS_Store \) -type f -delete 
	
	@# optimize nib files, making them uneditable, for releases only 
ifeq ($(BETA),FALSE) 
	find $(BUILD_DIR) \( -name classes.nib -or -name info.nib \) -type f -delete
endif 

# make Growl disk image
$(BUILD_DIR)/$(RELEASE_NAME).dmg: release-Growl clean-out-garbage
	mkdir $(GROWL_DIR)/.background
	cp $(SRC_DIR)/images/dmg/growlDMGBackground.png $(GROWL_DIR)/.background
	./make-diskimage.sh $@ $(GROWL_DIR) Growl dmg_growl.applescript

# make SDK disk image
$(BUILD_DIR)/$(RELEASE_NAME)-SDK.dmg: release-SDK clean-out-garbage
	mkdir $(SDK_DIR)/.background
	cp $(SRC_DIR)/images/dmg/growlSDK.png $(SDK_DIR)/.background
	./make-diskimage.sh $@ $(SDK_DIR) Growl-SDK dmg_sdk.applescript
	@echo Build finished
