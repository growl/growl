//
//  GrowlCalTask.m
//  GrowlCal
//
//  Created by Daniel Siemer on 1/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "GrowlCalTask.h"
#import "NSDate+GrowlCalAdditions.h"

#import <Growl/Growl.h>
#import <CalendarStore/CalendarStore.h>

@implementation GrowlCalTask

@synthesize task = _task;
@synthesize nextTimer = _nextTimer;
@synthesize stage = _stage;
@synthesize allDay = _allDay;

-(id)initWithTask:(id)aTask
{
   if((self = [super init])){
      self.task = aTask;
      _stage = GrowlCalTaskUnknown;
      [self checkAllDay];
      [self determineStage];
      [self updateTimer];
   }
   return self;
}

-(NSCalendarDate*)afterTimeDayBefore {
   return [NSCalendarDate dateWithTimeInterval:0
                                     sinceDate:[[NSUserDefaults standardUserDefaults] objectForKey:@"AllDayItemDayBeforeTime"]];
}

-(NSCalendarDate*)afterTimeDayOf {
   return [NSCalendarDate dateWithTimeInterval:0
                                     sinceDate:[[NSUserDefaults standardUserDefaults] objectForKey:@"AllDayItemDayOfTime"]];
}

-(void)updateWithTask:(CalTask*)aTask
{
   if([[_task dueDate] compare:[aTask dueDate]] != NSOrderedSame)
      [self determineStage];
   
   self.task = aTask;
}

-(void)determineStage
{
   [self checkAllDay];
   NSDate *timeBefore = nil;
   NSDate *timeOf = nil;
   NSDate *now = [NSDate date];
   NSDate *dueDate = [_task dueDate];
   
   GrowlCalTaskStage newStage = _stage;
   
   if(_allDay){
      timeBefore = [self afterTimeDayBefore];
      timeOf = [self afterTimeDayOf];
   }else{
      NSInteger minutesBeforeEvent = [[NSUserDefaults standardUserDefaults] integerForKey:@"MinutesBeforeEvent"];
      timeBefore = [NSDate dateWithTimeInterval:-60 * minutesBeforeEvent sinceDate:dueDate];
      timeOf = dueDate;
   }
   
   if([now compare:timeBefore] == NSOrderedAscending)
      newStage = GrowlCalTaskUpcoming;
   else if([now compare:timeOf] == NSOrderedDescending)
      newStage = GrowlCalTaskUpcomingFired;
   
   if(newStage != _stage && newStage != GrowlCalTaskUnknown){
      _stage = newStage;
      [self updateTimer];
   }
}

-(void)invalidateTimer
{
   [_nextTimer invalidate];
   self.nextTimer = nil;
}

-(void)fireNotification
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

   NSDate *dueDate= [_task dueDate];
   if(_allDay){
      switch (_stage) {
         case GrowlCalTaskUpcomingFired:
            noteName = @"UpcomingToDoAlert";
            timeString = [dateFormatter stringFromDate:dueDate];
            noteDescription = NSLocalizedString(@"%@ will be due %@", @"");
            break;
         case GrowlCalTaskCurrentFired:
            noteName = @"UpcomingToDoAlert";
            timeString = [dateFormatter stringFromDate:dueDate];
            noteDescription = NSLocalizedString(@"%@ is due %@", @"");
            break;
         default:
            break;
      }
   }else{
      switch (_stage) {
         case GrowlCalTaskUpcomingFired:
            noteName = @"UpcomingToDoAlert";
            timeString = [dateFormatter stringFromDate:dueDate];
            noteDescription = NSLocalizedString(@"%@ will be due at %@", @"");
            break;
         case GrowlCalTaskCurrentFired:
            noteName = @"ToDoAlert";
            timeString = [dateFormatter stringFromDate:dueDate];
            noteDescription = NSLocalizedString(@"%@ is due at %@", @"");
            break;
         default:
            break;
      }
   }
   
   if(noteName && noteDescription)
      [GrowlApplicationBridge notifyWithTitle:[_task title]
                                  description:[NSString stringWithFormat:noteDescription, [_task title], timeString]
                             notificationName:noteName
                                     iconData:nil
                                     priority:0
                                     isSticky:NO
                                 clickContext:nil
                                   identifier:[_task uid]];
}

-(void)timerFire:(NSTimer*)nextTimer
{
   switch (_stage) {
      case GrowlCalTaskUpcoming:
         _stage = GrowlCalTaskUpcomingFired;
         break;
      case GrowlCalTaskUpcomingFired:
         _stage = GrowlCalTaskCurrentFired;
         break;
      case GrowlCalTaskCurrentFired:
      case GrowlCalTaskUnknown:
      default:
         return;
         break;
   }
   [self fireNotification];
   [self updateTimer];
}

-(void)checkAllDay
{
   //Possibly foolish check, will do testing to validate
   NSLog(@"Due date: %@", [_task dueDate]);
   if([[[_task dueDate] dayOfDate] compare:[_task dueDate]] == NSOrderedSame)
      _allDay = YES;
   else
      _allDay = NO;
}

-(void)updateTimer
{
   [self invalidateTimer];
   NSDate *dueDate = [_task dueDate];
   NSDate *beforeTime = nil;
   NSDate *dueTime = nil;
   if(_allDay){
      NSCalendarDate *afterTimeDayBefore = [self afterTimeDayBefore];
      NSCalendarDate *afterTimeDayOf = [self afterTimeDayOf];
      beforeTime = [[NSCalendarDate dateWithTimeInterval:0 sinceDate:dueDate] dateByAddingYears:0
                                                                                         months:0
                                                                                           days:0
                                                                                          hours:-(24 - [afterTimeDayBefore hourOfDay])
                                                                                        minutes:(60 - [afterTimeDayBefore minuteOfHour])
                                                                                        seconds:0];
      dueTime = [[NSCalendarDate dateWithTimeInterval:0 sinceDate:dueDate] dateByAddingYears:0
                                                                                      months:0
                                                                                        days:0
                                                                                       hours:[afterTimeDayOf hourOfDay]
                                                                                     minutes:[afterTimeDayOf minuteOfHour]
                                                                                     seconds:0];
   }else{
      NSInteger minutesBeforeEvent = [[NSUserDefaults standardUserDefaults] integerForKey:@"MinutesBeforeReminder"];
      beforeTime = [NSDate dateWithTimeInterval:-60 * minutesBeforeEvent sinceDate:dueDate];
      dueTime = dueDate;
   }
   
   NSDate *timerFireDate = nil;
   switch (_stage) {
      case GrowlCalTaskUpcoming:
         timerFireDate = beforeTime;
         break;
      case GrowlCalTaskUpcomingFired:
         timerFireDate = dueTime;
         break;
      case GrowlCalTaskCurrentFired:
      case GrowlCalTaskUnknown:
      default:
         break;
   }
   
   if(!timerFireDate)
      return;
   
   NSTimeInterval interval = [timerFireDate timeIntervalSinceDate:[NSDate date]];
   if(interval < 0)
      interval = 0;
   self.nextTimer = [NSTimer timerWithTimeInterval:interval
                                            target:self 
                                          selector:@selector(timerFire:) 
                                          userInfo:nil
                                           repeats:NO];
   [[NSRunLoop mainRunLoop] addTimer:_nextTimer forMode:NSRunLoopCommonModes];
}

@end
