#!/bin/bash
# Script for installing GrowlMail
# This will quit Mail, and then install GrowlMail. It will move old GrowlMail to the trash.
# This will not enable plugins in mail's prefs file currently.
#

killall Mail
HOMEDIR=pwd
if  test -e "$HOME/Library/Mail/Bundles/GrowlMail.mailbundle"
    then
    echo "GrowlMail exists, moving to trash"
    ditto --rsrc $HOME/Library/Mail/Bundles/GrowlMail.mailbundle $HOME/.Trash
    if test ! -d $HOME/Library/Mail/Bundles/GrowlMail.mailbundle; then
        rm $HOME/Library/Mail/Bundles/GrowlMail.mailbundle
    fi
    else
    Echo "GrowlMail is not there, attempting to make Bundles folder"
    mkdir $HOME/Library/Mail/Bundles
fi
if test -e "$PWD/build/GrowlMail.mailbundle/"
    then
    echo "It's there"
    ditto --rsrc $PWD/build/GrowlMail.mailbundle/ $HOME/Library/Mail/Bundles/
    else
    Echo "GrowlMail is not built, you need to build it first."
fi
