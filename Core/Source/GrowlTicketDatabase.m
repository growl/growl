//
//  GrowlTicketDatabase.m
//  Growl
//
//  Created by Daniel Siemer on 2/21/12.
//  Copyright (c) 2012 The Growl Project. All rights reserved.
//

#import "GrowlTicketDatabase.h"
#import "GrowlPathUtilities.h"
#import "GrowlTicketController.h"
#import "GrowlDefines.h"

#import "NSStringAdditions.h"
#import "GrowlTicketDatabaseTicket.h"
#import "GrowlTicketDatabaseHost.h"
#import "GrowlTicketDatabaseApplication.h"

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


/* Returns a GrowlTicketDatabaseHost for the given hostname, if it doesn't exist, it is created and inserted */
-(GrowlTicketDatabaseHost*)hostWithName:(NSString*)hostname {
   __block GrowlTicketDatabaseHost *host = nil;
   void (^hostBlock)(void) = ^{
      NSError *hostErr = nil;
      
      NSFetchRequest *hostCheck = [NSFetchRequest fetchRequestWithEntityName:@"GrowlHostTicket"];
      [hostCheck setPredicate:[NSPredicate predicateWithFormat:@"name == %@", hostname]];
      NSArray *hosts = [managedObjectContext executeFetchRequest:hostCheck error:&hostErr];
      if(hostErr)
      {
         NSLog(@"Unresolved error %@, %@", hostErr, [hostErr userInfo]);
         return;
      }
      
      if([hosts count] == 0) {
         host = [NSEntityDescription insertNewObjectForEntityForName:@"GrowlHostTicket"
                                                   inManagedObjectContext:managedObjectContext];
         [host setName:hostname];
         if([hostname isEqualToString:@"Localhost"])
            [host setLocalhost:[NSNumber numberWithBool:YES]];
      }else{
         host = [hosts objectAtIndex:0];
      }
   };
   
   if([NSThread isMainThread])
      hostBlock();
   else
      [managedObjectContext performBlockAndWait:hostBlock];
   
   return host;
}

-(void)upgradeFromTicketFiles {
   __block BOOL importedTickets = NO;
   __block GrowlTicketDatabase *blockSelf = self;
   [managedObjectContext performBlockAndWait:^{
      
      GrowlTicketController *controller = [[GrowlTicketController alloc] init];
      [controller loadAllSavedTickets];
      [[controller allSavedTickets] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
			if([[obj applicationName] caseInsensitiveCompare:@"Growl"] == NSOrderedSame) 
				return;
			
         GrowlTicketDatabaseHost *host = [blockSelf hostWithName:(!obj || [obj isLocalHost]) ? @"Localhost" : [obj hostName]];
         
         GrowlTicketDatabaseApplication *app = [NSEntityDescription insertNewObjectForEntityForName:@"GrowlApplicationTicket"
                                                                             inManagedObjectContext:managedObjectContext];
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
         GrowlTicketDatabaseHost *host = [blockSelf hostWithName:(!hostName || [hostName isLocalHost]) ? @"Localhost" : hostName];
         
         app = [NSEntityDescription insertNewObjectForEntityForName:@"GrowlApplicationTicket"
                                             inManagedObjectContext:managedObjectContext];
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
   __block GrowlTicketDatabaseApplication *app = nil;
   void (^appBlock)(void) = ^{
      NSError *appErr = nil;
      
      NSFetchRequest *appCheck = [NSFetchRequest fetchRequestWithEntityName:@"GrowlApplicationTicket"];
      [appCheck setPredicate:[NSPredicate predicateWithFormat:@"name == %@ AND parent.name == %@", appName, ((!hostName || [hostName isLocalHost]) ? @"Localhost" : hostName)]];
      NSArray *apps = [managedObjectContext executeFetchRequest:appCheck error:&appErr];
      if(appErr)
      {
         NSLog(@"Unresolved error %@, %@", appErr, [appErr userInfo]);
         return;
      }
      
      if([apps count] == 0) {
         NSLog(@"Could not find application: %@ for host: %@", appName, hostName);
      }else{
         app = [apps objectAtIndex:0U];
      }
   };
   
   if([NSThread isMainThread])
      appBlock();
   else
      [managedObjectContext performBlockAndWait:appBlock];
   
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
   __block GrowlTicketDatabaseApplication *app = nil;
   void (^appBlock)(void) = ^{
      NSError *appErr = nil;
      
      NSFetchRequest *appCheck = [NSFetchRequest fetchRequestWithEntityName:@"GrowlApplicationTicket"];
      [appCheck setPredicate:[NSPredicate predicateWithFormat:@"name == %@ && parent.name == %@", appName, ((!hostName || [hostName isLocalHost]) ? @"Localhost" : hostName)]];
      NSArray *apps = [managedObjectContext executeFetchRequest:appCheck error:&appErr];
      if(appErr)
      {
         NSLog(@"Unresolved error %@, %@", appErr, [appErr userInfo]);
         return;
      }
      
      if([apps count] == 0) {
         NSLog(@"Could not find application: %@ for host: %@", appName, hostName);
      }else{
         app = [apps objectAtIndex:0U];
      }
   };
   
   if([NSThread isMainThread])
      appBlock();
   else
      [managedObjectContext performBlockAndWait:appBlock];
   return app;
}

-(GrowlTicketDatabaseAction*)actionForName:(NSString*)name {
	__block GrowlTicketDatabaseAction *action = nil;
   void (^actionBlock)(void) = ^{
      NSError *actionErr = nil;
      
      NSFetchRequest *actionCheck = [NSFetchRequest fetchRequestWithEntityName:@"GrowlAction"];
      [actionCheck setPredicate:[NSPredicate predicateWithFormat:@"name == %@", name]];
      NSArray *actions = [managedObjectContext executeFetchRequest:actionCheck error:&actionErr];
      if(actionErr)
      {
         NSLog(@"Unresolved error %@, %@", actionErr, [actionErr userInfo]);
         return;
      }
      
      if([actions count] == 0) {
         NSLog(@"Could not find action entry for: %@", actionErr);
      }else{
         action = [actions objectAtIndex:0U];
      }
   };
   
   if([NSThread isMainThread])
      actionBlock();
   else
      [managedObjectContext performBlockAndWait:actionBlock];
   return action;
}

@end
