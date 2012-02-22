//
//  GrowlTicketDatabaseApplication.m
//  Growl
//
//  Created by Daniel Siemer on 2/22/12.
//  Copyright (c) 2012 The Growl Project. All rights reserved.
//

#import "GrowlTicketDatabaseApplication.h"
#import "GrowlApplicationTicket.h"
#import "GrowlTicketDatabaseNotification.h"

@implementation GrowlTicketDatabaseApplication

@dynamic appID;
@dynamic appPath;

-(void)setWithApplicationTicket:(GrowlApplicationTicket*)ticket {
   self.enabled = [NSNumber numberWithBool:[ticket ticketEnabled]];
   self.iconData = [ticket iconData];
   self.loggingEnabled = [NSNumber numberWithBool:[ticket loggingEnabled]];
   self.name = ticket.applicationName;
   self.positionType = [NSNumber numberWithInteger:[ticket positionType]];
   self.selectedPosition = [NSNumber numberWithInteger:[ticket selectedPosition]];
   self.appID = ticket.appID;
   self.appPath = ticket.appPath;
   
   [[ticket notifications] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      GrowlTicketDatabaseNotification *note = [NSEntityDescription insertNewObjectForEntityForName:@"GrowlNotificationTicket"
                                                                            inManagedObjectContext:[self managedObjectContext]];
      [note setParent:self];
      [note setWithNotificationTicket:obj];
   }];
}

@end
