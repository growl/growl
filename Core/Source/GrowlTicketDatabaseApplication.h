//
//  GrowlTicketDatabaseApplication.h
//  Growl
//
//  Created by Daniel Siemer on 2/22/12.
//  Copyright (c) 2012 The Growl Project. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "GrowlTicketDatabaseTicket.h"

@class GrowlApplicationTicket, GrowlTicketDatabaseNotification;

@interface GrowlTicketDatabaseApplication : GrowlTicketDatabaseTicket

@property (nonatomic, retain) NSString * appID;
@property (nonatomic, retain) NSString * appPath;

-(void)setWithApplicationTicket:(GrowlApplicationTicket*)ticket;
-(void)registerWithDictionary:(NSDictionary*)regDict;
-(void)reregisterWithDictionary:(NSDictionary*)regDict;

-(GrowlTicketDatabaseNotification*)notificationTicketForName:(NSString*)noteName;

@end
