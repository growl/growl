#We do this so that people who launch Xcode from the UI will be able to run
#hg.  If we come across any other paths here where people would install
#hg by default, we should add them here.
PATH="$PATH:/opt/local/bin:/usr/local/bin:/sw/bin"
#hg parent will present two revisions if the user has a pending merge.
#The user probably shouldn't be building in such a circumstance, but,
#nonetheless, we should handle it sanely. We do this by only showing the
#first parent.
REVISION=`hg parent --template="{rev}\n" | head -n1`
echo "*** Building Growl Revision: $REVISION"
mkdir -p "`dirname $SCRIPT_OUTPUT_FILE_0`"

echo "#define HG_REVISION $REVISION" > "$SCRIPT_OUTPUT_FILE_0"
echo "#define HG_REVISION_STRING \"$REVISION\"" >> "$SCRIPT_OUTPUT_FILE_0"
