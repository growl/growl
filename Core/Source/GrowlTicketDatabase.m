//
//  GrowlTicketDatabase.m
//  Growl
//
//  Created by Daniel Siemer on 2/21/12.
//  Copyright (c) 2012 The Growl Project. All rights reserved.
//

#import "GrowlTicketDatabase.h"
#import "GrowlPathUtilities.h"
#import "GrowlPluginController.h"
#import "GrowlTicketController.h"
#import "GrowlPluginController.h"
#import "GrowlWebKitDisplayPlugin.h"
#import "GrowlDefines.h"
#import <GrowlPlugins/GrowlPlugin.h>
#import <GrowlPlugins/GrowlActionPlugin.h>

#import "NSStringAdditions.h"
#import "GrowlTicketDatabaseTicket.h"
#import "GrowlTicketDatabaseHost.h"
#import "GrowlTicketDatabaseApplication.h"
#import "GrowlTicketDatabasePlugin.h"
#import "GrowlTicketDatabaseAction.h"
#import "GrowlTicketDatabaseDisplay.h"

@implementation GrowlTicketDatabase

+(GrowlTicketDatabase *)sharedInstance {
   static GrowlTicketDatabase *instance = nil;
   static dispatch_once_t onceToken;
   dispatch_once(&onceToken, ^{
      instance = [[self alloc] init];
   });
   return instance;
}

-(id)init {
   if((self = [super init])) {
   }
   return self;
}
       
-(void)dealloc {
   [super dealloc];
}

-(NSString*)storePath {
   return [[GrowlPathUtilities growlSupportDirectory] stringByAppendingPathComponent:@"tickets.database"];
}
-(NSString*)storeType {
   return @"Growl Tickets Database";
}
-(NSString*)modelName {
   return @"GrowlTicketDatabase.momd";
}

-(void)launchFailed {
   NSBeginCriticalAlertSheet(NSLocalizedString(@"Warning! Application preferences will not be saved", @"alert that Growl will be limited to in memory for tickets"),
                             NSLocalizedString(@"Ok", @""),
                             nil, nil, nil, nil, nil, NULL, NULL, 
                             NSLocalizedString(@"An uncorrectable error occured in creating or opening the Growl Tickets Database.\nApplications may register, and you can adjust settings.\nHowever, no registrations or settings will be saved to the next session, and Growl may use more memory", @""));
}

-(NSManagedObject*)managedObjectForEntity:(NSString*)entity predicate:(NSPredicate*)predicate {
	__block NSManagedObject *object = nil;
	__block NSManagedObjectContext *blockContext = self.managedObjectContext;
   void (^objectBlock)(void) = ^{
      NSError *objectErr = nil;
      
      NSFetchRequest *objectCheck = [NSFetchRequest fetchRequestWithEntityName:entity];
		if(predicate)
			[objectCheck setPredicate:predicate];
      NSArray *objectArray = [blockContext executeFetchRequest:objectCheck error:&objectErr];
      if(objectErr)
      {
         NSLog(@"Unresolved error %@, %@", objectErr, [objectErr userInfo]);
         return;
      }
		
      if([objectArray count] == 0) {
         NSLog(@"Could not find %@ entry for predicate %@", entity, [predicate predicateFormat]);
      }else{
			if ([objectArray count] > 1) {
				NSLog(@"Taking first %@ matching %@, %lu others", entity, [predicate predicateFormat], [objectArray count] - 1);
			}
			object = [objectArray objectAtIndex:0U];
      }
   };
   
   if([NSThread isMainThread])
      objectBlock();
   else
      [managedObjectContext performBlockAndWait:objectBlock];
   return object;

}

