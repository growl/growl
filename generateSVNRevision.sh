REVISION=`svnversion .`
echo "*** Building Growl Revision: $REVISION"
mkdir -p $OBJROOT/include
#SVN_REVISION is a string because it may look like "4168M" or "4123:4168MS"
echo "#define SVN_REVISION \"$REVISION\"" > $SCRIPT_OUTPUT_FILE_0
