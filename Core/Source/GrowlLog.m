//
//  GrowlLog.m
//  Growl
//
//  Created by Ingmar Stein on 17.04.05.
//  Copyright 2004-2005 The Growl Project. All rights reserved.
//

#import "GrowlLog.h"
#import "GrowlPreferencesController.h"
#import "GrowlDefines.h"
#import "NSDictionaryAdditions.h"

@implementation GrowlLog
+ (void) log:(NSString *)message {
	GrowlPreferencesController *preferences = [GrowlPreferencesController preferences];
	if (![preferences boolForKey:GrowlLoggingEnabledKey])
		return;

	int typePref = [preferences integerForKey:GrowlLogTypeKey];
	if (typePref == 0) {
		NSLog(@"%@", message);
	} else {
		NSString *logFile = [preferences objectForKey:GrowlCustomHistKey1];
		NSFileManager *fileManager = [NSFileManager defaultManager];
		if (![fileManager fileExistsAtPath:logFile])
			[fileManager createFileAtPath:logFile contents:nil attributes:nil];
		NSFileHandle *logHandle = [NSFileHandle fileHandleForWritingAtPath:logFile];
		if (logHandle) {
			[logHandle seekToEndOfFile];
			[logHandle writeData:[[message stringByAppendingString:@"\n"] dataUsingEncoding:NSUTF8StringEncoding]];
			[logHandle closeFile];
		} else  {
			// Falling back to NSLogging...
			if (logFile)
				NSLog(@"Failed to write notification to file %@", logFile);
			NSLog(@"%@", message);
		}
	}
}

+ (void) logNotificationDictionary:(NSDictionary *)noteDict {
	NSString *logString = [[NSString alloc] initWithFormat:@"%@ %@: %@ (%@) - Priority %d",
		[NSDate date],
		[noteDict objectForKey: GROWL_APP_NAME],
		[noteDict objectForKey: GROWL_NOTIFICATION_TITLE],
		[noteDict objectForKey: GROWL_NOTIFICATION_DESCRIPTION],
		[noteDict integerForKey:GROWL_NOTIFICATION_PRIORITY]];
	[self log:logString];
	[logString release];
}

+ (void) logRegistrationDictionary:(NSDictionary *)regDict {
	NSString *logString = [[NSString alloc] initWithFormat:@"%@ %@ registered",
		[NSDate date],
		[regDict objectForKey:GROWL_APP_NAME]];
	[self log:logString];
	[logString release];
}

@end