/* Returns a GrowlTicketDatabaseHost for the given hostname, if it doesn't exist, it is created and inserted */
-(GrowlTicketDatabaseHost*)hostWithName:(NSString*)hostname {
	hostname = (!hostname || [hostname isLocalHost]) ? @"Localhost" : hostname;
   __block GrowlTicketDatabaseHost *host = (GrowlTicketDatabaseHost*)[self managedObjectForEntity:@"GrowlHostTicket"
																													 predicate:[NSPredicate predicateWithFormat:@"name == %@", hostname]];
	__block NSManagedObjectContext *blockContext = self.managedObjectContext;
	if(!host) {
		void (^hostBlock)(void) = ^{
			host = [NSEntityDescription insertNewObjectForEntityForName:@"GrowlHostTicket"
															 inManagedObjectContext:blockContext];
			[host setName:hostname];
			if([hostname isEqualToString:@"Localhost"])
				[host setLocalhost:[NSNumber numberWithBool:YES]];
		};
		if([NSThread isMainThread])
			hostBlock();
		else
			[managedObjectContext performBlockAndWait:hostBlock];
	}
   
   return host;
}

-(GrowlTicketDatabasePlugin*)makeDefaultConfigForPluginDict:(NSDictionary*)noteDict {
	__block GrowlTicketDatabasePlugin *newConfig = nil;
	NSString *pluginName = [noteDict valueForKey:GrowlPluginInfoKeyName];
	GrowlPlugin *plugin = [[GrowlPluginController sharedController] pluginInstanceWithName:pluginName];
	newConfig = (GrowlTicketDatabasePlugin*)[self managedObjectForEntity:@"GrowlPlugin" 
																				  predicate:[NSPredicate predicateWithFormat:@"pluginID == %@", [[plugin bundle] bundleIdentifier]]];
	if(newConfig){
		NSLog(@"At least one configuration entry already exists for bundle id %@, returning the existing config", [[plugin bundle] bundleIdentifier]);
		return newConfig;
	}
	
	__block NSManagedObjectContext *blockContext = self.managedObjectContext;
	void (^pluginBlock)(void) = ^{
		NSString *type = [plugin isKindOfClass:[GrowlActionPlugin class]] ? @"GrowlAction" : @"GrowlDisplay";
		
		newConfig = [NSEntityDescription insertNewObjectForEntityForName:type
																inManagedObjectContext:blockContext];
		newConfig.pluginType = type;
		newConfig.displayName = pluginName;
		newConfig.pluginID = [[plugin bundle] bundleIdentifier];
		newConfig.configID = [[NSProcessInfo processInfo] globallyUniqueString];
		
		NSString *prefsID = [plugin prefDomain];
		if(prefsID){
			NSDictionary *configDict = [[GrowlPreferencesController sharedController] objectForKey:prefsID];
			NSLog(@"setting config dict for %@ with %@", pluginName, configDict);
			if(configDict)
				newConfig.configuration = configDict;
		}
	};
	
	if([NSThread isMainThread])
      pluginBlock();
   else
      [managedObjectContext performBlockAndWait:pluginBlock];
	return newConfig;
}

