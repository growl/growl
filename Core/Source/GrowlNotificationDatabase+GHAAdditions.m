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

@implementation GrowlNotificationDatabase (GHAAditions)

-(void)setupMaintenanceTimers
{
   //While this is only compiled with GHA, we want to be really sure we are GHA.
   if(![[[NSProcessInfo processInfo] processName] isEqualToString:@"GrowlHelperApp"])
   {
      NSLog(@"We arent GHA, we shouldn't be setting up maintenance timers");
      return;
   }
   
   if(maintenanceTimer || cacheMaintenenceTimer)
   {
      NSLog(@"Timers appear to already be setup, setupMaintenanceTimers should only be called once");
      return;
   }
   NSLog(@"Setup timers, this should only happen once");

   //Setup timers, every half hour for DB maintenance, every night for Cache cleanup   
   maintenanceTimer = [[NSTimer timerWithTimeInterval:30 * 60 
                                               target:self
                                             selector:@selector(storeMaintenance:)
                                             userInfo:nil
                                              repeats:YES] retain];
   [[NSRunLoop mainRunLoop] addTimer:maintenanceTimer forMode:NSRunLoopCommonModes];
   //TODO: Fix this to use ~midnight
   NSDateComponents *components = [[NSCalendar currentCalendar] components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:[NSDate date]];
   [components setHour:23];
   [components setMinute:59];
   NSDate *firstImageCacheDate = [[NSCalendar currentCalendar] dateFromComponents:components];
   NSLog(@"First image cache check will run at %@", firstImageCacheDate);
   cacheMaintenenceTimer = [[NSTimer alloc] initWithFireDate:firstImageCacheDate
                                                    interval:24 * 3600
                                                      target:self
                                                    selector:@selector(imageCacheMaintenance:) 
                                                    userInfo:nil
                                                     repeats:YES];
   [[NSRunLoop mainRunLoop] addTimer:cacheMaintenenceTimer forMode:NSRunLoopCommonModes];
}

-(void)logNotificationWithDictionary:(NSDictionary*)noteDict
{
   NSError *error = nil;
   if(![[GrowlNotificationDatabase sharedInstance] managedObjectContext])
      return;
   
   //Ignore our own notification, it would be a bit recursive, and infinite loopish...
   if([[noteDict objectForKey:GROWL_APP_NAME] isEqualToString:@"Growl"] && [[noteDict objectForKey:GROWL_NOTIFICATION_NAME] isEqualToString:NOTIFICATION_HISTORY_NOTIFICATION])
      return;
   
   //Ignore the notification if we arent logging and arent idle
   //Note that this breaks growl menu most recent notifications
   if(![[GrowlPreferencesController sharedController] isGrowlHistoryLogEnabled] && !GrowlIdleStatusController_isIdle())
      return;
   
   //decide whether we will delete this message upon the user having returned/read it
   BOOL deleteUponReturn = NO;
   if(![[GrowlPreferencesController sharedController] isGrowlHistoryLogEnabled] && GrowlIdleStatusController_isIdle())
      deleteUponReturn = YES;
   
   //Check the ticket for the notification to see if we should log it, if no and we are idle, flag for delete
   GrowlApplicationTicket *ticket = [[GrowlTicketController sharedController] ticketForApplicationName:[noteDict objectForKey:GROWL_APP_NAME]];
   GrowlNotificationTicket *notificationTicket = [ticket notificationTicketForName:[noteDict objectForKey:GROWL_NOTIFICATION_NAME]];
   //   if(![notificationTicket logNotification] && !GrowlIdleStatusController_isIdle())
   //      return;
   if(![notificationTicket logNotification] && GrowlIdleStatusController_isIdle())
      deleteUponReturn = YES;
   
   GrowlHistoryNotification *notification = [NSEntityDescription insertNewObjectForEntityForName:@"Notification" inManagedObjectContext:[[GrowlNotificationDatabase sharedInstance] managedObjectContext]];
   
   // Whatever notification we set above, set its values and save
   [notification setWithNoteDictionary:noteDict];
   [notification setDeleteUponReturn:[NSNumber numberWithBool:deleteUponReturn]];
   if (![[notification managedObjectContext] save:&error])
      NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
}

@end
