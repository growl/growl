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

@class GrowlApplicationTicket;

@interface GrowlTicketDatabaseApplication : GrowlTicketDatabaseTicket

@property (nonatomic, retain) NSString * appID;
@property (nonatomic, retain) NSString * appPath;

-(void)setWithApplicationTicket:(GrowlApplicationTicket*)ticket;

@end
