//
//  GrowlRegisterScriptCommand.m
//  Growl
//
//  Created by Ingmar Stein on Tue Nov 09 2004.
//  Copyright (c) 2004 Ingmar Stein. All rights reserved.
//

#import "GrowlRegisterScriptCommand.h"
#import "GrowlController.h"
#import "NSGrowlAdditions.h"

#define KEY_APP_NAME					@"asApplication"
#define KEY_NOTIFICATIONS_ALL			@"allNotifications"
#define KEY_NOTIFICATIONS_DEFAULT		@"defaultNotifications"
#define KEY_ICON_APP_NAME				@"iconOfApplication"

#define ERROR_EXCEPTION						1

static const NSSize iconSize = {128.0f, 128.0f};

@implementation GrowlRegisterScriptCommand

-(id) performDefaultImplementation {
	NSDictionary* args = [self evaluatedArguments];

	// should validate params better!
	NSString *appName = [args valueForKey:KEY_APP_NAME];
	NSArray *allNotifications = [args valueForKey:KEY_NOTIFICATIONS_ALL];
	NSArray *defaultNotifications = [args valueForKey:KEY_NOTIFICATIONS_DEFAULT];
	NSString *iconOfApplication = [args valueForKey:KEY_ICON_APP_NAME];

	NSMutableDictionary* registerDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
		appName, GROWL_APP_NAME,
		allNotifications, GROWL_NOTIFICATIONS_ALL,
		defaultNotifications, GROWL_NOTIFICATIONS_DEFAULT,
		nil];

	NS_DURING
		NSImage* icon = nil;
		if (iconOfApplication) {
			icon = [[NSWorkspace sharedWorkspace] iconForApplication:iconOfApplication];
			if (icon) {
				[icon setSize:iconSize];
				[registerDict setObject:[icon TIFFRepresentation] forKey:GROWL_APP_ICON];
			}
		}

		[[GrowlController singleton] registerApplicationWithDictionary:registerDict];
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
	
	if (str != nil) {
		[self setScriptErrorString:str];
	}
}

@end
