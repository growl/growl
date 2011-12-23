//
//  GrowlCalCalendarController.h
//  GrowlCal
//
//  Created by Daniel Siemer on 12/20/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CalCalendarItem;

@interface GrowlCalCalendarController : NSObject

@property (strong) NSMutableDictionary *calendars;
@property (strong) NSMutableDictionary *events;
@property (strong) NSMutableDictionary *upcomingTasks;
@property (strong) NSMutableDictionary *upcomingTasksFired;
@property (strong) NSMutableDictionary *uncompletedDueTasks;

@property (strong) NSTimer *cacheTimer;
@property (strong) NSTimer *notifyTimer;

+ (GrowlCalCalendarController*)sharedController;

- (void)timerFire:(NSTimer*)timer;
- (void)loadCalendars;
- (void)saveCalendars;
- (void)loadEvents;
- (void)loadTasks;

- (BOOL)isNotificationEnabledForItem:(CalCalendarItem*)item;

- (NSArray*)calendarsArray;

@end
