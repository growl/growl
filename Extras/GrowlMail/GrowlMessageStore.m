/*
 Copyright (c) The Growl Project, 2004-2005
 All rights reserved.

 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:

 1. Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 2. Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in the
 documentation and/or other materials provided with the distribution.
 3. Neither the name of Growl nor the names of its contributors
 may be used to endorse or promote products derived from this software
 without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
 OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 OF THE POSSIBILITY OF SUCH DAMAGE.
*/
//
//  GrowlMessageStore.m
//  GrowlMail
//
//  Created by Ingmar Stein on 27.10.04.
//

#import "GrowlMessageStore.h"
#import "Message+GrowlMail.h"
#import "GrowlMail.h"
#import <Growl/Growl.h>

@implementation GrowlMessageStore
+ (void)load
{
	[GrowlMessageStore poseAsClass:[MessageStore class]];
}

- (id)finishRoutingMessages:(NSArray *)messages routed:(NSArray *)routed
{
	Message *message;
	GrowlMail *growlMail = [GrowlMail sharedInstance];
	if ( [growlMail isEnabled] ) {
		BOOL summaryOnly = [growlMail showSummary];
		Class tocClass = [TOCMessage class];
		NSEnumerator *e = [messages objectEnumerator];
		NSMutableDictionary *accountSummary = nil;
		if ( summaryOnly ) {
			accountSummary = [[NSMutableDictionary alloc] initWithCapacity:[[MailAccount mailAccounts] count]];
		}
		while( (message = [e nextObject]) ) {
//			NSLog( @"Message class: %@", [message className] );
			MailAccount *account = [[message messageStore] account];
			if ( !([message isKindOfClass: tocClass] || ([message isJunk] && [growlMail isIgnoreJunk]))
					&& [growlMail isAccountEnabled:[account path]] ) {
				if ( summaryOnly ) {
					NSString *accountName = [account displayName];
					NSNumber *oldCount = [accountSummary objectForKey:accountName];
					int count;
					if ( oldCount ) {
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
		if ( summaryOnly ) {
			NSEnumerator *enumerator = [accountSummary keyEnumerator];
			NSBundle *bundle = [GrowlMail bundle];
			NSString *title = NSLocalizedStringFromTableInBundle(@"New mail", nil, bundle, @"");
			NSString *key;
			while( (key = [enumerator nextObject]) ) {
				NSNumber *count = [accountSummary objectForKey:key];
				NSString *description = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%@ \n%d new mail(s)", nil, bundle, @""), key, [count intValue]];
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

	return [super finishRoutingMessages: messages routed: routed];
}

@end
