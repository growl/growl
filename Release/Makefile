########################## 
### Versioning: 
###   * Set the VERSION below 
###   * Update the version struct in Core/Source/GrowlApplicationController.m  
###       (needed for proper version checking) 
###   * Update the version string in Extras/growlnotify/main.m 
# 
VERSION=1.1b8
# 
######################### 
# 
# No changes should be needed below this line 
# 
######################### 
RELEASE_NAME=Growl-$(VERSION)

SRC_DIR=..
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

.PHONY: all assertnochanges assertnoconflicts compile-Growl compile-GrowlMail compile-GrowlSafari compile-growlnotify compile-HardwareGrowler compile-GrowlTunes clean release source updateversion-Growl updateversion-GrowlMail updateversion-GrowlSafari updateversion-GrowlTunes updateversion-HardwareGrowler copy-weblocs copy-growlnotify copy-GrowlTunes copy-HardwareGrowler copy-GrowlMail copy-GrowlSafari copy-sdk-weblocs copy-sdk-builtin copy-sdk-frameworks clean-out-garbage

all: assertnochanges updateversion-Growl updateversion-GrowlMail updateversion-GrowlSafari updateversion-GrowlTunes updateversion-HardwareGrowler compile-Growl compile-GrowlMail compile-GrowlSafari compile-growlnotify compile-HardwareGrowler compile-GrowlTunes release $(BUILD_DIR)/$(RELEASE_NAME).dmg $(BUILD_DIR)/$(RELEASE_NAME)-SDK.dmg source
all-withlocalchanges: assertnoconflicts updateversion-Growl updateversion-GrowlMail updateversion-GrowlSafari updateversion-GrowlTunes updateversion-HardwareGrowler compile-Growl compile-GrowlMail compile-GrowlSafari compile-growlnotify compile-HardwareGrowler compile-GrowlTunes release $(BUILD_DIR)/$(RELEASE_NAME).dmg $(BUILD_DIR)/$(RELEASE_NAME)-SDK.dmg source

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

# Update CFBundleVersion and CFBundleShortVersionString.
updateversion-Growl:
	# First, GHA's.
	defaults write $(SRC_DIR)/Core/Resources/GrowlHelperApp-Info.plist CFBundleVersion '$(VERSION)' 
	defaults write $(SRC_DIR)/Core/Resources/GrowlHelperApp-Info.plist CFBundleShortVersionString '$(VERSION)' 
	plutil -convert xml1 $(SRC_DIR)/Core/Resources/GrowlHelperApp-Info.plist 
	# Then, Growl.prefPane's.
	defaults write $(SRC_DIR)/Core/Resources/Info.plist CFBundleVersion '$(VERSION)' 
	defaults write $(SRC_DIR)/Core/Resources/Info.plist CFBundleShortVersionString '$(VERSION)' 
	plutil -convert xml1 $(SRC_DIR)/Core/Resources/Info.plist 
	# Then, GrowlMenu's.
	defaults write $(SRC_DIR)/StatusItem/Resources/MenuExtra-Info.plist CFBundleVersion '$(VERSION)' 
	defaults write $(SRC_DIR)/StatusItem/Resources/MenuExtra-Info.plist CFBundleShortVersionString '$(VERSION)' 
	plutil -convert xml1 $(SRC_DIR)/StatusItem/Resources/MenuExtra-Info.plist 

updateversion-GrowlMail:
	defaults write $(SRC_DIR)/Extras/GrowlMail/Info.plist CFBundleVersion '$(VERSION)' 
	defaults write $(SRC_DIR)/Extras/GrowlMail/Info.plist CFBundleShortVersionString '$(VERSION)' 
	plutil -convert xml1 $(SRC_DIR)/Extras/GrowlMail/Info.plist 

updateversion-GrowlSafari:
	defaults write $(SRC_DIR)/Extras/GrowlSafari/Info.plist CFBundleVersion '$(VERSION)' 
	defaults write $(SRC_DIR)/Extras/GrowlSafari/Info.plist CFBundleShortVersionString '$(VERSION)' 
	plutil -convert xml1 $(SRC_DIR)/Extras/GrowlSafari/Info.plist 

updateversion-GrowlTunes:
	defaults write $(SRC_DIR)/Extras/GrowlTunes/Info.plist CFBundleVersion '$(VERSION)' 
	defaults write $(SRC_DIR)/Extras/GrowlTunes/Info.plist CFBundleShortVersionString '$(VERSION)' 
	plutil -convert xml1 $(SRC_DIR)/Extras/GrowlTunes/Info.plist 

