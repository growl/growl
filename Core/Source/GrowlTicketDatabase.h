//
//  GrowlTicketDatabase.h
//  Growl
//
//  Created by Daniel Siemer on 2/21/12.
//  Copyright (c) 2012 The Growl Project. All rights reserved.
//

#import "GrowlAbstractDatabase.h"

@class GrowlTicketDatabaseApplication;

@interface GrowlTicketDatabase : GrowlAbstractDatabase

+(GrowlTicketDatabase *)sharedInstance;

-(void)upgradeFromTicketFiles;

-(BOOL)registerApplication:(NSDictionary*)regDict;
-(BOOL)removeTicketForApplicationName:(NSString*)appName hostName:(NSString*)hostName;
-(GrowlTicketDatabaseApplication*)ticketForApplicationName:(NSString*)appName hostName:(NSString*)hostName;

@end
