#!/bin/bash

primary=English
for language in German; do
	for f in `find $primary.lproj -name \*.nib -not -name \*~.nib -type d`; do
		nibfile=`basename $f`
		nibname=`basename $f .nib`
		translated="$language.lproj/$nibname-new.nib"
		mkdir -p $language.lproj/$nibfile
		nibtool -d $language.lproj/$nibname.strings $primary.lproj/$nibfile -W $translated
		cp $translated/*.nib $language.lproj/$nibfile
		rm -rf $translated $language.lproj/*~.nib
		echo Updated $language.lproj/$nibfile
	done;
done
