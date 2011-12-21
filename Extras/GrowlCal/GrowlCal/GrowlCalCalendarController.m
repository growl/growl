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

@synthesize cacheTimer = _cacheTimer;
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
      
      self.notifyTimer = [NSTimer timerWithTimeInterval:10
                                                 target:self
                                               selector:@selector(timerFire:)
                                               userInfo:nil
                                                repeats:YES];
      self.cacheTimer = [NSTimer timerWithTimeInterval:60*60
                                                target:self
                                              selector:@selector(cacheTimerFire:)
                                              userInfo:nil
                                               repeats:YES];

      [self loadCalendars];
      [self loadEvents];
      [self loadTasks];
      [[NSRunLoop mainRunLoop] addTimer:_notifyTimer forMode:NSRunLoopCommonModes];
      [[NSRunLoop mainRunLoop] addTimer:_cacheTimer forMode:NSRunLoopCommonModes];
      
      [self timerFire:nil];
   }
      
   return self;
}

- (void)dealloc
{
   [self saveCalendars];
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
      if(![event isAllDay]){
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
      }else{
         if([start compare:current] == NSOrderedAscending){
            noteName = @"EventAlert";
            timeString = [NSString stringWithFormat:NSLocalizedString(@"%@", @""), [formater stringFromDate:start]];
            noteDescription = NSLocalizedString(@"%@ started at %@ (all-day)", @"Title format string for event started");
         }else{
            noteName = @"UpcomingEventAlert";
            timeString = [NSString stringWithFormat:NSLocalizedString(@"%@", @""), [formater stringFromDate:start]];
            noteDescription = NSLocalizedString(@"%@ will start at %@ (all-day)", @"");
         }
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

- (BOOL)shouldSendNotificationForItem:(CalCalendarItem*)item
{
   BOOL shouldSend = NO;
   NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
   
   if([defaults boolForKey:@"NotifyAllCalendars"]) 
      shouldSend = YES;
   if([defaults boolForKey:@"NotifySelectedCalendars"] && [[_calendars objectForKey:[[item calendar] uid]] use])
      shouldSend = YES;
   if([defaults boolForKey:@"NotifyGrowlCalNote"] && [[item notes] rangeOfString:@"GrowlCal"].location == NSNotFound)
      shouldSend = YES;
   
   return shouldSend;
}

- (void)timerFire:(NSTimer*)timer
{
   __block GrowlCalCalendarController *blockSelf = self;
   __block NSMutableArray *firedKeys = [NSMutableArray array];
   NSInteger minutesBeforeEvent = [[NSUserDefaults standardUserDefaults] integerForKey:@"MinutesBeforeEvent"];
   [[_upcomingEvents allValues] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      if(![obj isAllDay]){
         if([[obj startDate] compare:[NSDate dateWithTimeIntervalSinceNow:60 * minutesBeforeEvent]] == NSOrderedAscending){
            [firedKeys addObject:[obj uid]];
            if([blockSelf shouldSendNotificationForItem:obj])
               [blockSelf sendNotificationForItem:obj];
         }
      }else{
         NSCalendarDate *now = [[NSCalendarDate alloc] initWithTimeInterval:0 sinceDate:[obj startDate]];
         NSCalendarDate *dayBefore = [now dateByAddingYears:0
                                                     months:0
                                                       days:0
                                                      hours:-(24 - 8)
                                                    minutes:(60 - 30)
                                                    seconds:0];

         if([dayBefore compare:[NSDate date]] == NSOrderedAscending){
            [firedKeys addObject:[obj uid]];
            if([[obj startDate] compare:[NSDate date]] != NSOrderedAscending && [blockSelf shouldSendNotificationForItem:obj])
               [blockSelf sendNotificationForItem:obj];
         }
      }
   }];
   
   [firedKeys enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      [_upcomingEventsFired setObject:[_upcomingEvents objectForKey:obj] forKey:obj];
      [_upcomingEvents removeObjectForKey:obj];
   }];
   
   __block NSMutableArray *newCurrent = [NSMutableArray array];
   [[_upcomingEventsFired allValues] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      if(![obj isAllDay]){
         if([[obj startDate] compare:[NSDate date]] == NSOrderedAscending){
            [newCurrent addObject:[obj uid]];
            if([blockSelf shouldSendNotificationForItem:obj])
               [blockSelf sendNotificationForItem:obj];
         }
      }else{
         NSCalendarDate *now = [[NSCalendarDate alloc] initWithTimeInterval:0 sinceDate:[obj startDate]];
         NSCalendarDate *dayOf = [now dateByAddingYears:0
                                                 months:0
                                                   days:0
                                                  hours:8
                                                minutes:30
                                                seconds:0];
         
         if([dayOf compare:[NSDate date]] == NSOrderedAscending){
            [newCurrent addObject:[obj uid]];
            if([blockSelf shouldSendNotificationForItem:obj])
               [blockSelf sendNotificationForItem:obj];
         }
      }
   }];
   [newCurrent enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      [_currentEvents setObject:[_upcomingEventsFired objectForKey:obj] forKey:obj];
      [_upcomingEventsFired removeObjectForKey:obj];
   }];

   __block NSMutableArray *firedCurrent = [NSMutableArray array];
   NSInteger minutesBeforeEventEnd = [[NSUserDefaults standardUserDefaults] integerForKey:@"MinutesBeforeEvent"];
   [[_currentEvents allValues] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      if([[obj endDate] compare:[NSDate dateWithTimeIntervalSinceNow:60 * minutesBeforeEventEnd]] == NSOrderedAscending){
         [firedCurrent addObject:[obj uid]];
         if([blockSelf shouldSendNotificationForItem:obj])
            [blockSelf sendNotificationForItem:obj];
      }
    }];
   
   [firedCurrent enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      [_currentEventsFired setObject:[_currentEvents objectForKey:obj] forKey:obj];
      [_currentEvents removeObjectForKey:obj];
   }];

   __block NSMutableArray *finishedWith = [NSMutableArray array];
   [[_currentEventsFired allValues] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      if([[obj endDate] compare:[NSDate date]] == NSOrderedAscending){
         [finishedWith addObject:[obj uid]];
         if([blockSelf shouldSendNotificationForItem:obj])
            [blockSelf sendNotificationForItem:obj];
      }
   }];
   
   [finishedWith enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      [_currentEventsFired removeObjectForKey:obj];
   }];
}

