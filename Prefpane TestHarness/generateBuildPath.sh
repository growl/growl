# Get the local path to the built Growl Prefpane - for loading in the testing app.
mkdir -p $TARGET_BUILD_DIR/include
echo "#define GROWL_OBJROOT @\"$TARGET_BUILD_DIR\"" > $SCRIPT_OUTPUT_FILE_0
