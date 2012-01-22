//
//  GrowlCalEvent.h
//  Growl
//
//  Created by Daniel Siemer on 12/22/11.
//  Copyright (c) 2011 The Growl Project. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GrowlCalCalendarController.h"

enum _GrowlCalEventStage {
   GrowlCalEventUpcoming,
   GrowlCalEventUpcomingFired,
   GrowlCalEventCurrent,
   GrowlCalEventCurrentFired,
   GrowlCalEventFinished,
   GrowlCalEventUnknown
};

typedef NSInteger GrowlCalEventStage;

@protocol GrowlCalEventDelegateProtocal <NSObject>

-(void)removeFromEventList:(NSString*)uid date:(NSDate*)date;

@end

@class CalEvent;

@interface GrowlCalEvent : NSObject 

@property (weak) id<GrowlCalEventDelegateProtocal>delegate;
@property (strong) CalEvent *event;
@property (strong) NSTimer *nextTimer;
@property (nonatomic) GrowlCalEventStage stage;

-(id)initWithEvent:(CalEvent*)event delegate:(id<GrowlCalEventDelegateProtocal>)delegate;

-(void)invalidateTimer;
-(void)updateTimer;
-(void)determineStage;
-(void)updateEvent:(CalEvent*)event;

@end
