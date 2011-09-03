#We do this so that people who launch Xcode from the UI will be able to run
#hg.  If we come across any other paths here where people would install
#hg by default, we should add them here.
#paths are, in order: homebrew, macports, local, fink
PATH="$PATH:/usr/local/share/python:/opt/local/bin:/usr/local/bin:/sw/bin"

#this is done because the mercurial source install seems to put it in this location
export PYTHONPATH="$PYTHONPATH:/usr/local/lib/python2.6/site-packages:/Library/Python/2.6/site-packages"

#this is done because Xcode won't actually run the script if the output file already exists, which is bad
HEADERPATH="$TARGET_BUILD_DIR/include/hgRevision.h"

#hg parent will present two revisions if the user has a pending merge.
#The user probably shouldn't be building in such a circumstance, but,
#nonetheless, we should handle it sanely. We do this by only showing the
#first parent.
REVISION=`hg parent --template="{rev}\n" | head -n1`
if [[ "x$REVISION" = "x" ]]; then
	#This is not an hg repository. It's probably an archive. Try to determine the archived revision.
	REVISION=`/usr/bin/sed -E -n '/^node:/{ s/node: //; s/^([0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]).*/\1/; p; q; }' < "${SRCROOT}/.hg_archival.txt"`
	if [[ "x$REVISION" = "x" ]]; then
		#Not an archive, either. Weird.
		REVISION=0
	fi
fi
echo "*** Building Growl Revision: $REVISION"
mkdir -p "`dirname "$HEADERPATH"`"

echo "#define HG_REVISION $REVISION" > "$HEADERPATH"
echo "#define HG_REVISION_STRING \"$REVISION\"" >> "$HEADERPATH"
