PREFIX?=
PREFERENCEPANES_DIR=$(PREFIX)/Library/PreferencePanes
FRAMEWORKS_DIR=$(PREFIX)/Library/Frameworks
GROWL_PREFPANE=Growl.prefPane
GROWL_FRAMEWORK=Growl.framework
GROWL_HELPER_APP=$(PREFERENCEPANES_DIR)/$(GROWL_PREFPANE)/Contents/Resources/GrowlHelperApp.app
HEADERDOC_DIR=Docs/HeaderDoc

BUILD_DIR?=$(shell defaults read com.apple.Xcode PBXProductDirectory 2> /dev/null)

ifeq ($(strip $(BUILD_DIR)),)
	BUILD_DIR=build
endif

DEFAULT_BUILDCONFIGURATION=Release

BUILDCONFIGURATION?=$(DEFAULT_BUILDCONFIGURATION)

CP=ditto --rsrc
RM=rm

.PHONY : all growl growlhelperapp growlapplicationbridge growlapplicationbridge-withinstaller frameworks clean

all:
	xcodebuild -alltargets -configuration $(BUILDCONFIGURATION) build

growl:
	xcodebuild -target Growl -configuration $(BUILDCONFIGURATION) build

growlhelperapp:
	xcodebuild -target GrowlHelperApp -configuration $(BUILDCONFIGURATION) build

frameworks: growlapplicationbridge growlapplicationbridge-withinstaller

growlapplicationbridge:
	xcodebuild -target Growl.framework -configuration $(BUILDCONFIGURATION) build

growlapplicationbridge-withinstaller:
	xcodebuild -target Growl-WithInstaller.framework -configuration $(BUILDCONFIGURATION) build

clean:
	xcodebuild -alltargets clean

headerdoc:
	rm -rf $(HEADERDOC_DIR)
	headerdoc2html -C -o $(HEADERDOC_DIR) Common/Source/GrowlDefines.h Common/Source/GrowlDefinesInternal.h Framework/Source/*.h Common/Source/GrowlPathUtil.h Plugins/Displays/GrowlDisplayProtocol.h Framework/Source/Growl.hdoc
	gatherheaderdoc $(HEADERDOC_DIR)

localizable-strings:
	genstrings -o Core/Resources/English.lproj Core/Source/*.h Core/Source/*.m
	genstrings -o StatusItem/Resources/English.lproj StatusItem/Source/*.h StatusItem/Source/*.m
	genstrings -o Plugins/Displays/Bezel/English.lproj Plugins/Displays/Bezel/*.h Plugins/Displays/Bezel/*.m
	genstrings -o Plugins/Displays/Brushed/English.lproj Plugins/Displays/Brushed/*.h Plugins/Displays/Brushed/*.m
	genstrings -o Plugins/Displays/Bubbles/English.lproj Plugins/Displays/Bubbles/*.h Plugins/Displays/Bubbles/*.m
	genstrings -o Plugins/Displays/iCal/English.lproj Plugins/Displays/iCal/*.h Plugins/Displays/iCal/*.m
	#genstrings -o Plugins/Displays/Log/English.lproj Plugins/Displays/Log/*.h Plugins/Displays/Log/*.m
	genstrings -o Plugins/Displays/MailMe/English.lproj Plugins/Displays/MailMe/*.h Plugins/Displays/MailMe/*.m
	genstrings -o Plugins/Displays/MusicVideo/English.lproj Plugins/Displays/MusicVideo/*.h Plugins/Displays/MusicVideo/*.m
	genstrings -o Plugins/Displays/Nano/English.lproj Plugins/Displays/Nano/*.h Plugins/Displays/Nano/*.m
	genstrings -o Plugins/Displays/Smoke/English.lproj Plugins/Displays/Smoke/*.h Plugins/Displays/Smoke/*.m
		genstrings -o Plugins/Displays/SMS/English.lproj Plugins/Displays/SMS/*.h Plugins/Displays/SMS/*.m
	genstrings -o Plugins/Displays/Speech/English.lproj Plugins/Displays/Speech/*.h Plugins/Displays/Speech/*.m
	genstrings -o Plugins/Displays/WebKit/English.lproj Plugins/Displays/WebKit/*.h Plugins/Displays/WebKit/*.m
	#genstrings -o Framework/Resources/English.lproj Framework/Source/*.h Framework/Source/*.m Framework/Source/*.c
	genstrings -o Extras/GrowlTunes/English.lproj Extras/GrowlTunes/*.h Extras/GrowlTunes/*.m
	genstrings -o Extras/HardwareGrowler/English.lproj Extras/HardwareGrowler/*.h Extras/HardwareGrowler/*.m Extras/HardwareGrowler/*.c