-(void)upgradeFromTicketFiles {
   __block BOOL importedTickets = NO;
   __block GrowlTicketDatabase *blockSelf = self;
   [managedObjectContext performBlockAndWait:^{
		/* Pull in default configurations for each existing plugin */
		NSArray *actions = [managedObjectContext executeFetchRequest:[NSFetchRequest fetchRequestWithEntityName:@"GrowlPlugin"] error:nil];
		if(!actions || [actions count] == 0){
			GrowlPluginController *pluginController = [GrowlPluginController sharedController];
			[pluginController performSelector:@selector(loadPlugins)];
			NSArray *pluginArray = [[pluginController displayPlugins] copy];
			NSString *defaultStyleName = [[GrowlPreferencesController sharedController] defaultDisplayPluginName];
			__block BOOL foundDefault = NO;
			__block NSString *firstDisplayUUID = nil;
			__block NSString *smokeUUID = nil;
			[pluginArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
				GrowlTicketDatabasePlugin *config = [blockSelf makeDefaultConfigForPluginDict:obj];
				if([[config pluginType] caseInsensitiveCompare:@"GrowlDisplay"] == NSOrderedSame &&
					!firstDisplayUUID)
				{
					firstDisplayUUID = firstDisplayUUID;
				}
				if([[config pluginType] caseInsensitiveCompare:@"GrowlDisplay"] == NSOrderedSame&& 
					[[config displayName] caseInsensitiveCompare:defaultStyleName] == NSOrderedSame){
					[[GrowlPreferencesController sharedController] setDefaultDisplayPluginName:[config configID]];
					foundDefault = YES;
				}
				if([[config displayName] caseInsensitiveCompare:@"Smoke"] == NSOrderedSame){
					smokeUUID = [config configID];
				}
			}];
			if(!foundDefault && smokeUUID){
				[[GrowlPreferencesController sharedController] setDefaultDisplayPluginName:smokeUUID];
			}else if(!foundDefault && !smokeUUID && firstDisplayUUID){
				[[GrowlPreferencesController sharedController] setDefaultDisplayPluginName:firstDisplayUUID];
			}else{
				NSLog(@"There was an error, there should be some display plugins during import");
			}
			[pluginArray release];
		}
		
		/* Pull in ticket for each existing app ticket */
      GrowlTicketController *controller = [[GrowlTicketController alloc] init];
      [controller loadAllSavedTickets];
      [[controller allSavedTickets] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
			if([[obj applicationName] caseInsensitiveCompare:@"Growl"] == NSOrderedSame) 
				return;
			
         GrowlTicketDatabaseHost *host = [blockSelf hostWithName:[obj hostName]];
         
         GrowlTicketDatabaseApplication *app = [NSEntityDescription insertNewObjectForEntityForName:@"GrowlApplicationTicket"
                                                                             inManagedObjectContext:[blockSelf managedObjectContext]];
         [app setParent:host];
         [app setWithApplicationTicket:obj];
         importedTickets = YES;
      }];
      [controller release];
   }];
   [self saveDatabase:YES];
   
   //If we imported any, move the tickets directory to a backup location
   //We do this only if we imported because [GrowlPathUtilities ticketsDirectory] will create the directory if it doesn't exist
   if(importedTickets){
      NSString *ticketsPath = [GrowlPathUtilities ticketsDirectory];
      if(ticketsPath){
         NSError *moveErr = nil;
         if(![[NSFileManager defaultManager] moveItemAtPath:ticketsPath
                                                     toPath:[ticketsPath stringByAppendingPathExtension:@"bak"]
                                                      error:&moveErr])
         {
            NSLog(@"Error trying to rename Tickets directory to Tickets.bak\n %@ : %@", moveErr, [moveErr userInfo]);
         }else{
            NSLog(@"Finished importing tickets, and moved Tickets directory to BackupTickets");
         }
      }
      [managedObjectContext performBlock:^{
         NSFetchRequest *test = [NSFetchRequest fetchRequestWithEntityName:@"GrowlApplicationTicket"];
         NSArray *testResult = [managedObjectContext executeFetchRequest:test error:nil];
         [testResult enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSLog(@"Imported: %@ on host %@ with %lu notifications", [obj name], [[obj parent] name], [[obj children] count]);
         }];
      }];
   }
}

-(BOOL)registerApplication:(NSDictionary*)regDict {
	NSString *appName = [regDict objectForKey:GROWL_APP_NAME];
   if(!appName){
      NSLog(@"Cannot register without an application name!");
      return NO;
   }
	
	if([appName caseInsensitiveCompare:@"Growl"] == NSOrderedSame) {
		NSLog(@"Growl should not register with itself!");
		return NO;
	}
	
   NSString *hostName = [regDict objectForKey:GROWL_NOTIFICATION_GNTP_SENT_BY];
   
   
   void (^appBlock)(void) = nil;
   __block GrowlTicketDatabaseApplication *app = [self ticketForApplicationName:appName hostName:hostName];
   if(!app){
      __block GrowlTicketDatabase *blockSelf = self;
      appBlock = ^{
         GrowlTicketDatabaseHost *host = [blockSelf hostWithName:hostName];
         
         app = [NSEntityDescription insertNewObjectForEntityForName:@"GrowlApplicationTicket"
                                             inManagedObjectContext:[blockSelf managedObjectContext]];
         [app setParent:host];
         [app registerWithDictionary:regDict];
      };
   }else{
      appBlock = ^{
         [app reregisterWithDictionary:regDict];
      };
   }
   
   if([NSThread isMainThread])
      appBlock();
   else
      [managedObjectContext performBlockAndWait:appBlock];
   
   return app != nil;
}

