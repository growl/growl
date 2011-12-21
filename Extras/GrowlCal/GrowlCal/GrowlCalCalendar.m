//
//  GrowlCalCalendar.m
//  GrowlCal
//
//  Created by Daniel Siemer on 12/19/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "GrowlCalCalendar.h"
#import "GrowlCalCalendarController.h"

#import <CalendarStore/CalendarStore.h>

@implementation GrowlCalCalendar

@synthesize controller = _controller;
@synthesize calendar = _calendar;
@synthesize uid = _uid;
@synthesize use = _use;

-(id)initWithUID:(NSString*)uid {
   if((self = [super init])){
      self.use = NO;
      self.uid = uid;
      self.calendar = [[CalCalendarStore defaultCalendarStore] calendarWithUID:_uid];
      [self addObserver:self
             forKeyPath:@"use"
                options:NSKeyValueObservingOptionNew
                context:nil];
   }
   return self;
}

-(id)initWithDictionary:(NSDictionary*)dict {
   if((self = [self initWithUID:[dict valueForKey:@"uid"]])){
      self.use = [[dict valueForKey:@"use"] boolValue];
   }
   return self;
}

-(void)dealloc
{
   [self removeObserver:self forKeyPath:@"use"];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
   if([keyPath isEqualToString:@"use"])
      [_controller saveCalendars];
}

-(NSDictionary*)dictionaryRepresentation {
   if(!_uid)
      return nil;
   
   return [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:_use], @"use", _uid, @"uid", nil];
}

-(void)updateCalendar {
   self.calendar = [[CalCalendarStore defaultCalendarStore] calendarWithUID:_uid];
}

@end
