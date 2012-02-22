//
//  GrowlTicketDatabaseNotification.h
//  Growl
//
//  Created by Daniel Siemer on 2/22/12.
//  Copyright (c) 2012 The Growl Project. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "GrowlTicketDatabaseTicket.h"

@class GrowlNotificationTicket;

@interface GrowlTicketDatabaseNotification : GrowlTicketDatabaseTicket

@property (nonatomic, retain) NSNumber * defaultEnabled;
@property (nonatomic, retain) NSString * humanReadableName;
@property (nonatomic, retain) NSNumber * priority;
@property (nonatomic, retain) NSNumber * sticky;

-(void)setWithNotificationTicket:(GrowlNotificationTicket*)ticket;

@end
