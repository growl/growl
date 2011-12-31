//
//  GrowlCalCalendarController.m
//  GrowlCal
//
//  Created by Daniel Siemer on 12/20/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "GrowlCalCalendarController.h"
#import "GrowlCalCalendar.h"
#import "GrowlCalEvent.h"
#import "GrowlCalRecurringEvent.h"

#import <Growl/Growl.h>
#import <CalendarStore/CalendarStore.h>

@implementation GrowlCalCalendarController

@synthesize calendars = _calendars;
@synthesize events = _events;
@synthesize upcomingTasks = _upcomingTasks;
@synthesize upcomingTasksFired = _upcomingTasksFired;
@synthesize uncompletedDueTasks = _uncompletedDueTasks;

@synthesize cacheTimer = _cacheTimer;
@synthesize notifyTimer = _notifyTimer;

+ (GrowlCalCalendarController*)sharedController
{
   static GrowlCalCalendarController *instance;
   static dispatch_once_t onceToken;
   dispatch_once(&onceToken, ^{
      instance = [[self alloc] init];
   });
   return instance;
}

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
      
      self.events = [NSMutableDictionary dictionary];
      self.upcomingTasks = [NSMutableDictionary dictionary];
      self.upcomingTasksFired = [NSMutableDictionary dictionary];
      self.uncompletedDueTasks = [NSMutableDictionary dictionary];
      
      self.notifyTimer = [NSTimer timerWithTimeInterval:60
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
   NSDateFormatter *dateTimeFormatter = [[NSDateFormatter alloc] init];
   [dateTimeFormatter setDateStyle:NSDateFormatterShortStyle];
   [dateTimeFormatter setTimeStyle:NSDateFormatterShortStyle];
   [dateTimeFormatter setDoesRelativeDateFormatting:YES];
   
   NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
   [dateFormatter setDateStyle:NSDateFormatterShortStyle];
   [dateFormatter setDoesRelativeDateFormatting:YES];
   
   if([item isKindOfClass:[CalEvent class]]){
      return;
   }else if([item isKindOfClass:[CalTask class]]){
      CalTask *task = (CalTask*)item;
      NSDate *due = [task dueDate];
      if([[task dueDate] compare:[NSDate date]] == NSOrderedDescending){
         noteName = @"UpcomingToDoAlert";
         timeString = [dateFormatter stringFromDate:due];
         noteDescription = NSLocalizedString(@"%@ is due on %@", @"Title format string for event started");
      }else{
         noteName = @"ToDoAlert";
         timeString = [dateFormatter stringFromDate:due];
         noteDescription = NSLocalizedString(@"%@ is due on %@", @"Title format string for event started");

      }
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

- (BOOL)isNotificationEnabledForItem:(CalCalendarItem*)item
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
   __block NSMutableArray *taskFired = [NSMutableArray array];
   [[_upcomingTasks allValues] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      NSCalendarDate *now = [[NSCalendarDate alloc] initWithTimeInterval:0 sinceDate:[obj dueDate]];
      NSCalendarDate *dayBefore = [now dateByAddingYears:0
                                                  months:0
                                                    days:0
                                                   hours:-(24 - 8)
                                                 minutes:(60 - 30)
                                                 seconds:0];

      if([dayBefore compare:[NSDate date]] == NSOrderedAscending){
         [taskFired addObject:[obj uid]];
         if([[obj dueDate] compare:[NSDate date]] != NSOrderedAscending && [blockSelf isNotificationEnabledForItem:obj])
            [blockSelf sendNotificationForItem:obj];
      }
   }];
   
   [taskFired enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      if([_upcomingTasks objectForKey:obj])
         [_upcomingTasksFired setObject:[_upcomingTasks objectForKey:obj] forKey:obj];
      [_upcomingTasks removeObjectForKey:obj];
   }];
   
   __block NSMutableArray *dueTasks = [NSMutableArray array];
   [[_upcomingTasksFired allValues] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      NSCalendarDate *now = [[NSCalendarDate alloc] initWithTimeInterval:0 sinceDate:[obj dueDate]];
      NSCalendarDate *dayOf = [now dateByAddingYears:0
                                              months:0
                                                days:0
                                               hours:8
                                             minutes:30
                                             seconds:0];

      if([dayOf compare:[NSDate date]] == NSOrderedAscending){
         [dueTasks addObject:[obj uid]];
         if([blockSelf isNotificationEnabledForItem:obj])
            [blockSelf sendNotificationForItem:obj];
      }
   }];
   [dueTasks enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      if([_upcomingTasksFired objectForKey:obj])
         [_uncompletedDueTasks setObject:[_upcomingTasksFired objectForKey:obj] forKey:obj];
      [_upcomingTasksFired removeObjectForKey:obj];
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
      if(([obj isAllDay] && [[obj endDate] compare:[NSDate date]] == NSOrderedDescending) || 
         !([[obj startDate] compare:[NSDate dateWithTimeIntervalSinceNow:60*60*24]] == NSOrderedDescending ||
           [[obj endDate] compare:[NSDate date]] == NSOrderedAscending))
      {
         NSString *uid = [obj uid];
         if ([_events objectForKey:uid]) {
            id event = [_events objectForKey:uid];
            if(([event isKindOfClass:[GrowlCalEvent class]] && ![obj recurrenceRule]) || 
               ([event isKindOfClass:[GrowlCalRecurringEvent class]] && [obj recurrenceRule]))
            {
               [event updateEvent:obj];
            }else if([event isKindOfClass:[GrowlCalEvent class]] && [obj recurrenceRule]){
               GrowlCalRecurringEvent *newEvent = [[GrowlCalRecurringEvent alloc] initWithGrowlEvent:event delegate:(id<GrowlCalEventDelegateProtocal>)self];
               //[newEvent updateEvent:obj];
               [_events setObject:newEvent forKey:uid];
            }else if([event isKindOfClass:[GrowlCalRecurringEvent class]] && ![obj recurrenceRule]){
               if([[event occurences] count] > 1)
                  NSLog(@"Dumping existing event occurrences for event: %@, it is apparently no longer recurring", uid);
               GrowlCalEvent *newEvent = [event growlCalEventForDate:[obj startDate]];
               [_events setObject:newEvent forKey:uid];
            }
         }else{
            if([obj recurrenceRule]){
               GrowlCalRecurringEvent *recurring = [[GrowlCalRecurringEvent alloc] initWithEvent:obj delegate:(id<GrowlCalEventDelegateProtocal>)self];
               [_events setObject:recurring forKey:uid];
            }else{
               GrowlCalEvent *event = [[GrowlCalEvent alloc] initWithEvent:obj delegate:(id<GrowlCalEventDelegateProtocal>)blockSelf];
               [_events setObject:event forKey:uid];
            }
         }
      }
   }];
}