updateversion-HardwareGrowler:
	defaults write $(SRC_DIR)/Extras/HardwareGrowler/Info.plist CFBundleVersion '$(VERSION)' 
	defaults write $(SRC_DIR)/Extras/HardwareGrowler/Info.plist CFBundleShortVersionString '$(VERSION)' 
	plutil -convert xml1 $(SRC_DIR)/Extras/HardwareGrowler/Info.plist 

compile-Growl: updateversion-Growl
	$(MAKE) $(BUILDFLAGS) -C $(SRC_DIR)

compile-GrowlMail: compile-Growl updateversion-GrowlMail
	$(MAKE) $(BUILDFLAGS) -C $(SRC_DIR)/Extras/GrowlMail
compile-GrowlSafari: compile-Growl updateversion-GrowlSafari
	$(MAKE) $(BUILDFLAGS) -C $(SRC_DIR)/Extras/GrowlSafari
compile-growlnotify: compile-Growl
	$(MAKE) $(BUILDFLAGS) -C $(SRC_DIR)/Extras/growlnotify
compile-GrowlTunes: compile-Growl updateversion-GrowlTunes
	$(MAKE) $(BUILDFLAGS) -C $(SRC_DIR)/Extras/GrowlTunes
compile-HardwareGrowler: compile-Growl updateversion-Growl
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
	mkdir $(SRC_BUILD_DIR)

# These targets all copy items from the source tree ($SRCDIR) into $(SRC_BUILD_DIR.
copy-all-sources: $(SRC_BUILD_DIR)/Bindings $(SRC_BUILD_DIR)/Common $(SRC_BUILD_DIR)/Core $(SRC_BUILD_DIR)/Plugins $(SRC_BUILD_DIR)/Docs $(SRC_BUILD_DIR)/Extras $(SRC_BUILD_DIR)/Framework $(SRC_BUILD_DIR)/Growl Readme.rtfd $(SRC_BUILD_DIR)/Growl.xcodeproj $(SRC_BUILD_DIR)/Prefpane TestHarness $(SRC_BUILD_DIR)/Scripts $(SRC_BUILD_DIR)/images $(SRC_BUILD_DIR)/HACKING.TXT $(SRC_BUILD_DIR)/License.txt $(SRC_BUILD_DIR)/Makefile $(SRC_BUILD_DIR)/README.rtf $(SRC_BUILD_DIR)/build.sh $(SRC_BUILD_DIR)/changes.txt $(SRC_BUILD_DIR)/generateSVNRevision.sh $(SRC_BUILD_DIR)/headerDoc2HTML.config

$(SRC_BUILD_DIR)/Bindings: reset-source-dir
	cp -R $(SRC_DIR)/Bindings $(SRC_BUILD_DIR)
$(SRC_BUILD_DIR)/Common: reset-source-dir
	cp -R $(SRC_DIR)/Common $(SRC_BUILD_DIR)
$(SRC_BUILD_DIR)/Core: reset-source-dir
	cp -R $(SRC_DIR)/Core $(SRC_BUILD_DIR)
$(SRC_BUILD_DIR)/Plugins: reset-source-dir
	cp -R $(SRC_DIR)/Plugins $(SRC_BUILD_DIR)
$(SRC_BUILD_DIR)/Docs: reset-source-dir
	cp -R $(SRC_DIR)/Docs $(SRC_BUILD_DIR)
$(SRC_BUILD_DIR)/Extras: reset-source-dir
	cp -R $(SRC_DIR)/Extras $(SRC_BUILD_DIR)
$(SRC_BUILD_DIR)/Framework: reset-source-dir
	cp -R $(SRC_DIR)/Framework $(SRC_BUILD_DIR)
$(SRC_BUILD_DIR)/Growl Readme.rtfd: reset-source-dir
	cp -R $(SRC_DIR)/Growl\ Readme.rtfd $(SRC_BUILD_DIR)
$(SRC_BUILD_DIR)/Growl.xcodeproj: reset-source-dir
	cp -R $(SRC_DIR)/Growl.xcodeproj $(SRC_BUILD_DIR)
$(SRC_BUILD_DIR)/Prefpane TestHarness: reset-source-dir
	cp -R $(SRC_DIR)/Prefpane\ TestHarness $(SRC_BUILD_DIR)
$(SRC_BUILD_DIR)/Scripts: reset-source-dir
	cp -R $(SRC_DIR)/Scripts $(SRC_BUILD_DIR)
