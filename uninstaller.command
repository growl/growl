#!/bin/sh

echo Stopping GrowlHelperApp if runnig
echo --
killall GrowlHelperApp || true
echo --
echo To uninstall Growl, you must provide your administrator password
sudo rm -rf /Library/PreferencePanes/Growl.prefPane /Library/Frameworks/GrowlAppBridge.framework