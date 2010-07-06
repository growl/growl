//
//  GrowlProcessUtilities.m
//  Growl
//
//  Created by Peter Hosey on 2010-07-05.
//  Copyright 2010 The Growl Project. All rights reserved.
//

#import "GrowlProcessUtilities.h"

#import "GrowlDefinesInternal.h"

//All arguments are optional, meaning that they can be NULL/nil.
static bool Growl_GetPSNForProcessWithBundle(STRING_TYPE bundleIDArg, STRING_TYPE bundlePath, ProcessSerialNumber *outPSN);

#pragma mark -

bool Growl_GetPSNForProcessWithBundlePath(STRING_TYPE bundlePath, ProcessSerialNumber *outPSN) {
	return Growl_GetPSNForProcessWithBundle(/*bundleID*/ nil, bundlePath, outPSN);
}

bool Growl_ProcessExistsWithBundleIdentifier(STRING_TYPE bundleID) {
	return Growl_GetPSNForProcessWithBundle(bundleID, /*bundlePath*/ nil, /*outPSN*/ NULL);
}

bool Growl_HelperAppIsRunning(void) {
	return Growl_ProcessExistsWithBundleIdentifier(GROWL_HELPERAPP_BUNDLE_IDENTIFIER);
}

#pragma mark -

static bool Growl_GetPSNForProcessWithBundle(STRING_TYPE bundleIDArg, STRING_TYPE bundlePathArg, ProcessSerialNumber *outPSN) {
	NSString *theBundleIdentifier = (NSString *)bundleIDArg;
	NSString *theBundlePath = (NSString *)bundlePathArg;
	
	BOOL isRunning = NO;
	ProcessSerialNumber PSN = { 0, kNoProcess };

	//One potential failure case: If both a bundle path and a bundle ID are passed, and a process that matches by bundle ID but not by path comes before a match by path, this loop will return the match by bundle ID.
	//We *should* return the match by path, but covering that corner case while still supporting other modes would make this much slower.
	while (GetNextProcess(&PSN) == noErr) {
		NSDictionary *infoDict = [NSMakeCollectable(ProcessInformationCopyDictionary(&PSN, kProcessDictionaryIncludeAllInformationMask)) autorelease];
		if (infoDict) {
			NSString *bundlePath = [infoDict objectForKey:@"BundlePath"];
			NSString *bundleID = [infoDict objectForKey:(NSString *)kCFBundleIdentifierKey];

			isRunning = bundlePath && theBundlePath && [bundlePath isEqualToString:theBundlePath];
			if (!isRunning)
				isRunning = bundleID && theBundleIdentifier && [bundleID isEqualToString:theBundleIdentifier];
		}

		if (isRunning)
			break;
	}
	
	if (outPSN != NULL) {
		if (!isRunning)
			PSN = (ProcessSerialNumber){ 0, kNoProcess };
		*outPSN = PSN;
	}
	
	return isRunning;
}
