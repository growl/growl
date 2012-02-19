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
@property (strong) NSMutableDictionary *tasks;

@property (strong) NSTimer *cacheTimer;

+ (GrowlCalCalendarController*)sharedController;

- (void)loadCalendars;
- (void)saveCalendars;
- (void)loadEvents;
- (void)loadTasks;

- (BOOL)isNotificationEnabledForItem:(CalCalendarItem*)item;

- (NSArray*)calendarsArray;

@end
