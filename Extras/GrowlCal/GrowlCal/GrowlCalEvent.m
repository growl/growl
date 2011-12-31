//
//  GrowlCalEvent.m
//  Growl
//
//  Created by Daniel Siemer on 12/22/11.
//  Copyright (c) 2011 The Growl Project. All rights reserved.
//

#import "GrowlCalEvent.h"

#import <Growl/Growl.h>
#import <CalendarStore/CalendarStore.h>

@implementation GrowlCalEvent

@synthesize delegate = _delegate;
@synthesize event = _event;
@synthesize nextTimer = _nextTimer;
@synthesize stage = _stage;

-(id)initWithEvent:(CalEvent*)event delegate:(id<GrowlCalEventDelegateProtocal>)delegate
{
   if((self = [super init])) {
      self.event = event;
      self.delegate = delegate;
      _stage = GrowlCalEventUnknown;
      [self determineStage];
   }
   return self;
}

-(void)dealloc
{
   [self invalidateTimer];
}

-(void)invalidateTimer
{
   [_nextTimer invalidate];
   self.nextTimer = nil;
}

-(void)startTimerWithDate:(NSDate*)date
{
   [self invalidateTimer];
   NSTimeInterval interval = [date timeIntervalSinceDate:[NSDate date]];
   self.nextTimer = [NSTimer timerWithTimeInterval:interval
                                            target:self 
                                          selector:@selector(nextTimerFire:) 
                                          userInfo:nil
                                           repeats:NO];
   [[NSRunLoop mainRunLoop] addTimer:_nextTimer forMode:NSRunLoopCommonModes];
}

-(void)updateTimer
{
   NSDate *start = [_event startDate];
   NSDate *end = [_event endDate];
   NSDate *now = [NSDate date];
   NSDate *timerDate = nil;

   NSInteger minutesBeforeEvent = [[NSUserDefaults standardUserDefaults] integerForKey:@"MinutesBeforeEvent"];

   switch (_stage) {
      case GrowlCalEventUpcoming:
         if([_event isAllDay]){
            timerDate = [[NSCalendarDate dateWithTimeInterval:0 sinceDate:start] dateByAddingYears:0
                                                                                            months:0
                                                                                              days:0
                                                                                             hours:-(24 - 8)
                                                                                           minutes:(60 - 30)
                                                                                           seconds:0];
            if([timerDate compare:now] == NSOrderedAscending)
               timerDate = now;
         }else
            timerDate = [NSDate dateWithTimeInterval:-60 * minutesBeforeEvent sinceDate:start];
         break;
      case GrowlCalEventUpcomingFired:
         if([_event isAllDay]){
            timerDate = [[NSCalendarDate dateWithTimeInterval:0 sinceDate:start] dateByAddingYears:0
                                                                                            months:0
                                                                                              days:0
                                                                                             hours:8
                                                                                           minutes:30
                                                                                           seconds:0];
            if([timerDate compare:now] == NSOrderedAscending)
               timerDate = now;
         }else
            timerDate = start;
         break;
      case GrowlCalEventCurrent:
         if([_event isAllDay])
            timerDate = end;
         else{
            timerDate = [NSDate dateWithTimeInterval:-60 * minutesBeforeEvent sinceDate:end];
            if([timerDate compare:now] == NSOrderedAscending)
               timerDate = now;
         }
         break;
      case GrowlCalEventCurrentFired:
         if([_event isAllDay])
            timerDate = end;
         else
            timerDate = end;
         break;
      case GrowlCalEventFinished:
      default:
         break;
   }
      
   if(timerDate)
      [self startTimerWithDate:timerDate];
}
    
-(void)determineStage
{
   NSDate *now = [NSDate date];
   NSDate *start = [_event startDate];
   NSDate *end = [_event endDate];
   
   GrowlCalEventStage newStage = _stage;
   
   if([_event isAllDay]){
      NSCalendarDate *dayOf = [[NSCalendarDate dateWithTimeInterval:0 sinceDate:start] dateByAddingYears:0
                                                                                                  months:0
                                                                                                    days:0
                                                                                                   hours:8
                                                                                                 minutes:30
                                                                                                 seconds:0];
      if([start compare:now] == NSOrderedDescending)
         newStage = GrowlCalEventUpcoming;
      else if([start compare:now] == NSOrderedAscending && [dayOf compare:now] != NSOrderedAscending)
         newStage = GrowlCalEventUpcomingFired;
      else if([start compare:now] == NSOrderedAscending && [end compare:now] != NSOrderedAscending)
         newStage = GrowlCalEventCurrent;
      else if([end compare:now] == NSOrderedAscending)
         newStage = GrowlCalEventFinished;
      else
         newStage = GrowlCalEventFinished;
   }else{   
      NSInteger minutesBeforeEvent = [[NSUserDefaults standardUserDefaults] integerForKey:@"MinutesBeforeEvent"];
      if([(NSDate*)[NSDate dateWithTimeInterval:-60 * minutesBeforeEvent sinceDate:start] compare:now] == NSOrderedAscending)
         newStage = GrowlCalEventUpcoming;
      else if([start compare:now] == NSOrderedAscending)
         newStage = GrowlCalEventUpcomingFired;
      else if([start compare:now] == NSOrderedDescending && [end compare:now] != NSOrderedDescending)
         newStage = GrowlCalEventCurrent;
      else if([end compare:now] == NSOrderedDescending)
         newStage = GrowlCalEventFinished;
      else
         newStage = GrowlCalEventFinished;
   }
   if(newStage != _stage && newStage != GrowlCalEventUnknown){
      _stage = newStage;
      [self updateTimer];
   }
}

