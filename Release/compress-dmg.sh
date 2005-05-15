#!/bin/sh
if [ $# -ne 1  ]; then
	echo "Usage: $0 <prefix>"
else
	hdiutil convert -format UDZO -imagekey zlib-level=9 -o $1-compressed.dmg $1.dmg
	hdiutil convert -format UDZO -imagekey zlib-level=9 -o $1-SDK-compressed.dmg $1-SDK.dmg
	mv $1-compressed.dmg $1.dmg
	mv $1-SDK-compressed.dmg $1-SDK.dmg
fi
