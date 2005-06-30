//
//  TicketsArrayController.m
//  Growl
//
//  Created by Ingmar Stein on 12.04.05.
//  Copyright 2005 The Growl Project. All rights reserved.
//
//  This file is under the BSD License, refer to License.txt for details

#import "TicketsArrayController.h"
#import "GrowlApplicationTicket.h"
#import "GrowlApplicationNotification.h"

@implementation TicketsArrayController

- (void) dealloc {
	[searchString release];
	[super dealloc];
}

#pragma mark -

- (NSArray *) arrangeObjects:(NSArray *)objects {
	NSArray *sorted = [objects sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
	if (!searchString || [searchString isEqualToString:@""]) {
		return [super arrangeObjects:sorted];
	} else {
		NSMutableArray *matchedObjects = [NSMutableArray arrayWithCapacity:[sorted count]];
		NSEnumerator *ticketEnum = [sorted objectEnumerator];
		GrowlApplicationTicket *ticket;
		while ((ticket = [ticketEnum nextObject])) {
			// Filter application's name
			if ([[ticket applicationName] rangeOfString:searchString options:NSLiteralSearch|NSCaseInsensitiveSearch].location != NSNotFound) {
				[matchedObjects addObject:ticket];
			} else {
				// Filter notifications
				NSEnumerator *notificationsEnum = [[ticket notifications] objectEnumerator];
				GrowlApplicationNotification *notification;
				while ((notification = [notificationsEnum nextObject])) {
					if ([[notification name] rangeOfString:searchString options:NSLiteralSearch|NSCaseInsensitiveSearch].location != NSNotFound) {
						[matchedObjects addObject:ticket];
						break;
					}
				}
			}
		}
		return [super arrangeObjects:matchedObjects];
	}
}

- (void) search:(id)sender {
	[self setSearchString:[sender stringValue]];
	[self rearrangeObjects];
}

#pragma mark -

- (NSString *) searchString {
	return searchString;
}
- (void) setSearchString:(NSString *)newSearchString {
	if (searchString != newSearchString) {
		[searchString release];
		searchString = [newSearchString copy];
	}
}

@end
