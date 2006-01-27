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

static void performLog(CFStringRef message) {
	int typePref = GrowlPreferencesController_integerForKey(GrowlLogTypeKey);
	if (typePref == 0) {
		NSLog(CFSTR("%@"), message);
	} else {
		CFStringRef logFile = GrowlPreferencesController_objectForKey(GrowlCustomHistKey1);
		char *logFilePath = createFileSystemRepresentationOfString(logFile);
		FILE *fp = fopen(logFilePath, "ab");
		free(logFilePath);
		if (fp) {
			char *data;

			// NSLog already includes a timestamp
			CFDateRef date = CFDateCreate(kCFAllocatorDefault, CFAbsoluteTimeGetCurrent());
			CFStringRef dateString = createStringWithDate(date);
			CFRelease(date);
			data = copyCString(dateString, kCFStringEncodingUTF8);
			CFRelease(dateString);
			fputs(data, fp);
			fputc(' ', fp);
			free(data);

			data = copyCString(message, kCFStringEncodingUTF8);
			fputs(data, fp);
			fputc('\n', fp);
			free(data);
			fclose(fp);
		} else {
			// Falling back to NSLogging...
			if (logFile)
				NSLog(CFSTR("Failed to write notification to file %@"), logFile);
			NSLog(CFSTR("%@"), message);
		}
	}
}

void GrowlLog_log(CFStringRef message) {
	if (GrowlPreferencesController_boolForKey(GrowlLoggingEnabledKey))
		performLog(message);
}

void GrowlLog_logNotificationDictionary(CFDictionaryRef noteDict) {
	if (GrowlPreferencesController_boolForKey(GrowlLoggingEnabledKey)) {
		int priority;
		CFNumberRef priorityNumber = CFDictionaryGetValue(noteDict, GROWL_NOTIFICATION_PRIORITY);
		if (priorityNumber)
			CFNumberGetValue(priorityNumber, kCFNumberIntType, &priority);
		else
			priority = 0;
		CFStringRef logString = CFStringCreateWithFormat(kCFAllocatorDefault,
														 NULL,
														 CFSTR("%@: %@ (%@) - Priority %d"),
														 CFDictionaryGetValue(noteDict, GROWL_APP_NAME),
														 CFDictionaryGetValue(noteDict, GROWL_NOTIFICATION_TITLE),
														 CFDictionaryGetValue(noteDict, GROWL_NOTIFICATION_DESCRIPTION),
														 priority);
		performLog(logString);
		CFRelease(logString);
	}
}

void GrowlLog_logRegistrationDictionary(CFDictionaryRef regDict) {
	if (GrowlPreferencesController_boolForKey(GrowlLoggingEnabledKey)) {
		CFStringRef logString = CFStringCreateWithFormat(kCFAllocatorDefault,
														 NULL,
														 CFSTR("%@ registered"),
														 CFDictionaryGetValue(regDict, GROWL_APP_NAME));
		performLog(logString);
		CFRelease(logString);
	}
}
