#!/bin/sh
hdiutil convert -format UDZO -imagekey zlib-level=9 -o Growl-0.7b2-compressed.dmg Growl-0.7b2.dmg
hdiutil convert -format UDZO -imagekey zlib-level=9 -o Growl-0.7b2-SDK-compressed.dmg Growl-0.7b2-SDK.dmg
