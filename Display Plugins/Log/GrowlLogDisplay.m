//
//  GrowlLogDisplay.m
//  Growl Display Plugins
//
//  Created by Nelson Elhage on 8/23/04.
//  Copyright 2004 Nelson Elhage. All rights reserved.
//

#import "GrowlLogDefines.h"
#import "GrowlLogDisplay.h"
#import "GrowlLogPrefs.h"
#import <GrowlDefinesInternal.h>

@implementation GrowlLogDisplay

- (void) loadPlugin {
}

- (void) unloadPlugin {
}

- (id) init {
	if ((self = [super init])) {
		preferencePane = [[GrowlLogPrefs alloc] initWithBundle:[NSBundle bundleForClass:[GrowlLogPrefs class]]];
	}
	return self;
}

- (void) dealloc {
	[preferencePane release];
	[super dealloc];
}

- (NSPreferencePane *) preferencePane {
	return preferencePane;
}

  - (void)  displayNotificationWithInfo:(NSDictionary *) noteDict {
 	NSString *logString = [NSString stringWithFormat:@"%@ %@: %@ (%@) - Priority %d",
							[[NSDate date] description],
 							[noteDict objectForKey:GROWL_APP_NAME],
  							[noteDict objectForKey:GROWL_NOTIFICATION_TITLE], 
 							[noteDict objectForKey:GROWL_NOTIFICATION_DESCRIPTION],
							[[noteDict objectForKey:GROWL_NOTIFICATION_PRIORITY] intValue] ];
							
 	int typePref = 0;
 	READ_GROWL_PREF_INT(logTypeKey, LogPrefDomain, &typePref);
 	if (typePref == 0) {
 		NSLog(logString);
 	} else {
 		NSString *logFile = nil;
 		BOOL written = NO;
 		READ_GROWL_PREF_VALUE(customHistKey1, LogPrefDomain, NSString *, &logFile);
 		if (![[NSFileManager defaultManager] fileExistsAtPath:logFile]) {
 			[[NSFileManager defaultManager] createFileAtPath:logFile contents:nil attributes:nil];
		}
 		NSFileHandle *logHandle = [NSFileHandle fileHandleForWritingAtPath:logFile];
 		if (logHandle) {
 			[logHandle seekToEndOfFile];
 			[logHandle writeData:[[logString stringByAppendingString:@"\n"] dataUsingEncoding:NSUTF8StringEncoding]];
 			[logHandle closeFile];
 			written = YES;
 		}
 		if (!written) {
 			// Falling back to NSLogging…
			if (logFile) {
				NSLog(@"Failed to write notification to file %@", logFile);
			}
 			NSLog(logString);
 		}
 	}
  }
@end
