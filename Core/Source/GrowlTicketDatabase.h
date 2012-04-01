//
//  GrowlTicketDatabase.h
//  Growl
//
//  Created by Daniel Siemer on 2/21/12.
//  Copyright (c) 2012 The Growl Project. All rights reserved.
//

#import "GrowlAbstractDatabase.h"

@class GrowlTicketDatabaseApplication, GrowlTicketDatabasePlugin, GrowlTicketDatabaseDisplay;

@interface GrowlTicketDatabase : GrowlAbstractDatabase

+(GrowlTicketDatabase *)sharedInstance;

-(void)upgradeFromTicketFiles;

-(BOOL)registerApplication:(NSDictionary*)regDict;
-(BOOL)removeTicketForApplicationName:(NSString*)appName hostName:(NSString*)hostName;
-(GrowlTicketDatabaseApplication*)ticketForApplicationName:(NSString*)appName hostName:(NSString*)hostName;

-(GrowlTicketDatabasePlugin*)makeDefaultConfig:(BOOL)force forPluginDict:(NSDictionary*)noteDict;

-(void)createNewCompoundAction;
-(GrowlTicketDatabaseDisplay*)defaultDisplayConfig;
-(NSSet*)defaultActionConfigSet;
-(GrowlTicketDatabasePlugin*)pluginConfigForID:(NSString*)configID;
-(GrowlTicketDatabasePlugin*)actionForName:(NSString*)name;

@end
