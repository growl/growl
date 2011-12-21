//
//  GrowlCalCalendarController.m
//  GrowlCal
//
//  Created by Daniel Siemer on 12/20/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "GrowlCalCalendarController.h"
#import "GrowlCalCalendar.h"

#import <Growl/GrowlApplicationBridge.h>
#import <CalendarStore/CalendarStore.h>

@implementation GrowlCalCalendarController

@synthesize calendars = _calendars;
@synthesize upcomingEvents = _upcomingEvents;
@synthesize upcomingEventsFired = _upcomingEventsFired;
@synthesize currentEvents = _currentEvents;
@synthesize currentEventsFired = _currentEventsFired;
@synthesize upcomingTasks = _upcomingTasks;
@synthesize upcomingTasksFired = _upcomingTasksFired;

@synthesize notifyTimer = _notifyTimer;

-(id)init
{
   if((self = [super init])){
      [[NSNotificationCenter defaultCenter] addObserver:self 
                                               selector:@selector(calendarsChanged:) 
                                                   name:CalCalendarsChangedExternallyNotification
                                                 object:[CalCalendarStore defaultCalendarStore]];   
      [[NSNotificationCenter defaultCenter] addObserver:self 
                                               selector:@selector(eventsChanged:) 
                                                   name:CalEventsChangedExternallyNotification
                                                 object:[CalCalendarStore defaultCalendarStore]];   
      [[NSNotificationCenter defaultCenter] addObserver:self 
                                               selector:@selector(tasksChanged:) 
                                                   name:CalTasksChangedExternallyNotification
                                                 object:[CalCalendarStore defaultCalendarStore]];
      
      self.upcomingEvents = [NSMutableDictionary dictionary];
      self.upcomingEventsFired = [NSMutableDictionary dictionary];
      self.currentEvents = [NSMutableDictionary dictionary];
      self.currentEventsFired = [NSMutableDictionary dictionary];
      self.upcomingTasks = [NSMutableDictionary dictionary];
      self.upcomingTasksFired = [NSMutableDictionary dictionary];
      
      self.notifyTimer = [NSTimer timerWithTimeInterval:60
                                                 target:self
                                               selector:@selector(timerFire:)
                                               userInfo:nil
                                                repeats:YES];
      
      [self loadCalendars];
      [self loadEvents];
      [self loadTasks];
      [[NSRunLoop mainRunLoop] addTimer:_notifyTimer forMode:NSRunLoopCommonModes];
      
      [self timerFire:nil];
   }
      
   return self;
}

- (void)sendNotificationForItem:(CalCalendarItem*)item
{
   NSString *noteName = nil;
   NSString *noteDescription = nil;
   NSString *timeString = nil;
   NSDateFormatter *formater = [[NSDateFormatter alloc] init];
   [formater setDateStyle:NSDateFormatterShortStyle];
   [formater setTimeStyle:NSDateFormatterShortStyle];
   [formater setDoesRelativeDateFormatting:YES];
   
   if([item isKindOfClass:[CalEvent class]]){
      CalEvent *event = (CalEvent*)item;
      NSDate *current = [NSDate date];
      NSDate *start = [event startDate];
      NSDate *end = [event endDate];
      if([start compare:current] == NSOrderedAscending){
         if([end compare:current] == NSOrderedAscending){
            noteName = @"EventEndAlert";
            timeString = [NSString stringWithFormat:NSLocalizedString(@"%@", @""), [formater stringFromDate:end]];
            noteDescription = NSLocalizedString(@"%@ ended at %@", @"Title format string for event ended");
         }else if([end compare:[NSDate dateWithTimeIntervalSinceNow:60*15]] == NSOrderedAscending){
            noteName = @"UpcomingEventEndAlert";
            NSInteger minutes = [end timeIntervalSinceDate:current] / 60;
            timeString = [NSString stringWithFormat:NSLocalizedString(@"%ld minutes", nil), minutes];
            noteDescription = NSLocalizedString(@"%@ will end in %@", @"");
         }else{
            noteName = @"EventAlert";
            timeString = [NSString stringWithFormat:NSLocalizedString(@"%@", @""), [formater stringFromDate:start]];
            noteDescription = NSLocalizedString(@"%@ started at %@", @"Title format string for event started");
         }
      }else{
         noteName = @"UpcomingEventAlert";
         NSInteger minutes = [start timeIntervalSinceDate:current] / 60;
         timeString = [NSString stringWithFormat:NSLocalizedString(@"%ld minutes", nil), minutes];
         noteDescription = NSLocalizedString(@"%@ will start in %@", @"");
      }
   }else if([item isKindOfClass:[CalTask class]]){
      CalTask *task = (CalTask*)item;
      if([[task dueDate] compare:[NSDate date]] == NSOrderedDescending)
         noteName = @"UpcomingToDoAlert";
      else
         noteName = @"ToDoAlert";
   }else{
      return;
   }

   [GrowlApplicationBridge notifyWithTitle:[item title]
                               description:[NSString stringWithFormat:noteDescription, [item title], timeString]
                          notificationName:noteName
                                  iconData:nil
                                  priority:0
                                  isSticky:NO
                              clickContext:nil
                                identifier:[item uid]];
}

