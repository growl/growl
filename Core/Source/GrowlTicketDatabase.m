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
      [[NSNotificationCenter defaultCenter] addObserver:self
                                               selector:@selector(registerApplication:)
                                                   name:@"ApplicationRegistered"
                                                 object:nil];
   }
   return self;
}
       
-(void)dealloc {
   [[NSNotificationCenter defaultCenter] removeObserver:self];
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
      [hostCheck setPredicate:[NSPredicate predicateWithFormat:@"name = %@", hostname]];
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
         GrowlTicketDatabaseHost *host = [blockSelf hostWithName:([obj isLocalHost]) ? @"Localhost" : [obj hostName]];
         
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

-(void)registerApplication:(NSNotification*)note {
   
}

@end
