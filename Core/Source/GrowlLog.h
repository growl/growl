//
//  GrowlLog.h
//  Growl
//
//  Created by Ingmar Stein on 17.04.05.
//  Copyright 2004-2006 The Growl Project. All rights reserved.
//

#ifndef GROWL_LOG_H
#define GROWL_LOG_H

#include <CoreFoundation/CoreFoundation.h>

void GrowlLog_log(NSString *format, ...);
void GrowlLog_logNotificationDictionary(NSDictionary *noteDict);
void GrowlLog_logRegistrationDictionary(NSDictionary *regDict);

#ifdef __OBJC__

//Faster than NSStringFromRect when logging is turned off.
NSString *GrowlLog_StringFromRect(NSRect rect);

@interface GrowlLog: NSObject
{
	NSTimeInterval lastLoggingEnabledFetchTime;
	BOOL hasFetchedLoggingEnabled;
	BOOL loggingEnabled;
}

+ (GrowlLog *) sharedController;

- (BOOL) isLoggingEnabled;

- (void) writeToLog:(NSString *)format, ...;
- (void) writeToLog:(NSString *)format withArguments:(va_list)args;

- (void) writeNotificationDictionaryToLog:(NSDictionary *)noteDict;
- (void) writeRegistrationDictionaryToLog:(NSDictionary *)regDict;

@end

#endif //__OBJC__

#endif
