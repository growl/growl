//
//  GrowlPropertyListFilePathway.m
//  Growl
//
//  Created by Peter Hosey on 2008-02-07.
//  Copyright 2008 Peter Hosey. All rights reserved.
//

#import "GrowlPropertyListFilePathway.h"

#import "GrowlApplicationController.h"
#include "CFGrowlAdditions.h"
#import "NSStringAdditions.h"

static GrowlPropertyListFilePathway *sharedController = nil;

@implementation GrowlPropertyListFilePathway

+ (GrowlPropertyListFilePathway *) standardPathway {
	if (!sharedController)
		sharedController = [[GrowlPropertyListFilePathway alloc] init];
	
	return sharedController;
}

#pragma mark Opening files

//If you're looking for GHA's app delegate, try GrowlApplicationController. That -application:openFile: method calls this one to handle .growlRegDict files.
- (BOOL) application:(NSApplication *)theApplication openFile:(NSString *)filename {
#pragma unused(theApplication)
	BOOL retVal = NO;

	CFURLRef fileURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (CFStringRef)filename, kCFURLPOSIXPathStyle, false);
	NSDictionary *regDict = (NSDictionary *)createPropertyListFromURL((NSURL *)fileURL, kCFPropertyListImmutable, NULL, NULL);
	CFRelease(fileURL);

	/*GrowlApplicationBridge 0.6 communicates registration to Growl by
	 *	writing a dictionary file to the temporary items folder, then
	 *	opening the file with GrowlHelperApp.
	 *we need to delete these, lest we fill up the user's disk or (on Tiger)
	 *	surprise him with a 'Recovered items' folder in his Trash.
	 */
	if ([filename isSubpathOf:NSTemporaryDirectory()]) //assume we got here from GAB
		[[NSFileManager defaultManager] removeFileAtPath:filename handler:nil];

	if (regDict) {
		//Register this app using the indicated dictionary
		[self registerApplicationWithDictionary:regDict];
		[regDict release];

		retVal = YES;
	}

	return retVal;
}

@end
