#!/bin/bash
#
# install.sh - Script for installing GrowlMail.
#
# - Build GrowlMail
# - Possibly move old GrowlMail to the Trash.
# - Install new GrowlMail.
# - Enable the plugin in Mail.
# - Relaunch Mail.
#

GROWLMAIL="`dirname $0`"
BUILD="$GROWLMAIL/build"
SRC="$BUILD/GrowlMail.mailbundle"

BUNDLES="$HOME/Library/Mail/Bundles"
DEST="$BUNDLES/GrowlMail.mailbundle"

MV="/bin/mv"
CP="/usr/bin/ditto -v --rsrc"

if [[ -e "$BUILD" ]]; then
	echo "--> Removing old build"
	echo "rm -rf \"$BUILD\""
	rm -fr "$BUILD"
fi
echo "--> Building GrowlMail"
echo "cd \"$GROWLMAIL\" && xcodebuild -buildstyle Deployment \"SYMROOT=$BUILD\" \"OBJROOT=$BUILD\""
(cd "$GROWLMAIL" && xcodebuild -buildstyle Deployment build "SYMROOT=$BUILD" "OBJROOT=$BUILD") || exit 1

if [[ -e "$DEST" ]]; then
	echo "--> GrowlMail exists, moving to Trash."
	echo "$MV \"$DEST\" \"$HOME/.Trash/GrowlMail.mailbundle\""
	$MV "$DEST" "$HOME/.Trash/GrowlMail.mailbundle" || exit 1
fi

echo "--> Creating Bundles folder"
echo "mkdir -p \"$BUNDLES\""
mkdir -p "$BUNDLES" || exit 1

echo "--> Installing GrowlMail"
echo "$CP \"$SRC\" \"$DEST\""
$CP "$SRC" "$DEST" || exit 1

if killall -s Mail >/dev/null 2>/dev/null; then
	echo "--> Quitting Mail"
	echo "osascript -l AppleScript -e 'quit application \"Mail\"'"
	osascript -l AppleScript -e 'quit application "Mail"'
	MAIL_RUNNING=-YES-
fi

echo "--> Enabling plug-ins in Mail (if they are already enabled, this will have no effect)"
echo "defaults write com.apple.mail EnableBundles -bool YES"
defaults write com.apple.mail EnableBundles -bool YES
echo "defaults write com.apple.mail BundleCompatibilityVersion -int 1"
defaults write com.apple.mail BundleCompatibilityVersion -int 1

if [[ ${MAIL_RUNNING:--NO-} == -YES- ]]; then
	echo "--> Relaunching Mail"
	echo "open -a Mail"
	open -a Mail
fi

exit 0
