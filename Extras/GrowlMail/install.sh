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

echo "--> Building GrowlMail."
echo "rm -r \"$BUILD\""
rm -fr "$BUILD"
echo "cd \"$GROWLMAIL\" && xcodebuild -buildstyle Deployment \"SYMROOT=$BUILD\" \"OBJROOT=$BUILD\""
(cd "$GROWLMAIL" && xcodebuild -buildstyle Deployment build "SYMROOT=$BUILD" "OBJROOT=$BUILD") || exit 1

if test -e "$DEST"; then
	echo "--> GrowlMail exists, moving to Trash."
	echo "ditto -v --rsrc \"$DEST\" \"$HOME/.Trash/GrowlMail.mailbundle\""
	ditto -v --rsrc "$DEST" "$HOME/.Trash/GrowlMail.mailbundle" || exit 1
	echo "rm -r \"$DEST\""
	rm -fr "$DEST"
fi

echo "--> Creating Bundles folder."
echo "mkdir -p \"$BUNDLES\""
mkdir -p "$BUNDLES" || exit 1

echo "--> Installing GrowlMail."
echo "ditto -v --rsrc \"$SRC\" \"$DEST\""
ditto -v --rsrc "$SRC" "$DEST" || exit 1

echo "--> Enabling plug-ins in Mail (if they are already enabled, this will have no effect)."
echo defaults write com.apple.mail EnableBundles -bool YES
defaults write com.apple.mail EnableBundles -bool YES
echo defaults write com.apple.mail BundleCompatibilityVersion -int 1
defaults write com.apple.mail BundleCompatibilityVersion -int 1

if killall -s Mail 1>/dev/null 2>/dev/null; then
	echo "--> Relaunching Mail."
	echo "(osascript -l AppleScript -e 'quit application \"Mail\"') && open -a Mail"
	(osascript -l AppleScript -e 'quit application "Mail"') && open -a Mail
fi

exit 0
