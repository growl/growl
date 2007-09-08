#!/bin/sh
rm -rf ~/Library/PreferencePanes/Growl.prefPane
sudo rm -rf /Library/PreferencePanes/Growl.prefPane

#The installer will have killed these if this is a fresh install but not if it is an upgrade... where upgrade is defined fairly inconsistently.  Killing the system prefs by name won't work for non-English systems, but the attempt is better than nothing. Optimally, we'd kill the process with the bundle identifier com.apple.systempreferenes.
killall "System Preferences" || TRUE
killall GrowlHelperApp || TRUE
killall GrowlMenu || TRUE