//
//  GrowlMail.m
//  GrowlMail
//
//  Created by Adam Iser on Mon Jul 26 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "GrowlMail.h"
#import <GrowlAppBridge/GrowlApplicationBridge.h>
#import "GrowlDefines.h"

static NSString *newMail = @"New Mail";
static NSString *mailAppName = @"GrowlMail";


@implementation GrowlMail

+ (void)initialize
{
    [super initialize];
	[self registerBundle];
	NSLog(@"GrowlMail registered");
}

- (id)init
{
	if (self = [super init]) {
		if ([GrowlAppBridge launchGrowlIfInstalledNotifyingTarget:self selector:@selector(gabResponse:) context:nil]) {
			// Register for new mail notification
			[[NSNotificationCenter defaultCenter] addObserver:self
													 selector:@selector(mailAccountFetchCompleted:)
														 name:@"MailAccountFetchCompleted"
													   object:nil];
		} else {
			NSLog(@"Growl not installed, GrowlMail disabled");
		}
	}
	return(self);
}

- (void)gabResponse:(id)context {
	// Register our ticket with Growl
	NSArray *allowedNotifications = [NSArray arrayWithObject:newMail];
	NSDictionary *ticket = [NSDictionary dictionaryWithObjectsAndKeys:
		mailAppName, GROWL_APP_NAME,
		allowedNotifications, GROWL_NOTIFICATIONS_ALL,
		allowedNotifications, GROWL_NOTIFICATIONS_DEFAULT,
		nil];
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:GROWL_APP_REGISTRATION
																   object:nil
																 userInfo:ticket];
}

- (void)mailAccountFetchCompleted:(NSNotification *)notification
{
	MailAccount		*account = [notification object];
	NSDictionary	*userInfo = [notification userInfo];
//	NSLog(@"UserInfo:%@",userInfo);
	
	//New mail
	if([[userInfo objectForKey:@"NewMailWasReceived"] boolValue]){
		//NSLog(@"%@ has received new mail!",[account displayName]);
		NSDictionary *notif = [NSDictionary dictionaryWithObjectsAndKeys:
			newMail, GROWL_NOTIFICATION_NAME,
			mailAppName, GROWL_APP_NAME,
			[account displayName], GROWL_NOTIFICATION_TITLE,
			@"New mail is available", GROWL_NOTIFICATION_DESCRIPTION,
			nil];
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName:GROWL_NOTIFICATION
																	   object:nil
																	 userInfo:notif];
	}
}

/*
	[account primaryMailboxUid]
 + (id)findNewestMessageInMessages:(id)fp8;
 */

@end



