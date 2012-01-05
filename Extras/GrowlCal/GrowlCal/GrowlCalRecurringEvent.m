//
//  GrowlCalRecurringEvent.m
//  GrowlCal
//
//  Created by Daniel Siemer on 12/22/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "GrowlCalRecurringEvent.h"
#import "NSDate+GrowlCalAdditions.h"

#import <CalendarStore/CalendarStore.h>

@implementation GrowlCalRecurringEvent

@synthesize delegate = _delegate;
@synthesize uid = _uid;
@synthesize occurences = _occurences;

-(id)initWithEvent:(CalEvent*)event delegate:(id<GrowlCalEventDelegateProtocal>)delegate
{
   if((self = [super init])){
      self.delegate = delegate;
      self.occurences = [NSMutableArray array];
      [self updateEvent:event];
   }
   return self;
}

-(id)initWithGrowlEvent:(GrowlCalEvent *)event delegate:(id<GrowlCalEventDelegateProtocal>)delegate
{
   if((self = [super init])){
      self.delegate = delegate;
      self.occurences = [NSMutableArray array];
      [_occurences addObject:event];
   }
   return self;
}

-(void)updateEvent:(CalEvent*)event
{
   //Find our event with start date, but since we are updating, it could be the same day, but a different time
   GrowlCalEvent *growlEvent = [self growlCalEventForDate:[event startDate]];   
   if(growlEvent){
      [growlEvent updateEvent:event];
   }else{
      GrowlCalEvent *newEvent = [[GrowlCalEvent alloc] initWithEvent:event delegate:self];
      [_occurences addObject:newEvent];
   }
}

-(void)removeDeadEvents
{
   //This represents events that should be in here, we will take a copy of occurences, and remove any we find in both from it
   //Any remaining items in the copy should be removed
   NSPredicate *predicate = [CalCalendarStore eventPredicateWithStartDate:[NSDate dateWithTimeIntervalSinceNow:-60*60*24]
                                                                  endDate:[NSDate dateWithTimeIntervalSinceNow:60*60*24*7] 
                                                                      UID:_uid
                                                                calendars:[[CalCalendarStore defaultCalendarStore] calendars]];
   NSArray *recurrences = [[CalCalendarStore defaultCalendarStore] eventsWithPredicate:predicate];
   __block NSMutableArray *eventsToRemove = [_occurences mutableCopy];
   [recurrences enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      GrowlCalEvent *event = [self growlCalEventForDate:[obj startDate]];
      [eventsToRemove removeObject:event];
   }];
   if([eventsToRemove count] > 0)
      [_occurences removeObjectsInArray:eventsToRemove];
}

-(GrowlCalEvent*)growlCalEventForDate:(NSDate*)date
{
   __block GrowlCalEvent *event = nil;
   [_occurences enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      if([[[obj event] startDate] compare:date] == NSOrderedSame){
         event = obj;
         *stop = YES;
      }
      NSDate *dayOfObj = [[[obj event] startDate] dayOfDate];
      NSDate *dayofEvent = [date dayOfDate];
      if([dayOfObj compare:dayofEvent] == NSOrderedSame){
         event = obj;
         *stop = YES;
      }
   }];
   return event;
}

-(void)removeFromEventList:(NSString *)uid date:(NSDate *)date
{
   //Find our event with start date
   __block NSUInteger toRemove = NSNotFound;
   [_occurences enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      if([[[obj event] startDate] compare:date] == NSOrderedSame){
         toRemove = idx;
         *stop = YES;
      }
   }];
   
   if(toRemove != NSNotFound)
      [_occurences removeObjectAtIndex:toRemove];
   
   if([_occurences count] == 0)
      [_delegate removeFromEventList:_uid date:nil];
}

@end
