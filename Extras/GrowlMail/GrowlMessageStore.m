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

static NSMutableArray *collectedMessages;

@implementation GrowlMessageStore
+ (void) load {
	[GrowlMessageStore poseAsClass:[MessageStore class]];
}

- (void) showSummary {
	Message *message;
	int summaryMode = [GrowlMail summaryMode];

	unsigned messageCount = [collectedMessages count];
	if (summaryMode == MODE_AUTO) {
		if (messageCount >= AUTO_THRESHOLD) {
			summaryMode = MODE_SUMMARY;
		} else {
			summaryMode = MODE_SINGLE;
		}
	}

	switch (summaryMode) {
		default:
		case MODE_SINGLE:
			[collectedMessages makeObjectsPerformSelector:@selector(showNotification)];
			break;
		case MODE_SUMMARY: {
			NSMutableDictionary *accountSummary = [[NSMutableDictionary alloc] initWithCapacity:[[MailAccount mailAccounts] count]];
			NSEnumerator *enumerator = [collectedMessages objectEnumerator];
			while ((message = [enumerator nextObject])) {
				MailAccount *account = [[message messageStore] account];
				NSString *accountName = [account displayName];
				NSNumber *oldCount = [accountSummary objectForKey:accountName];
				int count;
				if (oldCount) {
					count = [oldCount intValue] + 1;
				} else {
					count = 1;
				}
				NSNumber *value = [[NSNumber alloc] initWithInt:count];
				[accountSummary setObject:value forKey:accountName];
				[value release];
			}
			NSBundle *bundle = [GrowlMail bundle];
			NSString *title = NSLocalizedStringFromTableInBundle(@"New mail", nil, bundle, @"");
			NSData *iconData = [[NSImage imageNamed:@"NSApplicationIcon"] TIFFRepresentation];
			NSString *key;
			enumerator = [accountSummary keyEnumerator];
			while ((key = [enumerator nextObject])) {
				NSNumber *count = [accountSummary objectForKey:key];
				NSString *description = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%@ \n%d new mail(s)", nil, bundle, @""), key, [count intValue]];
				[GrowlApplicationBridge notifyWithTitle:title
											description:description
									   notificationName:NSLocalizedStringFromTableInBundle(@"New mail", nil, [GrowlMail bundle], @"")
											   iconData:iconData
											   priority:0
											   isSticky:NO
										   clickContext:@""];	// non-nil click context
			}
			[accountSummary release];
			break;
		}
	}

	[collectedMessages release];
	collectedMessages = nil;
}

- (id) finishRoutingMessages:(NSArray *)messages routed:(NSArray *)routed {
	if ([GrowlMail isEnabled]) {
		if (!collectedMessages) {
			collectedMessages = [[NSMutableArray alloc] init];
			[self performSelectorOnMainThread:@selector(showSummary)
								   withObject:nil
								waitUntilDone:NO];
		}
		Message *message;
		Class tocClass = [TOCMessage class];
		GrowlMail *growlMail = [GrowlMail sharedInstance];
		NSEnumerator *enumerator = [messages objectEnumerator];
		while ((message = [enumerator nextObject])) {
			// NSLog( @"Message class: %@", [message className] );
			if (!([message isKindOfClass: tocClass] || ([message isJunk] && [GrowlMail isIgnoreJunk]))
				&& [growlMail isAccountEnabled:[[[message messageStore] account] path]]) {
				[collectedMessages addObject:message];
			}
		}
	}

	return [super finishRoutingMessages: messages routed: routed];
}

@end
