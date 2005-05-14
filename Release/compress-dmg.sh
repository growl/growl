#!/bin/sh
hdiutil convert -format UDZO -imagekey zlib-level=9 -o Growl-0.7b4-compressed.dmg Growl-0.7b4.dmg
hdiutil convert -format UDZO -imagekey zlib-level=9 -o Growl-0.7b4-SDK-compressed.dmg Growl-0.7b4-SDK.dmg
mv Growl-0.7b4-compressed.dmg Growl-0.7b4.dmg
mv Growl-0.7b4-SDK-compressed.dmg Growl-0.7b4-SDK.dmg
