#!/bin/bash
# Script for installing GrowlMail
# This will install GrowlMail, quit Mail, enable plug-ins in Mail, and relaunch Mail. It will move an old GrowlMail (if present) to the trash.
# It uses the home folder as the destination by default, though this can be changed.
#

SRC="$PWD/build"
DEST="$HOME/Library/Mail/Bundles"

echo SRC="$SRC"
echo DEST="$DEST"

if test -e "$DEST"; then
	echo "$0: GrowlMail exists, moving to trash"
	echo "ditto --rsrc \"$SRC/GrowlMail.mailbundle\" \"$HOME/.Trash\""
	ditto --rsrc "$SRC/GrowlMail.mailbundle" "$HOME/.Trash"
	if test ! -d "$SRC/GrowlMail.mailbundle"; then
		echo "rm \"$SRC/GrowlMail.mailbundle\""
		rm "$SRC/GrowlMail.mailbundle"
	fi
else
	echo "$0: GrowlMail is not there, making Bundles folder if necessary"
	echo "mkdir \"$HOME/Library/Mail/Bundles\""
	mkdir "$HOME/Library/Mail/Bundles"
	if test ! -?; then
		echo "$0: Could not create Bundles folder - try repairing your permissions"
	fi
fi
if test ! -e "$SRC/GrowlMail.mailbundle"; then
	echo xcodebuild
	xcodebuild
else
	true
fi
if test -?; then
	echo "ditto --rsrc \"$SRC/GrowlMail.mailbundle\" \"$DEST/GrowlMail.mailbundle\""
	ditto --rsrc "$SRC/GrowlMail.mailbundle" "$DEST/GrowlMail.mailbundle"
fi

echo "$0: Enabling plug-ins in Mail (if they are already enabled, this will have no effect)"
echo defaults write com.apple.mail EnableBundles -bool YES
defaults write com.apple.mail EnableBundles -bool YES
echo defaults write com.apple.mail BundleCompatibilityVersion -int 1
defaults write com.apple.mail BundleCompatibilityVersion -int 1

echo "$0: Relaunching Mail if necessary (if Mail is not already running, this will do nothing)"
if killall -s Mail 2>/dev/null; then
	echo "(osascript -l AppleScript -e 'quit application \"Mail\"') && open -a Mail"
	(osascript -l AppleScript -e 'quit application "Mail"') && open -a Mail
fi
