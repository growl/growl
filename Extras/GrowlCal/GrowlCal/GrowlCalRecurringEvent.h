//
//  GrowlCalRecurringEvent.h
//  GrowlCal
//
//  Created by Daniel Siemer on 12/22/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "GrowlCalEvent.h"

@class CalEvent;

@interface GrowlCalRecurringEvent : NSObject <GrowlCalEventDelegateProtocal>

@property (weak) id<GrowlCalEventDelegateProtocal> delegate;
@property (strong) NSString* uid;
@property (strong) NSMutableArray *occurences;

-(id)initWithEvent:(CalEvent*)event delegate:(id<GrowlCalEventDelegateProtocal>)delegate;
-(id)initWithGrowlEvent:(GrowlCalEvent*)event delegate:(id<GrowlCalEventDelegateProtocal>)delegate;
-(void)updateEvent:(CalEvent*)event;
-(void)removeDeadEvents;

-(GrowlCalEvent*)growlCalEventForDate:(NSDate*)date; 

@end