$(SRC_BUILD_DIR)/images: reset-source-dir
	cp -R $(SRC_DIR)/images $(SRC_BUILD_DIR)
$(SRC_BUILD_DIR)/HACKING.TXT: reset-source-dir
	cp $(SRC_DIR)/HACKING.txt $(SRC_BUILD_DIR)
$(SRC_BUILD_DIR)/License.txt: reset-source-dir
	cp $(SRC_DIR)/License.txt $(SRC_BUILD_DIR)
$(SRC_BUILD_DIR)/Makefile: reset-source-dir
	cp $(SRC_DIR)/Makefile $(SRC_BUILD_DIR)
$(SRC_BUILD_DIR)/README.rtf: reset-source-dir
	cp $(SRC_DIR)/README.rtf $(SRC_BUILD_DIR)
$(SRC_BUILD_DIR)/build.sh: reset-source-dir
	cp $(SRC_DIR)/build.sh $(SRC_BUILD_DIR)
$(SRC_BUILD_DIR)/changes.txt: reset-source-dir
	cp $(SRC_DIR)/changes.txt $(SRC_BUILD_DIR)
$(SRC_BUILD_DIR)/generateSVNRevision.sh: reset-source-dir
	cp $(SRC_DIR)/generateSVNRevision.sh $(SRC_BUILD_DIR)
$(SRC_BUILD_DIR)/headerDoc2HTML.config: reset-source-dir
	cp $(SRC_DIR)/headerDoc2HTML.config $(SRC_BUILD_DIR)

# Remove files that we don't really want to distribute.
clean-up-sources: copy-all-sources
	find $(SRC_BUILD_DIR) \( -name build -or -name .svn -or -name "*~.nib" \) -type d -exec rm -rf {} \; -prune
	find $(SRC_BUILD_DIR) \( -name "*~" -or -name .DS_Store \) -type f -delete

$(SRC_BUILD_DIR).tar.bz2: copy-all-sources clean-up-sources
	cd $(BUILD_DIR)
	tar cjf "$@" "$(SRC_BUILD_DIR_FILENAME)"

$(BUILD_DIR):
	mkdir $(BUILD_DIR)
$(GROWL_DIR): $(BUILD_DIR)
	mkdir $(GROWL_DIR)
$(SDK_DIR): $(BUILD_DIR)
	mkdir $(SDK_DIR)

release-Growl: $(GROWL_DIR)/Uninstall\ Growl.app copy-weblocs $(GROWL_DIR)/Growl.prefPane copy-growlnotify copy-GrowlTunes copy-HardwareGrowler copy-GrowlMail copy-GrowlSafari
release-SDK: copy-sdk-weblocs $(SRC_DIR)/Scripts copy-sdk-builtin copy-sdk-frameworks $(SDK_DIR)/Bindings
# The two disk-image targets depend on release-Growl and release-SDK, respectively. Thus, making release will make release-Growl and release-SDK, then the disk images.
release: clean $(GROWL_DIR) $(SDK_DIR) $(BUILD_DIR)/$(RELEASE_NAME).dmg $(BUILD_DIR)/$(RELEASE_NAME)-SDK.dmg

# copy uninstaller
$(GROWL_DIR)/Uninstall\ Growl.app: $(GROWL_DIR)
	svn export "Uninstall Growl.app" $(GROWL_DIR)
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
$(GROWL_DIR)/Growl.prefPane: $(GROWL_DIR)
	cp -R $(GROWL_BUILD_DIR)/Growl.prefPane $(GROWL_DIR)

# copy the extras
$(GROWL_DIR)/Extras: $(GROWL_DIR)
	mkdir $(GROWL_DIR)/Extras

copy-growlnotify: $(GROWL_DIR)/Extras/growlnotify $(GROWL_DIR)/Extras/growlnotify/growlnotify $(GROWL_DIR)/Extras/growlnotify/install.sh $(GROWL_DIR)/Extras/growlnotify/README.txt
$(GROWL_DIR)/Extras/growlnotify: $(GROWL_DIR)/Extras
	mkdir $(GROWL_DIR)/Extras/growlnotify
$(GROWL_DIR)/Extras/growlnotify/growlnotify: $(GROWL_DIR)/Extras/growlnotify
	cp $(GROWLNOTIFY_BUILD_DIR)/growlnotify $(GROWL_DIR)/Extras/growlnotify
$(GROWL_DIR)/Extras/growlnotify/growlnotify.1: $(GROWL_DIR)/Extras/growlnotify
	cp $(SRC_DIR)/Extras/growlnotify/growlnotify.1 $(GROWL_DIR)/Extras/growlnotify
