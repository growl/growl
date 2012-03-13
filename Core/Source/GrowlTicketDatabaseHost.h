//
//  GrowlTicketDatabaseHost.h
//  Growl
//
//  Created by Daniel Siemer on 2/22/12.
//  Copyright (c) 2012 The Growl Project. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "GrowlTicketDatabaseTicket.h"


@interface GrowlTicketDatabaseHost : GrowlTicketDatabaseTicket

@property (nonatomic, retain) NSNumber * localhost;

@end
