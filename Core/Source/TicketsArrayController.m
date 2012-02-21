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
      self.expandedArray = [NSMutableArray array];
      
      BOOL search = (searchString && ![searchString isEqualToString:@""]);
       __block BOOL remoteHosts = NO;
      __block NSString *blockString = searchString;
      __block NSString *previousHost = nil;
      [sorted enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
         if(!search || [[obj appNameHostName] rangeOfString:blockString options:NSLiteralSearch|NSCaseInsensitiveSearch].location != NSNotFound){
            NSString *newHost = [obj hostName];
            if(newHost && ![previousHost isEqualToString:newHost]){
               [expandedArray addObject:newHost];
               previousHost = newHost;
                remoteHosts = YES;
            }
            [expandedArray addObject:obj];
         }
      }];
       if(remoteHosts)
           [expandedArray insertObject:NSLocalizedString(@"Local", @"Title for section containing apps from the local machine") atIndex:0U];
      return expandedArray;
   }
}

- (void) search:(id)sender {
	[self setSearchString:[sender stringValue]];
	[self rearrangeObjects];
}

- (void) selectFirstApplication {
   __block NSUInteger index = NSNotFound;
   [[self arrangedObjects] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      if([obj isKindOfClass:[GrowlApplicationTicket class]]){
         index = idx;
         *stop = YES;
      }
   }];
   
   [self setSelectionIndex:index];
}

- (BOOL) canRemove {
   if([self selectionIndex] != NSNotFound)
      return [[[self arrangedObjects] objectAtIndex:[self selectionIndex]] isKindOfClass:[GrowlApplicationTicket class]];
   else
      return NO;
}

@end