-(BOOL)removeTicketForApplicationName:(NSString*)appName hostName:(NSString*)hostName {
	GrowlTicketDatabaseApplication *app = [self ticketForApplicationName:appName hostName:hostName];

   if(!app)
      return NO;
   
   [managedObjectContext deleteObject:app];
   [self saveDatabase:NO];
   return YES;
}

-(GrowlTicketDatabaseApplication*)ticketForApplicationName:(NSString*)appName hostName:(NSString*)hostName {
	if([appName caseInsensitiveCompare:@"Growl"] == NSOrderedSame){
		return nil;
	}
   NSString *resolvedHost = ((!hostName || [hostName isLocalHost]) ? @"Localhost" : hostName);
	return (GrowlTicketDatabaseApplication*)[self managedObjectForEntity:@"GrowlApplicationTicket" 
																				  predicate:[NSPredicate predicateWithFormat:@"name == %@ && parent.name == %@", appName, resolvedHost]];
}

-(GrowlTicketDatabaseDisplay*)defaultDisplayConfig {
	NSString *defaultDisplayID = [[GrowlPreferencesController sharedController] defaultDisplayPluginName];
	//This is the case where there is intentionally no default display
	if(!defaultDisplayID || [defaultDisplayID isEqualToString:@""]) 
		return nil;
	
	__block GrowlTicketDatabaseDisplay* plugin = (GrowlTicketDatabaseDisplay*)[self pluginConfigForID:defaultDisplayID];
	if(!plugin || ![plugin canFindInstance]) {
		//resolve to a smoke display config if possible
		plugin = (GrowlTicketDatabaseDisplay*)[self managedObjectForEntity:@"GrowlDisplay" 
																				  predicate:[NSPredicate predicateWithFormat:@"pluginID == %@", @"com.Growl.Smoke"]];
		if(!plugin || ![plugin canFindInstance]){
			__block NSManagedObjectContext *blockContext = self.managedObjectContext;
			void (^pluginBlock)(void) = ^{
				NSError *pluginErr = nil;
				
				NSFetchRequest *objectCheck = [NSFetchRequest fetchRequestWithEntityName:@"GrowlDisplay"];
				NSArray *pluginArray = [blockContext executeFetchRequest:objectCheck error:&pluginErr];
				if(pluginErr)
				{
					NSLog(@"Unresolved error %@, %@", pluginErr, [pluginErr userInfo]);
					return;
				}
				
				if([pluginArray count] == 0) {
					NSLog(@"Could not find any display plugin configs!");
				}else{
					[pluginArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
						if([obj isKindOfClass:[GrowlTicketDatabaseDisplay class]] && [obj canFindInstance]){
							plugin = obj;
							*stop = YES;
						}
					}];
				}
			};
			
			if([NSThread isMainThread])
				pluginBlock();
			else
				[managedObjectContext performBlockAndWait:pluginBlock];
			
		}
	}
	return plugin;
}

-(NSSet*)defaultActionConfigSet {
	NSArray *actionIDs = [[GrowlPreferencesController sharedController] defaultActionPluginIDArray];
	__block NSMutableSet *resolvedSet = [NSMutableSet set];
	[actionIDs enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		GrowlTicketDatabasePlugin *plugin = [self pluginConfigForID:obj];
		if (plugin && [plugin isKindOfClass:[GrowlTicketDatabaseAction class]]) {
			[resolvedSet addObject:plugin];
		}
	}];
	if([resolvedSet count] > 0)
		return resolvedSet;
	else
		return nil;
}

-(GrowlTicketDatabasePlugin*)pluginConfigForID:(NSString*)configID {
	return (GrowlTicketDatabasePlugin*)[self managedObjectForEntity:@"GrowlPlugin" 
																			predicate:[NSPredicate predicateWithFormat:@"configID == %@", configID]];
}

-(GrowlTicketDatabasePlugin*)actionForName:(NSString*)name {
   return (GrowlTicketDatabasePlugin*)[self managedObjectForEntity:@"GrowlPlugin" 
																			predicate:[NSPredicate predicateWithFormat:@"displayName == %@", name]];
}

@end
