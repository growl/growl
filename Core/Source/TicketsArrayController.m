//
//  TicketsArrayController.m
//  Growl
//
//  Created by Ingmar Stein on 12.04.05.
//  Copyright 2005-2010 The Growl Project. All rights reserved.
//
//  This file is under the BSD License, refer to License.txt for details

#import "TicketsArrayController.h"
#import "GrowlApplicationTicket.h"
#import "GrowlNotificationTicket.h"

@implementation TicketsArrayController
@synthesize searchString;
@synthesize previousSet;
@synthesize expandedArray;

- (void) dealloc {
	[searchString release];
	[super dealloc];
}

#pragma mark -

- (NSArray *) arrangeObjects:(NSArray *)objects {
   NSSet *newSet = [NSSet setWithArray:objects];
   if ([newSet isEqualToSet:previousSet]) {
      return expandedArray;
   }else{
      NSArray *sorted = [objects sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
      self.previousSet = newSet;
      self.expandedArray = [NSMutableArray arrayWithObject:@"Local"];
      
      BOOL search = (searchString && ![searchString isEqualToString:@""]);
      __block NSString *blockString = searchString;
      __block NSString *previousHost = nil;
      [sorted enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
         if(!search || [[obj appNameHostName] rangeOfString:blockString options:NSLiteralSearch|NSCaseInsensitiveSearch].location != NSNotFound){
            NSString *newHost = [obj hostName];
            if(newHost && ![previousHost isEqualToString:newHost]){
               [expandedArray addObject:newHost];
               previousHost = newHost;
            }
            [expandedArray addObject:obj];
         }
      }];
      return expandedArray;
   }

/*	NSArray *sorted = [objects sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];

	if (!searchString || [searchString isEqualToString:@""]) {
		return [super arrangeObjects:sorted];
	} else {		NSMutableArray *matchedObjects = [NSMutableArray arrayWithCapacity:[sorted count]];

		for (GrowlApplicationTicket *ticket in sorted) {			// Filter application's name

			if ([[ticket appNameHostName] rangeOfString:searchString options:NSLiteralSearch|NSCaseInsensitiveSearch].location != NSNotFound) {
				[matchedObjects addObject:ticket];
			}
		}
		return [super arrangeObjects:matchedObjects];
	}*/
}

- (void) search:(id)sender {
	[self setSearchString:[sender stringValue]];
	[self rearrangeObjects];
}

@end
