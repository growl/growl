//
//  GrowlCalTask.h
//  GrowlCal
//
//  Created by Daniel Siemer on 1/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

enum _GrowlCalTaskStage {
   GrowlCalTaskUpcoming,
   GrowlCalTaskUpcomingFired,
   GrowlCalTaskCurrentFired,
   GrowlCalTaskUnknown
};

typedef NSInteger GrowlCalTaskStage;

@protocol GrowlCalTaskDelegateProtocal <NSObject>

-(void)removeFromTaskList:(NSString*)uid;

@end

@class CalTask;

@interface GrowlCalTask : NSObject

@property (strong) CalTask* task;
@property (strong) NSTimer *nextTimer;

@property (nonatomic) GrowlCalTaskStage stage;
@property (nonatomic) BOOL allDay;

-(id)initWithTask:(CalTask*)aTask;
-(void)updateWithTask:(CalTask*)aTask;
-(void)determineStage;
-(void)checkAllDay;
-(void)updateTimer;

@end
