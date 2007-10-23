#!/bin/sh
######
# Note that we are running sudo'd, so these defaults will be written to
# /Library/Preferences/com.apple.mail.plist
#
# Mail must NOT be running by the time this script executes
######
defaults write com.apple.mail EnableBundles -bool YES

# Mac OS X 10.5's Mail.app requires bundle version 3 or greater
defaults write com.apple.mail BundleCompatibilityVersion -int 3
