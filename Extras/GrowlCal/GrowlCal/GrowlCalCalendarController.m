//
//  GrowlCalCalendarController.m
//  GrowlCal
//
//  Created by Daniel Siemer on 12/20/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "GrowlCalCalendarController.h"
#import "GrowlCalCalendar.h"

#import <CalendarStore/CalendarStore.h>

@implementation GrowlCalCalendarController

@synthesize calendars = _calendars;

-(id)init
{
   if((self = [super init])){
      NSArray *cached = [[NSUserDefaults standardUserDefaults] valueForKey:@"calendarCache"];
      __block NSMutableArray *blockCals = [NSMutableArray array];
      [cached enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
         GrowlCalCalendar *cal = [[GrowlCalCalendar alloc] initWithDictionary:obj];
         if([cal calendar])
            [blockCals addObject:cal];
      }];
      
      BOOL removed = NO;
      if([blockCals count] < [cached count])
         removed = YES;
      
      NSArray *live = [[CalCalendarStore defaultCalendarStore] calendars];
      __block BOOL added = NO;
      [live enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
         if(![[blockCals valueForKey:@"uid"] containsObject:[obj uid]]){
            GrowlCalCalendar *newCal = [[GrowlCalCalendar alloc] initWithUID:[obj uid]];
            [blockCals addObject:newCal];
            added = YES;
         }
      }];
      self.calendars = blockCals;
      if(removed || added)
         [self saveCalendars];

   }
      
   [[NSNotificationCenter defaultCenter] addObserver:self 
                                            selector:@selector(calendarChanged:) 
                                                name:CalCalendarsChangedExternallyNotification
                                              object:[CalCalendarStore defaultCalendarStore]];   
   return self;
}

- (void)saveCalendars {
   __block NSMutableArray *toSave = [NSMutableArray arrayWithCapacity:[_calendars count]];
   [_calendars enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      [toSave addObject:[obj dictionaryRepresentation]];
   }];
   [[NSUserDefaults standardUserDefaults] setValue:toSave forKey:@"calendarCache"];
}

- (void)calendarChanged:(NSNotification*)notification
{
   NSArray *added = [[notification userInfo] valueForKey:CalInsertedRecordsKey];
   NSArray *changed = [[notification userInfo] valueForKey:CalUpdatedRecordsKey];
   NSArray *removed = [[notification userInfo] valueForKey:CalDeletedRecordsKey];
   
   __block NSMutableArray *blockCals = _calendars;
   if([added count] > 0){
      NSLog(@"%ld calendars added", [added count]);
      [added enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
         GrowlCalCalendar *newCal = [[GrowlCalCalendar alloc] initWithUID:obj];
         [blockCals addObject:newCal];
      }];
   }
   
   if([changed count] > 0) {
      NSLog(@"%ld calendars changed", [changed count]);
      [blockCals enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
         if([changed containsObject:[obj uid]])
            [obj updateCalendar];
      }];
   }
   
   __block NSMutableArray *toRemoveBlock = [NSMutableArray array];
   if([removed count] > 0) {
      NSLog(@"%ld calendars removed", [removed count]);
      [blockCals enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
         if([removed containsObject:[obj uid]])
            [toRemoveBlock addObject:obj];
      }];
   }
   if([toRemoveBlock count] > 0)
      [blockCals removeObjectsInArray:toRemoveBlock];
   
   [self willChangeValueForKey:@"calendars"];
   [self didChangeValueForKey:@"calendars"];
}

@end
