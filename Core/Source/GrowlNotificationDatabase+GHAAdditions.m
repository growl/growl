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
