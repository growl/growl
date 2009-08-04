#!/bin/sh
######
# Note that we are running sudo'd, so these defaults will be written to
# /Library/Preferences/com.apple.mail.plist
#
# Mail must NOT be running by the time this script executes
######
if [ `whoami` == root ] ; then
    #defaults acts funky when asked to write to the root domain but seems to work with a full path
	domain=/Library/Preferences/com.apple.mail
else
    domain=com.apple.mail
fi

defaults write "$domain" EnableBundles -bool YES

# Mac OS X 10.5's Mail.app requires bundle version 3 or greater
defaults write "$domain" BundleCompatibilityVersion -int 3
