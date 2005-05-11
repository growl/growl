#!/bin/sh
hdiutil convert -format UDZO -imagekey zlib-level=9 -o Growl-0.7b1-compressed.dmg Growl-0.7b1.dmg
hdiutil convert -format UDZO -imagekey zlib-level=9 -o Growl-0.7b1-SDK-compressed.dmg Growl-0.7b1-SDK.dmg
