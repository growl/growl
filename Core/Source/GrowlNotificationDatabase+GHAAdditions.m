//
//  GrowlNotificationDatabase+GHAAdditions.m
//  Growl
//
//  Created by Daniel Siemer on 10/5/10.
//  Copyright 2010 The Growl Project. All rights reserved.
//

#import "GrowlNotificationDatabase+GHAAdditions.h"
#import "GrowlTicketController.h"
#import "GrowlApplicationTicket.h"
#import "GrowlNotificationTicket.h"
#import "GrowlApplicationController.h"
#import "GrowlIdleStatusController.h"
#import "GrowlHistoryNotification.h"
#import "GrowlNotificationHistoryWindow.h"

@implementation GrowlNotificationDatabase (GHAAditions)

-(void)setupMaintenanceTimers
{   
   if(maintenanceTimer)
   {
      NSLog(@"Timer appears to already be setup, setupMaintenanceTimers should only be called once");
      return;
   }
   NSLog(@"Setup timer, this should only happen once");

   //Setup timers, every half hour for DB maintenance, every night for Cache cleanup   
   maintenanceTimer = [[NSTimer timerWithTimeInterval:30 * 60 
                                               target:self
                                             selector:@selector(storeMaintenance:)
                                             userInfo:nil
                                              repeats:YES] retain];
   [[NSRunLoop mainRunLoop] addTimer:maintenanceTimer forMode:NSRunLoopCommonModes];

   NSDateComponents *components = [[NSCalendar currentCalendar] components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:[NSDate date]];
   [components setDay:[components day] - 1];
   [components setHour:23];
   [components setMinute:59];
   lastImageCheck = [[[NSCalendar currentCalendar] dateFromComponents:components] retain];
   NSLog(@"Next image check no earlier than 24 hours from %@", lastImageCheck);
}

-(void)logNotificationWithDictionary:(NSDictionary*)noteDict
{
   
   BOOL deleteUponReturn = NO;
   GrowlPreferencesController *preferences = [GrowlPreferencesController sharedController];
   NSString *appName = [noteDict objectForKey:GROWL_APP_NAME];
   NSString *hostName = [noteDict objectForKey:GROWL_NOTIFICATION_GNTP_SENT_BY];
   GrowlApplicationTicket *ticket = [[GrowlTicketController sharedController] ticketForApplicationName:appName hostName:hostName];
   GrowlNotificationTicket *notificationTicket = [ticket notificationTicketForName:[noteDict objectForKey:GROWL_NOTIFICATION_NAME]];
   
   BOOL logging = [preferences isGrowlHistoryLogEnabled];
   BOOL appLogging = [ticket loggingEnabled];
   BOOL noteLogging = [notificationTicket logNotification];
   
   BOOL dontLog = (!logging || !appLogging || !noteLogging);
   
   BOOL isAway = GrowlIdleStatusController_isIdle();
   if(notificationsWhileAway || [[historyWindow window] isVisible])
      isAway = YES;
   //If the rollup isn't enabled, we aren't away, check last
   if(![preferences isRollupEnabled])
      isAway = NO;
   
   if(![self managedObjectContext])
   {
      NSLog(@"If we can't find/create the database, we can't log, return");
      return;
   }
   
   /* Ignore the notification if we arent logging and arent idle
    * Note that this breaks growl menu most recent notifications
    */
   if(dontLog){
      if(!isAway){
         //NSLog(@"We arent logging, and we arent away, return");
         return;
      }else{
         if(![preferences retainAllNotesWhileAway]){
            //NSLog(@"We are away, but not logging or retaining, or rollup is disabled, return");
            return;
         }else{
            //NSLog(@"We are away, shouldnt log this message, and we are rolling up, mark for deletion upon return");
            deleteUponReturn = YES;
         }
      }
   }
   
    void (^logBlock)(void) = ^{
       // NSError *error = nil;
        GrowlHistoryNotification *notification = [NSEntityDescription insertNewObjectForEntityForName:@"Notification" 
                                                                               inManagedObjectContext:managedObjectContext];
        
        // Whatever notification we set above, set its values and save
        [notification setWithNoteDictionary:noteDict];
        [notification setDeleteUponReturn:[NSNumber numberWithBool:deleteUponReturn]];
        [notification setShowInRollup:[NSNumber numberWithBool:isAway]];
    };
    if(![[NSThread currentThread] isMainThread])
        [managedObjectContext performBlockAndWait:logBlock];
    else
        logBlock();
    [self saveDatabase:NO];
   
   if(isAway)
   {
      notificationsWhileAway = YES;
      if(![preferences squelchMode] && [preferences isRollupAutomatic])
         [preferences setRollupShown:YES];
   }
}

-(void)showRollup
{
   if(![[GrowlPreferencesController sharedController] isRollupEnabled])
      return;
   
    if(!historyWindow)
    {
        GrowlNotificationHistoryWindow *window = [[GrowlNotificationHistoryWindow alloc] init];
        historyWindow = [window retain];
        [window release];
        [historyWindow window];
    }
    
    if(![[historyWindow window] isVisible])
    {
        [historyWindow resetArray];
       [historyWindow showWindow:self];
    }
}

-(void)hideRollup
{
   if([[historyWindow window] isVisible])
      [historyWindow close];
}

@end
