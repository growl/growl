int main (int argc, char **argv) {
	int status = EXIT_SUCCESS;

    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	if (argv[1] == NULL) {
		NSLog(@"%s invoked with no arguments", argv[0]);
		status = EXIT_FAILURE;
		goto end;
	}
	NSString *appPath = [NSString stringWithUTF8String:argv[1]];

	struct LSLaunchURLSpec URLSpec = {
		.appURL = NULL,
		.itemURLs = (CFArrayRef)[NSArray arrayWithObject:[NSURL fileURLWithPath:appPath]],
		.passThruParams = NULL,
		.launchFlags = kLSLaunchNoParams | kLSLaunchDontAddToRecents | kLSLaunchDontSwitch | kLSLaunchAndDisplayErrors,
		.asyncRefCon = NULL, //Because we're doing it synchronously.
	};
	OSStatus err = LSOpenFromURLSpec(&URLSpec, NULL);
	if (err != noErr) {
		NSLog(@"Couldn't launch %@: LSOpenFromURLSpec returned %i/%s", appPath, err, GetMacOSStatusCommentString(err));
		status = EXIT_FAILURE;
		goto end;
	}

end:
    [pool drain];
    return status;
}