- (void)timerFire:(NSTimer*)timer
{
   __block GrowlCalCalendarController *blockSelf = self;
   __block NSMutableArray *firedKeys = [NSMutableArray array];
   [[_upcomingEvents allValues] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      if([[obj startDate] compare:[NSDate dateWithTimeIntervalSinceNow:60*15]] == NSOrderedAscending){
         [blockSelf sendNotificationForItem:obj];
         [firedKeys addObject:[obj uid]];
      }
   }];
   
   [firedKeys enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      [_upcomingEventsFired setObject:[_upcomingEvents objectForKey:obj] forKey:obj];
      [_upcomingEvents removeObjectForKey:obj];
   }];
   
   __block NSMutableArray *newCurrent = [NSMutableArray array];
   [[_upcomingEventsFired allValues] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      if([[obj startDate] compare:[NSDate date]] == NSOrderedAscending){
         [blockSelf sendNotificationForItem:obj];
         [newCurrent addObject:[obj uid]];
      }
   }];
   
   [newCurrent enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      [_currentEvents setObject:[_upcomingEventsFired objectForKey:obj] forKey:obj];
      [_upcomingEventsFired removeObjectForKey:obj];
   }];

   __block NSMutableArray *firedCurrent = [NSMutableArray array];
   [[_currentEvents allValues] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      if([[obj endDate] compare:[NSDate dateWithTimeIntervalSinceNow:60*15]] == NSOrderedAscending){
         [blockSelf sendNotificationForItem:obj];
         [firedCurrent addObject:[obj uid]];
      }
   }];
   
   [firedCurrent enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      [_currentEventsFired setObject:[_currentEvents objectForKey:obj] forKey:obj];
      [_currentEvents removeObjectForKey:obj];
   }];

   __block NSMutableArray *finishedWith = [NSMutableArray array];
   [[_currentEventsFired allValues] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      if([[obj endDate] compare:[NSDate date]] == NSOrderedAscending){
         [blockSelf sendNotificationForItem:obj];
         [finishedWith addObject:[obj uid]];
      }
   }];
   
   [finishedWith enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      [_currentEventsFired removeObjectForKey:obj];
   }];
}

- (void)loadCalendars 
{
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

- (void)saveCalendars 
{
   __block NSMutableArray *toSave = [NSMutableArray arrayWithCapacity:[_calendars count]];
   [_calendars enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      [toSave addObject:[obj dictionaryRepresentation]];
   }];
   [[NSUserDefaults standardUserDefaults] setValue:toSave forKey:@"calendarCache"];
}

- (void)setEvent:(CalEvent*)event
{
   NSMutableDictionary *dictToSet = nil;
   NSString *uid = [event uid];
   if([_upcomingEvents objectForKey:uid])
      dictToSet = _upcomingEvents;
   else if([_upcomingEventsFired objectForKey:uid])
      dictToSet = _upcomingEventsFired;
   else if([_currentEvents objectForKey:uid])
      dictToSet = _currentEvents;
   else if([_currentEventsFired objectForKey:uid])
      dictToSet = _currentEventsFired;
   else{
      NSDate *start = [event startDate];
      NSDate *end = [event endDate];
      NSDate *now = [NSDate date];
      NSLog(@"start: %@, end: %@, now: %@", start, end, now);
      if([start compare:now] == NSOrderedDescending)
         dictToSet = _upcomingEvents;
      else{ 
         if([end compare:now] == NSOrderedAscending)
            dictToSet = _upcomingEventsFired;
         else 
            dictToSet = _currentEventsFired;
      }
   }
   if(dictToSet)
      [dictToSet setObject:event forKey:uid];
}

- (void)loadEvents
{
   NSPredicate *eventPredicate = [CalCalendarStore eventPredicateWithStartDate:[NSDate date]
                                                                       endDate:[NSDate dateWithTimeIntervalSinceNow:60*60*24]
                                                                     calendars:[[CalCalendarStore defaultCalendarStore] calendars]];
   NSArray *events = [[CalCalendarStore defaultCalendarStore] eventsWithPredicate:eventPredicate];
   __block GrowlCalCalendarController *blockSelf = self;
   [events enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      [blockSelf setEvent:obj];
   }];
}


- (void)loadTasks
{
/*   NSPredicate *taskPredicate = [CalCalendarStore taskPredicateWithUncompletedTasksDueBefore:[NSDate dateWithTimeIntervalSinceNow:60*60*24]
                                                                                   calendars:[[CalCalendarStore defaultCalendarStore] calendars]];
   NSArray *tasks = [[CalCalendarStore defaultCalendarStore] tasksWithPredicate:taskPredicate];*/
}

- (void)eventsChanged:(NSNotification*)notification
{
   [self loadEvents];
}

- (void)tasksChanged:(NSNotification*)notification
{
   [self loadTasks];
}

- (void)calendarsChanged:(NSNotification*)notification
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
