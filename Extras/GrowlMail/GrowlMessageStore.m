//
//  GrowlMailStore.m
//  GrowlMail
//
//  Created by Ingmar Stein on 27.10.04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "GrowlMessageStore.h"
#import "Message+GrowlMail.h"
#import "GrowlMail.h"
#import "GrowlDefines.h"

@implementation GrowlMessageStore
+ (void)load
{
    [GrowlMessageStore poseAsClass:[MessageStore class]];
}

- (id)finishRoutingMessages:(NSArray *)messages routed:(NSArray *)routed
{
	Message *message;
	GrowlMail *growlMail = [GrowlMail sharedInstance];
	if( [growlMail isEnabled] ) {
		BOOL summaryOnly = [growlMail showSummary];
		Class tocClass = [TOCMessage class];
		NSEnumerator *e = [messages objectEnumerator];
		NSMutableDictionary *accountSummary = nil;
		if( summaryOnly ) {
			accountSummary = [[NSMutableDictionary alloc] initWithCapacity:[[MailAccount mailAccounts] count]];
		}
		while( (message = [e nextObject]) ) {
//			NSLog( @"Message class: %@", [message className] );
			MailAccount *account = [[message messageStore] account];
			if( !([message isKindOfClass: tocClass] || ([message isJunk] && [growlMail isIgnoreJunk]))
					&& [growlMail isAccountEnabled:[account path]] ) {
				if( summaryOnly ) {
					NSString *accountName = [account displayName];
					NSNumber *oldCount = [accountSummary objectForKey:accountName];
					int count;
					if( oldCount ) {
						count = [oldCount intValue] + 1;
					} else {
						count = 1;
					}
					[accountSummary setObject:[NSNumber numberWithInt: count] forKey:accountName];
				} else {
					[message showNotification];
				}
			}
		}
		if( summaryOnly ) {
			NSEnumerator *enumerator = [accountSummary keyEnumerator];
			NSBundle *bundle = [GrowlMail bundle];
			NSString *title = NSLocalizedStringFromTableInBundle(@"New mail", nil, bundle, @"");
			NSString *key;
			while( (key = [enumerator nextObject]) ) {
				NSNumber *count = [accountSummary objectForKey:key];
				NSString *description = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%@ - %d new mail(s)", nil, bundle, @""), key, [count intValue]];
				NSDictionary *notif = [NSDictionary dictionaryWithObjectsAndKeys:
					title, GROWL_NOTIFICATION_NAME,
					@"GrowlMail", GROWL_APP_NAME,
					title, GROWL_NOTIFICATION_TITLE,
					[[NSImage imageNamed:@"NSApplicationIcon"] TIFFRepresentation], GROWL_NOTIFICATION_ICON,
					description, GROWL_NOTIFICATION_DESCRIPTION,
					nil];
				[[NSDistributedNotificationCenter defaultCenter] postNotificationName:GROWL_NOTIFICATION
																			   object:nil
																			 userInfo:notif];
			}
		}
	}

	return( [super finishRoutingMessages: messages routed: routed] );
}

@end