$(GROWL_DIR)/Extras/growlnotify/install.sh: $(GROWL_DIR)/Extras/growlnotify
	cp $(SRC_DIR)/Extras/growlnotify/install.sh $(GROWL_DIR)/Extras/growlnotify
$(GROWL_DIR)/Extras/growlnotify/README.txt: $(GROWL_DIR)/Extras/growlnotify
	cp $(SRC_DIR)/Extras/growlnotify/README.txt $(GROWL_DIR)/Extras/growlnotify

copy-GrowlTunes: $(GROWL_DIR)/Extras/GrowlTunes $(GROWL_DIR)/Extras/GrowlTunes/GrowlTunes.app $(GROWL_DIR)/Extras/GrowlTunes/ReadMe.rtfd
$(GROWL_DIR)/Extras/GrowlTunes: $(GROWL_DIR)/Extras
	mkdir $(GROWL_DIR)/Extras/GrowlTunes
$(GROWL_DIR)/Extras/GrowlTunes/GrowlTunes.app: $(GROWL_DIR)/Extras/GrowlTunes
	cp -R $(GROWLTUNES_BUILD_DIR)/GrowlTunes.app $(GROWL_DIR)/Extras/GrowlTunes
$(GROWL_DIR)/Extras/GrowlTunes/ReadMe.rtfd: $(GROWL_DIR)/Extras/GrowlTunes
	svn export $(SRC_DIR)/Extras/GrowlTunes/ReadMe.rtfd $(GROWL_DIR)/Extras/GrowlTunes

copy-HardwareGrowler: $(GROWL_DIR)/Extras/HardwareGrowler
$(GROWL_DIR)/Extras/HardwareGrowler: $(GROWL_DIR)/Extras
	mkdir $(GROWL_DIR)/Extras/HardwareGrowler
$(GROWL_DIR)/Extras/HardwareGrowler/HardwareGrowler.app: $(GROWL_DIR)/Extras/HardwareGrowler
	cp -R $(HARDWAREGROWLER_BUILD_DIR)/HardwareGrowler.app $(GROWL_DIR)/Extras/HardwareGrowler
$(GROWL_DIR)/Extras/HardwareGrowler/readme.txt: $(GROWL_DIR)/Extras/HardwareGrowler
	cp $(SRC_DIR)/Extras/HardwareGrowler/readme.txt $(GROWL_DIR)/Extras/HardwareGrowler

# build GrowlMail package
copy-GrowlMail: $(GROWL_DIR)/Extras/GrowlMail $(GROWL_DIR)/Extras/GrowlMail/GrowlMail.pkg $(GROWL_DIR)/Extras/GrowlMail/GrowlMail\ Installation.rtf
$(GROWL_DIR)/Extras/GrowlMail: $(GROWL_DIR)/Extras
	mkdir $(GROWL_DIR)/Extras/GrowlMail
$(GROWL_DIR)/Extras/GrowlMail/GrowlMail.pkg: $(GROWL_DIR)/Extras/GrowlMail
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
$(GROWL_DIR)/Extras/GrowlSafari/GrowlSafari.pkg: $(GROWL_DIR)/Extras/GrowlSafari
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

# copy the scripts
$(SRC_DIR)/Scripts: $(SDK_DIR)
	cp -R $(SRC_DIR)/Scripts $(GROWL_DIR)

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
$(SDK_DIR)/Frameworks/Growl.framework: $(SDK_DIR)/Frameworks
	cp -R $(GROWL_BUILD_DIR)/Growl.framework $(SDK_DIR)/Frameworks
$(SDK_DIR)/Frameworks/Growl-WithInstaller.framework: $(SDK_DIR)/Frameworks
	cp -R $(GROWL_BUILD_DIR)/Growl-WithInstaller.framework $(SDK_DIR)/Frameworks

# copy the bindings
$(SDK_DIR)/Bindings: $(SDK_DIR)
	svn export $(SRC_DIR)/Bindings $(SDK_DIR)
	@# remove the AppleScript binding
	rm -rf $@/applescript
	@# remove some symlinks
	rm $@/tcl/GrowlDefines.h
	rm $@/tcl/GrowlApplicationBridge.h
	rm $@/tcl/GrowlApplicationBridge.m

# delete svn and backup files
clean-out-garbage:
	find $(BUILD_DIR) -name ".svn" -type d -exec rm -rf {} \; -prune
	find $(BUILD_DIR) \( -name "*~" -or -name .DS_Store -or -name classes.nib -or -name info.nib \) -type f -delete

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
