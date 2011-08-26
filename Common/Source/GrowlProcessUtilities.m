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
static BOOL Growl_GetPSNForProcessWithBundle(NSString *bundleIDArg, NSString *bundlePath, ProcessSerialNumber *outPSN);

#pragma mark -

BOOL Growl_GetPSNForProcessWithBundlePath(NSString *bundlePath, ProcessSerialNumber *outPSN) {
	return Growl_GetPSNForProcessWithBundle(/*bundleID*/ nil, bundlePath, outPSN);
}

BOOL Growl_ProcessExistsWithBundleIdentifier(NSString *bundleID) {
	return [[NSRunningApplication runningApplicationsWithBundleIdentifier:bundleID] count];
}

BOOL Growl_HelperAppIsRunning(void) {
	return Growl_ProcessExistsWithBundleIdentifier(GROWL_HELPERAPP_BUNDLE_IDENTIFIER);
}

#pragma mark -

static BOOL Growl_GetPSNForProcessWithBundle(NSString *bundleIDArg, NSString *bundlePathArg, ProcessSerialNumber *outPSN) {
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
