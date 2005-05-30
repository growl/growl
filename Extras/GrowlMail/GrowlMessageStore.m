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

#define MODE_AUTO		0
#define MODE_SINGLE		1
#define MODE_SUMMARY	2

#define AUTO_THRESHOLD	10

#define PendingMessagesKey @"PendingMessages"

@implementation GrowlMessageStore
+ (void) load {
	[GrowlMessageStore poseAsClass:[MessageStore class]];
}

- (void) showSummary:(id)object {
#pragma unused(object)
	NSMutableDictionary *threadDictionary = [[NSThread currentThread] threadDictionary];
	NSArray *collectedMessages = [threadDictionary objectForKey:PendingMessagesKey];

	int summaryMode = [GrowlMail summaryMode];
	if (summaryMode == MODE_AUTO) {
		if ([collectedMessages count] >= AUTO_THRESHOLD)
			summaryMode = MODE_SUMMARY;
		else
			summaryMode = MODE_SINGLE;
	}

	switch (summaryMode) {
		default:
		case MODE_SINGLE:
			[collectedMessages makeObjectsPerformSelector:@selector(showNotification)];
			break;
		case MODE_SUMMARY: {
			NSCountedSet *accountSummary = [[NSCountedSet alloc] initWithCapacity:[[MailAccount mailAccounts] count]];
			NSEnumerator *enumerator = [collectedMessages objectEnumerator];
			Message *message;
			while ((message = [enumerator nextObject]))
				[accountSummary addObject:[[[message messageStore] account] displayName]];
			NSBundle *bundle = [GrowlMail bundle];
			NSString *title = NSLocalizedStringFromTableInBundle(@"New mail", nil, bundle, @"");
			id icon = [NSImage imageNamed:@"NSApplicationIcon"];
			NSString *account;
			enumerator = [accountSummary objectEnumerator];
			while ((account = [enumerator nextObject])) {
				unsigned count = [accountSummary countForObject:account];
				NSString *description = [[NSString alloc] initWithFormat:NSLocalizedStringFromTableInBundle(@"%@ \n%u new mail(s)", nil, bundle, @""), account, count];
				[GrowlApplicationBridge notifyWithTitle:title
											description:description
									   notificationName:NSLocalizedStringFromTableInBundle(@"New mail", nil, bundle, @"")
											   iconData:icon
											   priority:0
											   isSticky:NO
										   clickContext:@""];	// non-nil click context
				[description release];
			}
			[accountSummary release];
			break;
		}
	}

	[threadDictionary removeObjectForKey:PendingMessagesKey];
}

- (id) finishRoutingMessages:(NSArray *)messages routed:(NSArray *)routed {
	if ([GrowlMail isEnabled]) {
		NSMutableDictionary *threadDictionary = [[NSThread currentThread] threadDictionary];
		NSMutableArray *collectedMessages = [threadDictionary objectForKey:PendingMessagesKey];
		if (!collectedMessages) {
			collectedMessages = [[NSMutableArray alloc] init];
			[threadDictionary setObject:collectedMessages forKey:PendingMessagesKey];
			[collectedMessages release];
		}

		Message *message;
		Class tocMessageClass = [TOCMessage class];
		GrowlMail *growlMail = [GrowlMail sharedInstance];
		NSEnumerator *enumerator = [messages objectEnumerator];
		while ((message = [enumerator nextObject])) {
			//NSLog(@"Message class: %@", [message className]);
			if (!([message isKindOfClass:tocMessageClass] || ([message isJunk] && [GrowlMail isIgnoreJunk]))
				&& [growlMail isAccountEnabled:[[[message messageStore] account] path]])
				[collectedMessages addObject:message];
		}
		if ([collectedMessages count])
			// perform selector in the same thread
			[self performSelector:@selector(showSummary:)
					   withObject:nil
					   afterDelay:0.0];
		else
			[threadDictionary removeObjectForKey:PendingMessagesKey];
	}

	return [super finishRoutingMessages:messages routed:routed];
}

@end