-(void)updateEvent:(CalEvent*)event
{
   self.event = _event;
   if([[event startDate] compare:[_event startDate]] != NSOrderedSame || [[event endDate] compare:[_event endDate]] != NSOrderedSame)
      [self determineStage];
}

-(void)fireNotification
{
   if(![[GrowlCalCalendarController sharedController] isNotificationEnabledForItem:_event])
      return;

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

   NSDate *current = [NSDate date];
   NSDate *start = [_event startDate];
   NSDate *end = [_event endDate];
   if(![_event isAllDay]){
      switch (_stage) {
         case GrowlCalEventUpcomingFired:
         {
            noteName = @"UpcomingEventAlert";
            NSInteger minutes = [start timeIntervalSinceDate:current] / 60;
            timeString = [NSString stringWithFormat:NSLocalizedString(@"%ld minutes", nil), minutes];
            noteDescription = NSLocalizedString(@"%@ will start in %@", @"");
            break;
         }
         case GrowlCalEventCurrent:
            noteName = @"EventAlert";
            timeString = [NSString stringWithFormat:NSLocalizedString(@"%@", @""), [dateTimeFormatter stringFromDate:start]];
            noteDescription = NSLocalizedString(@"%@ started at %@", @"Title format string for event started");
            break;
         case GrowlCalEventCurrentFired:
         {
            noteName = @"UpcomingEventEndAlert";
            NSInteger minutes = [end timeIntervalSinceDate:current] / 60;
            timeString = [NSString stringWithFormat:NSLocalizedString(@"%ld minutes", nil), minutes];
            noteDescription = NSLocalizedString(@"%@ will end in %@", @"");
            break;
         }
         case GrowlCalEventFinished:
            noteName = @"EventEndAlert";
            timeString = [NSString stringWithFormat:NSLocalizedString(@"%@", @""), [dateTimeFormatter stringFromDate:end]];
            noteDescription = NSLocalizedString(@"%@ ended at %@", @"Title format string for event ended");
            break;
         default:
            break;
      }
   }else{
      switch (_stage) {
         case GrowlCalEventUpcomingFired:
            noteName = @"UpcomingAllDayEventAlert";
            timeString = [dateFormatter stringFromDate:start];
            noteDescription = NSLocalizedString(@"%@ will start on %@ (all-day)", @"");
            break;
         case GrowlCalEventCurrent:
            noteName = @"AllDayEventAlert";
            timeString = [dateFormatter stringFromDate:start];
            noteDescription = NSLocalizedString(@"%@ started on %@ (all-day)", @"Title format string for event started");
            break;
         default:
            break;
      }
   }
      
   if(noteName && noteDescription)   
      [GrowlApplicationBridge notifyWithTitle:[_event title]
                                  description:[NSString stringWithFormat:noteDescription, [_event title], timeString]
                             notificationName:noteName
                                     iconData:nil
                                     priority:0
                                     isSticky:NO
                                 clickContext:nil
                                   identifier:[_event uid]];
}

-(void)fireAndAdvance
{
   switch (_stage) {
      case GrowlCalEventUpcoming:
         _stage = GrowlCalEventUpcomingFired;
         break;
      case GrowlCalEventUpcomingFired:
         _stage = GrowlCalEventCurrent;
         break;
      case GrowlCalEventCurrent:
         _stage = GrowlCalEventCurrentFired;
         break;
      case GrowlCalEventCurrentFired:
         _stage = GrowlCalEventFinished;
         break;
      case GrowlCalEventFinished:
      default:
         [_delegate removeFromEventList:[_event uid] date:[_event startDate]];
         return;
         break;
   }
   [self fireNotification];
   [self updateTimer];
}

-(void)nextTimerFire:(NSTimer*)timer
{
   [self fireAndAdvance];
}

@end
