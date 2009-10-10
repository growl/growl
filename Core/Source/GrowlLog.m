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

void GrowlLog_log(STRING_TYPE format, ...) {
	va_list args;
	va_start(args, format);
	
	[[GrowlLog sharedController] writeToLog:format withArguments:args];
	
	va_end(args);
}

void GrowlLog_logNotificationDictionary(DICTIONARY_TYPE noteDict) {
	[[GrowlLog sharedController] writeNotificationDictionaryToLog:(NSDictionary *)noteDict];
}

void GrowlLog_logRegistrationDictionary(DICTIONARY_TYPE regDict) {
	[[GrowlLog sharedController] writeRegistrationDictionaryToLog:(NSDictionary *)regDict];
}

#pragma mark -

static GrowlLog *singleton = nil;

@implementation GrowlLog

+ (GrowlLog *) sharedController {
	if (!singleton)
		singleton = [[GrowlLog alloc] init];

	return singleton;
}

- (void) writeToLog:(NSString *)format withArguments:(va_list)args {
	if ([[GrowlPreferencesController sharedController] boolForKey:GrowlLoggingEnabledKey]) {
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
	if ([[GrowlPreferencesController sharedController] boolForKey:GrowlLoggingEnabledKey]) {
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
	if ([[GrowlPreferencesController sharedController] boolForKey:GrowlLoggingEnabledKey])
		[self writeToLog:@"%@ registered", [regDict objectForKey:GROWL_APP_NAME]];
}

@end
