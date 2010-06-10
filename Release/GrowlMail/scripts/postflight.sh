#!/bin/sh

# Move our temporary installation into the real destination.
mkdir -p ~/Library/Mail/Bundles
rm -R ~/Library/Mail/Bundles/GrowlMail.mailbundle
mv "$2/GrowlMail.mailbundle" ~/Library/Mail/Bundles

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

macosx_minor_version=$(sw_vers | /usr/bin/sed -Ene 's/.*[[:space:]]10\.([0-9][0-9]*)\.*[0-9]*/\1/p;')
if [[ "$macosx_minor_version" == "" ]]; then
	echo 'Unrecognized Mac OS X version!' > /dev/stderr
	sw_vers > /dev/stderr
elif [[ "$macosx_minor_version" -eq 5 ]]; then
	bundle_compatibility_version=3
else
	bundle_compatibility_version=4
fi

defaults write "$domain" EnableBundles -bool YES

# Mac OS X 10.5's Mail.app requires bundle version 3 or greater
defaults write "$domain" BundleCompatibilityVersion -int "$bundle_compatibility_version"

# Remove our temporary directory so that another user account on the same system can install.
rm -R /tmp/GrowlMail-Installation-Temp
