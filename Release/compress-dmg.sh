#!/bin/sh
hdiutil convert -format UDZO -imagekey zlib-level=9 -o Growl-0.7b3-compressed.dmg Growl-0.7b3.dmg
hdiutil convert -format UDZO -imagekey zlib-level=9 -o Growl-0.7b3-SDK-compressed.dmg Growl-0.7b3-SDK.dmg
