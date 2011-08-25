//
//  GrowlLog.m
//  Growl
//
//  Created by Ingmar Stein on 17.04.05.
//  Copyright 2004-2006 The Growl Project. All rights reserved.
//

#include "GrowlLog.h"
#include "GrowlPreferencesController.h"
#include "GrowlDefines.h"

#include <stdarg.h>

void GrowlLog_log(NSString *format, ...) {
	va_list args;
	va_start(args, format);
	
	[[GrowlLog sharedController] writeToLog:format withArguments:args];
	
	va_end(args);
}

void GrowlLog_logNotificationDictionary(NSDictionary *noteDict) {
	[[GrowlLog sharedController] writeNotificationDictionaryToLog:(NSDictionary *)noteDict];
}

void GrowlLog_logRegistrationDictionary(NSDictionary *regDict) {
	[[GrowlLog sharedController] writeRegistrationDictionaryToLog:(NSDictionary *)regDict];
}

NSString *GrowlLog_StringFromRect(NSRect rect) {
	if ([[GrowlLog sharedController] isLoggingEnabled])
		return NSStringFromRect(rect);
	else
		return @"(a rectangle)";
}

static const NSTimeInterval minimumLoggingEnabledFetchInterval = 5.0 * 60.0; //5 minutes

#pragma mark -

static GrowlLog *singleton = nil;

@implementation GrowlLog

+ (GrowlLog *) sharedController {
	if (!singleton)
		singleton = [[GrowlLog alloc] init];

	return singleton;
}

- (id) init {
	if ((self = [super init])) {
		hasFetchedLoggingEnabled = NO;
	}
	return self;
}

- (BOOL) isLoggingEnabled {
	NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
	if (hasFetchedLoggingEnabled && ((now - lastLoggingEnabledFetchTime) < minimumLoggingEnabledFetchInterval)) {
		//Not time yet.
	} else {
		loggingEnabled = [[GrowlPreferencesController sharedController] boolForKey:GrowlLoggingEnabledKey];
		lastLoggingEnabledFetchTime = now;
		hasFetchedLoggingEnabled = YES;
	}

	return loggingEnabled;
}

- (void) writeToLog:(NSString *)format withArguments:(va_list)args {
	if ([self isLoggingEnabled]) {
		GrowlPreferencesController *gpc = [GrowlPreferencesController sharedController];

		NSInteger typePref = [gpc integerForKey:GrowlLogTypeKey];
		if (typePref == 0) {
			NSLogv(format, args);
		} else {
			NSString *logFile = [gpc objectForKey:GrowlCustomHistKey1];
			const char *logFilePath = [logFile fileSystemRepresentation];
			FILE *fp = fopen(logFilePath, "ab");

			if (fp) {
				// NSLog already includes a timestamp; we have to fake it
				NSDate *date = [NSDate date];
				NSString *dateString = [createStringWithDate(date) autorelease];

				fputs([dateString UTF8String], fp);
				fputc(' ', fp);

				NSString *formatted = [[NSString alloc] initWithFormat:format arguments:args];
				fputs([formatted UTF8String], fp);
				[formatted release];
				fputc('\n', fp);

				fclose(fp);
			} else {
				// Falling back to NSLogging...
				if (logFile)
					NSLog(@"Failed to write notification to file %@", logFile);
				NSLogv(format, args);
			}
		}
	}
	
	/* Always log to console for debug builds */
#ifdef DEBUG
	NSLogv(format, args);
#endif
}
- (void) writeToLog:(NSString *)format, ... {
	va_list args;
	va_start(args, format);

	[self writeToLog:format withArguments:args];

	va_end(args);
}

- (void) writeNotificationDictionaryToLog:(NSDictionary *)noteDict {
	if ([self isLoggingEnabled]) {
		[self writeToLog:@"---"];

		int priority;
		NSNumber *priorityNumber = [noteDict objectForKey:GROWL_NOTIFICATION_PRIORITY];
		if (priorityNumber)
			priority = [priorityNumber intValue];
		else
			priority = 0;

		[self writeToLog:@"%@: %@ (%@) - Priority %d",
			[noteDict objectForKey:GROWL_APP_NAME],
			[noteDict objectForKey:GROWL_NOTIFICATION_TITLE],
			[noteDict objectForKey:GROWL_NOTIFICATION_DESCRIPTION],
			priority];
	}
}
- (void) writeRegistrationDictionaryToLog:(NSDictionary *)regDict {
	if ([self isLoggingEnabled])
		[self writeToLog:@"%@ registered", [regDict objectForKey:GROWL_APP_NAME]];
}

@end