- (void)loadCalendars 
{
   NSArray *cached = [[NSUserDefaults standardUserDefaults] valueForKey:@"calendarCache"];
   __block NSMutableDictionary *blockCals = [NSMutableDictionary dictionary];
   __block GrowlCalCalendarController *blockSelf = self;
   [cached enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      GrowlCalCalendar *cal = [[GrowlCalCalendar alloc] initWithDictionary:obj];
      [cal setController:blockSelf];
      if([cal calendar])
         [blockCals setObject:cal forKey:[cal uid]];
   }];
   
   BOOL removed = NO;
   if([blockCals count] < [cached count])
      removed = YES;
   
   NSArray *live = [[CalCalendarStore defaultCalendarStore] calendars];
   __block BOOL added = NO;
   [live enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      if(![[blockCals valueForKey:@"uid"] containsObject:[obj uid]]){
         GrowlCalCalendar *newCal = [[GrowlCalCalendar alloc] initWithUID:[obj uid]];
         [newCal setController:blockSelf];
         [blockCals setObject:newCal forKey:[newCal uid]];
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
   [[_calendars allValues] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
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
      //NSLog(@"start: %@, end: %@, now: %@", start, end, now);
      if([start compare:now] == NSOrderedDescending)
         dictToSet = _upcomingEvents;
      else{ 
         if([end compare:now] == NSOrderedDescending)
            dictToSet = _upcomingEventsFired;
         else 
            dictToSet = _currentEventsFired;
      }
   }
   
   if(dictToSet)
      [dictToSet setObject:event forKey:uid];
}

- (void)cacheTimerFire:(NSTimer*)timer
{
   [self loadEvents];
   [self loadTasks];
}

- (void)loadEvents
{
   NSPredicate *eventPredicate = [CalCalendarStore eventPredicateWithStartDate:[NSDate dateWithTimeIntervalSinceNow:-60*60*24]
                                                                       endDate:[NSDate dateWithTimeIntervalSinceNow:60*60*24*7]
                                                                     calendars:[[CalCalendarStore defaultCalendarStore] calendars]];
   NSArray *events = [[CalCalendarStore defaultCalendarStore] eventsWithPredicate:eventPredicate];
   __block GrowlCalCalendarController *blockSelf = self;
   [events enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      if([obj isAllDay] || !([[obj startDate] compare:[NSDate dateWithTimeIntervalSinceNow:60*60*24]] == NSOrderedDescending ||
                             [[obj endDate] compare:[NSDate date]] == NSOrderedAscending))
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
   //Adding and reloading events is handled by simply calling our cache events function
   [self loadEvents];
   NSArray *removed = [[notification userInfo] objectForKey:CalDeletedRecordsKey];
   [removed enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      if([_upcomingEvents objectForKey:obj])
         [_upcomingEvents removeObjectForKey:obj];
      if([_upcomingEventsFired objectForKey:obj])
         [_upcomingEventsFired removeObjectForKey:obj];
      if([_currentEvents objectForKey:obj])
         [_currentEvents removeObjectForKey:obj];
      if([_currentEventsFired objectForKey:obj])
         [_currentEventsFired removeObjectForKey:obj];
   }];
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
   
   __block NSMutableDictionary *blockCals = _calendars;
   __block GrowlCalCalendarController *blockSelf = self;
   if([added count] > 0){
      //NSLog(@"%ld calendars added", [added count]);
      [added enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
         GrowlCalCalendar *newCal = [[GrowlCalCalendar alloc] initWithUID:obj];
         [newCal setController:blockSelf];
         [blockCals setObject:newCal forKey:obj];
      }];
   }
   
   if([changed count] > 0) {
      //NSLog(@"%ld calendars changed", [changed count]);
      [[blockCals allValues] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
         if([changed containsObject:[obj uid]])
            [obj updateCalendar];
      }];
   }
   
   __block NSMutableArray *toRemoveBlock = [NSMutableArray array];
   if([removed count] > 0) {
      //NSLog(@"%ld calendars removed", [removed count]);
      [[blockCals allValues] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
         if([removed containsObject:[obj uid]])
            [toRemoveBlock addObject:[obj uid]];
      }];
   }
   if([toRemoveBlock count] > 0){
      [toRemoveBlock enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
         [blockCals removeObjectForKey:obj];
      }];
   }
   
   [self willChangeValueForKey:@"calendarsArray"];
   [self didChangeValueForKey:@"calendarsArray"];
}

- (NSArray*)calendarsArray
{
   return [_calendars allValues];
}

@end
