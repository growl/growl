#!/bin/bash

echo Stopping GrowlHelperApp if running
echo --
killall GrowlHelperApp || true
echo --
echo To uninstall Growl, you must provide your administrator password
echo --
echo Growl files will be moved to the trash
if test -d "/Library/PreferencePanes/Growl.prefPane"
    then
    sudo mv /Library/PreferencePanes/Growl.prefPane ~/.Trash
elif test -d "$HOME/Library/PreferencePanes/Growl.prefPane"
    then
    sudo mv $HOME/Library/PreferencePanes/Growl.prefPane ~/.Trash
fi
if test -d "/Library/Frameworks/GrowlAppBridge.framework"
    then
    sudo mv /Library/Frameworks/GrowlAppBridge.framework ~/.Trash
elif test -d "$HOME/Library/Frameworks/GrowlAppBridge.framework"
    then
    sudo mv $HOME/Library/Frameworks/GrowlAppBridge.framework ~/.Trash
fi