- (void)setTask:(CalTask*)task
{
   if(!task)
      return;

   NSMutableDictionary *dictToSet = _upcomingTasks;
   if([_upcomingTasksFired objectForKey:[task uid]])
      dictToSet = _upcomingTasksFired;
   else if([_uncompletedDueTasks objectForKey:[task uid]])
      dictToSet = _uncompletedDueTasks;
      
   [dictToSet setObject:task forKey:[task uid]];
}

- (void)loadTasks
{
   NSPredicate *taskPredicate = [CalCalendarStore taskPredicateWithUncompletedTasksDueBefore:[NSDate dateWithTimeIntervalSinceNow:60*60*24*7]
                                                                                   calendars:[[CalCalendarStore defaultCalendarStore] calendars]];
   NSArray *tasks = [[CalCalendarStore defaultCalendarStore] tasksWithPredicate:taskPredicate];
   __block GrowlCalCalendarController *blockSelf = self;
   [tasks enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      if([obj dueDate])
         [blockSelf setTask:obj];
   }];
}

- (void)eventsChanged:(NSNotification*)notification
{
   //Adding and reloading events is handled by simply calling our cache events function
   [self loadEvents];
   NSArray *removed = [[notification userInfo] objectForKey:CalDeletedRecordsKey];
   [removed enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      if([[_events objectForKey:obj] isKindOfClass:[GrowlCalRecurringEvent class]]){
         [[_events objectForKey:obj] removeDeadEvents];
      }else{
         [_events removeObjectForKey:obj];
      }
   }];
}

- (void)tasksChanged:(NSNotification*)notification
{
   [self loadTasks];
   NSArray *changed = [[notification userInfo] objectForKey:CalUpdatedRecordsKey];
   NSArray *removed = [[notification userInfo] objectForKey:CalDeletedRecordsKey];

   [changed enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      if([_uncompletedDueTasks objectForKey:obj]){
         CalTask *changeTask = [[CalCalendarStore defaultCalendarStore] taskWithUID:obj];
         if([changeTask isCompleted])
            [_uncompletedDueTasks removeObjectForKey:obj];
      }
   }];
   
   [removed enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      if([_upcomingTasks objectForKey:obj])
         [_upcomingTasks removeObjectForKey:obj];
      if([_upcomingTasksFired objectForKey:obj])
         [_upcomingTasksFired removeObjectForKey:obj];
      if([_uncompletedDueTasks objectForKey:obj])
         [_uncompletedDueTasks removeObjectForKey:obj];
   }];
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

#pragma mark GrowlCalEventDelegateProtocal

-(void)removeFromEventList:(NSString*)uid date:(NSDate *)date
{
   [_events removeObjectForKey:uid];
}

@end
