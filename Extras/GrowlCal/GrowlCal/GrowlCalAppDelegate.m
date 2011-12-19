//
//  GrowlCalAppDelegate.m
//  GrowlCal
//
//  Created by Daniel Siemer on 12/19/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "GrowlCalAppDelegate.h"

@implementation GrowlCalAppDelegate

@synthesize window = _window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
   [GrowlApplicationBridge setGrowlDelegate:self];
}

#pragma mark GrowlApplicationBridgeDelegate Methods

- (NSString *) applicationNameForGrowl {
	return @"GrowlCal";
}

- (NSDictionary *) registrationDictionaryForGrowl
{
   NSArray *allNotifications = [NSArray arrayWithObjects:@"EventAlert", 
                                                         @"ToDoAlert", nil];
   NSDictionary *humanReadableNames = [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Event Alert", nil), @"EventAlert",
                                                                                 NSLocalizedString(@"To Do Alert", nil), @"ToDoAlert", nil];
   NSArray *localized = [NSArray arrayWithObjects:NSLocalizedString(@"Shows an alert for upcoming iCal events", @"Event Alert description"),
                                                  NSLocalizedString(@"Shows an alert for upcoming ToDo deadlines", @"ToDo Alert description"), nil];
   
   NSDictionary *regDict = [NSDictionary dictionaryWithObjectsAndKeys:@"GrowlCal", GROWL_APP_NAME,
                                                                      allNotifications, GROWL_NOTIFICATIONS_ALL,
                                                                      humanReadableNames, GROWL_NOTIFICATIONS_HUMAN_READABLE_NAMES,
                                                                      localized, GROWL_NOTIFICATIONS_DESCRIPTIONS, nil];
   
   return regDict;
}

- (void) growlNotificationWasClicked:(id)clickContext
{
   
}

- (BOOL) hasNetworkClientEntitlement
{
   return NO;
}


@end
