//
//  GrowlRegisterScriptCommand.m
//  Growl
//
//  Created by Ingmar Stein on Tue Nov 09 2004.
//  Copyright (c) 2004 Ingmar Stein. All rights reserved.
//

#import "GrowlRegisterScriptCommand.h"
#import "GrowlController.h"
#import "GrowlDefines.h"
#import "NSGrowlAdditions.h"

#define KEY_APP_NAME					@"asApplication"
#define KEY_NOTIFICATIONS_ALL			@"allNotifications"
#define KEY_NOTIFICATIONS_DEFAULT		@"defaultNotifications"
#define KEY_ICON_APP_NAME				@"iconOfApplication"

#define ERROR_EXCEPTION						1

static const NSSize iconSize = {128.0f, 128.0f};

@implementation GrowlRegisterScriptCommand

- (id) performDefaultImplementation {
	NSDictionary *args = [self evaluatedArguments];

	// should validate params better!
	NSString *appName				= [args objectForKey:KEY_APP_NAME];
	NSArray *allNotifications		= [args objectForKey:KEY_NOTIFICATIONS_ALL];
	NSArray *defaultNotifications	= [args objectForKey:KEY_NOTIFICATIONS_DEFAULT];
	NSString *iconOfApplication		= [args objectForKey:KEY_ICON_APP_NAME];

	//translate AppleScript (1-based) indices to C (0-based) indices
	NSMutableArray *temp = [NSMutableArray arrayWithArray:defaultNotifications];
	NSEnumerator *defaultEnum = [defaultNotifications objectEnumerator];
	NSNumber *num;
	Class NSNumberClass = [NSNumber class];
	unsigned i = 0U;
	while ((num = [defaultEnum nextObject])) {
		if ([num isKindOfClass:NSNumberClass]) {
			//it's an index
			int value = [num intValue];
			if (value < 0) {
				value = [allNotifications count] + value;
			} else if (value > 0) {
				--value;
			} else {
				[self setScriptErrorNumber:errAEIllegalIndex];
				[self setScriptErrorString:@"Can't get item 0 of notifications."];
				return nil;
			}
			[temp replaceObjectAtIndex:i withObject:[NSNumber numberWithUnsignedInt:value]];
		}
		++i;
	}
	defaultNotifications = temp;

	NSMutableDictionary *registerDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
		appName, GROWL_APP_NAME,
		allNotifications, GROWL_NOTIFICATIONS_ALL,
		defaultNotifications, GROWL_NOTIFICATIONS_DEFAULT,
		nil];

	NS_DURING
		if (iconOfApplication) {
			NSData *iconData;
			NSImage *icon = [[NSWorkspace sharedWorkspace] iconForApplication:iconOfApplication];
			if (icon) {
				[icon setSize:iconSize];
				iconData = [icon TIFFRepresentation];
				if (iconData) {
					[registerDict setObject:iconData forKey:GROWL_APP_ICON];
				}
			}
		}

		[[GrowlController standardController] registerApplicationWithDictionary:registerDict];
	NS_HANDLER
		NSLog (@"error processing AppleScript request: %@", localException);
		[self setError:ERROR_EXCEPTION failure:localException];
	NS_ENDHANDLER

	return nil;
}

- (void) setError:(int)errorCode {
	[self setError:errorCode failure:nil];
}

- (void) setError:(int)errorCode failure:(id)failure {
	[self setScriptErrorNumber:errorCode];
	NSString* str;
	
	switch (errorCode) {
		case ERROR_EXCEPTION:
			str = [NSString stringWithFormat:@"Exception raised while processing: %@", failure];
			break;
		default:
			str = nil;
	}
	
	if (str) {
		[self setScriptErrorString:str];
	}
}

@end
