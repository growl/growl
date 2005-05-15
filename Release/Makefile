# These must be absolute paths
BUILD_DIR="$(CURDIR)/build"
RELEASE_DIR="$(CURDIR)"
RELEASE_NAME="Growl-0.7b5"

# What to do before running this script:
# - Set RELEASE_NAME
# - Set version number in GHA
# - Compile with build.sh
# - Build GrowlSafari.mpkg with PackageMaker and copy it into the Release directory
# What to do after running the release target:
# - Build the diskimages with FileStorm using the project files in the build directory
# - Run make finalize

all: release

clean:
	rm -rf $(BUILD_DIR)

release:
	# clean build directory
	rm -rf $(BUILD_DIR)
	mkdir -p $(BUILD_DIR)
	# hide extensions of webloc files
	/Developer/Tools/SetFile -a E *.webloc
	# copy FS templates and substitute paths
	cp -R Growl.fsproj.tmpl $(BUILD_DIR)/Growl.fsproj
	cp -R Growl-SDK.fsproj.tmpl $(BUILD_DIR)/Growl-SDK.fsproj
	perl -pi.bak -e "s'%builddir%'$(BUILD_DIR)'" $(BUILD_DIR)/Growl.fsproj/project.plist
	perl -pi.bak -e "s'%releasedir%'$(RELEASE_DIR)'" $(BUILD_DIR)/Growl.fsproj/project.plist
	perl -pi.bak -e "s'%releasename%'$(RELEASE_NAME)'" $(BUILD_DIR)/Growl.fsproj/project.plist
	perl -pi.bak -e "s'%builddir%'$(BUILD_DIR)'" $(BUILD_DIR)/Growl-SDK.fsproj/project.plist
	perl -pi.bak -e "s'%releasedir%'$(RELEASE_DIR)'" $(BUILD_DIR)/Growl-SDK.fsproj/project.plist
	perl -pi.bak -e "s'%releasename%'$(RELEASE_NAME)'" $(BUILD_DIR)/Growl-SDK.fsproj/project.plist
	# copy the prefpane
	cp -R ../build/Growl.prefPane $(BUILD_DIR)
	# copy the frameworks
	mkdir -p $(BUILD_DIR)/Frameworks
	cp -R ../build/Growl.framework ../build/Growl-WithInstaller.framework $(BUILD_DIR)/Frameworks
	# copy the extras
	mkdir -p $(BUILD_DIR)/Extras
	mkdir -p $(BUILD_DIR)/Extras/growlctl
	cp ../Extras/growlctl/build/growlctl $(BUILD_DIR)/Extras/growlctl
	cp ../Extras/growlctl/growlctl.1 $(BUILD_DIR)/Extras/growlctl
	cp ../Extras/growlctl/install.sh $(BUILD_DIR)/Extras/growlctl
	mkdir -p $(BUILD_DIR)/Extras/GrowlDict
	cp -R ../Extras/GrowlDict/build/GrowlDict.app $(BUILD_DIR)/Extras/GrowlDict
	cp ../Extras/GrowlDict/README.txt $(BUILD_DIR)/Extras/GrowlDict
	mkdir -p $(BUILD_DIR)/Extras/GrowlMail
	cp -R ../Extras/GrowlMail/build/GrowlMail.mailbundle $(BUILD_DIR)/Extras/GrowlMail
	cp ../Extras/GrowlMail/GrowlMail\ Installation.rtf $(BUILD_DIR)/Extras/GrowlMail
	mkdir -p $(BUILD_DIR)/Extras/growlnotify
	cp ../Extras/growlnotify/build/growlnotify $(BUILD_DIR)/Extras/growlnotify
	cp ../Extras/growlnotify/growlnotify.1 $(BUILD_DIR)/Extras/growlnotify
	cp ../Extras/growlnotify/install.sh $(BUILD_DIR)/Extras/growlnotify
	cp ../Extras/growlnotify/README.txt $(BUILD_DIR)/Extras/growlnotify
	mkdir -p $(BUILD_DIR)/Extras/GrowlSafari
	cp -R GrowlSafari.mpkg $(BUILD_DIR)/Extras/GrowlSafari
	cp -R ../Extras/GrowlSafari/README.txt $(BUILD_DIR)/Extras/GrowlSafari
	mkdir -p $(BUILD_DIR)/Extras/GrowlTunes
	cp -R ../Extras/GrowlTunes/build/GrowlTunes.app $(BUILD_DIR)/Extras/GrowlTunes
	cp -R ../Extras/GrowlTunes/ReadMe.rtfd $(BUILD_DIR)/Extras/GrowlTunes
	mkdir -p $(BUILD_DIR)/Extras/HardwareGrowler
	cp -R ../Extras/HardwareGrowler/build/HardwareGrowler.app $(BUILD_DIR)/Extras/HardwareGrowler
	cp ../Extras/HardwareGrowler/readme.txt $(BUILD_DIR)/Extras/HardwareGrowler
	# copy the scripts and bindings
	cp -R ../Scripts $(BUILD_DIR)
	cp -R ../Bindings $(BUILD_DIR)
	# remove the AppleScript binding
	rm -rf $(BUILD_DIR)/Bindings/applescript%
	# remove some symlinks
	rm $(BUILD_DIR)/Bindings/realbasic/GrowlDefines.h
	rm $(BUILD_DIR)/Bindings/tcl/GrowlDefines.h
	rm $(BUILD_DIR)/Bindings/tcl/GrowlApplicationBridge.h
	rm $(BUILD_DIR)/Bindings/tcl/GrowlApplicationBridge.m
	# delete svn and backup files
	find $(BUILD_DIR) -name ".svn" -exec rm -rf {} \; -prune
	find $(BUILD_DIR) -name "*~" -delete
	find $(BUILD_DIR) -name ".DS_Store" -delete
	# open FS projects
	open $(BUILD_DIR)/*.fsproj

finalize:
	./compress-dmg.sh "$(BUILD_DIR)/$(RELEASE_NAME)"
