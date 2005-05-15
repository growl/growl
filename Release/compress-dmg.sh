#!/bin/sh
hdiutil convert -format UDZO -imagekey zlib-level=9 -o Growl-0.7b5-compressed.dmg Growl-0.7b5.dmg
hdiutil convert -format UDZO -imagekey zlib-level=9 -o Growl-0.7b5-SDK-compressed.dmg Growl-0.7b5-SDK.dmg
mv Growl-0.7b5-compressed.dmg Growl-0.7b5.dmg
mv Growl-0.7b5-SDK-compressed.dmg Growl-0.7b5-SDK.dmg
