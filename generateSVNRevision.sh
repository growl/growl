REVISION=`svnversion .`
echo "*** Building Growl Revision: $REVISION"
mkdir -p $OBJROOT/include
echo "#define SVN_REVISION $REVISION" > $SCRIPT_OUTPUT_FILE_0