//
//  GNTPForwarder.m
//  Growl
//
//  Created by Daniel Siemer on 11/19/11.
//  Copyright (c) 2011 The Growl Project. All rights reserved.
//

#import "GNTPForwarder.h"
#import "GrowlBrowserEntry.h"
#import "NSStringAdditions.h"
#import "GrowlPreferencesController.h"
#import "GrowlNetworkUtilities.h"
#import "GrowlBonjourBrowser.h"
#import "GrowlNetworkObserver.h"
#import "GrowlDefines.h"
#import "GrowlGNTPDefines.h"
#import <GrowlPlugins/GrowlKeychainUtilities.h>

#import "GrowlTicketDatabase.h"
#import "GrowlTicketDatabaseApplication.h"

#import "GrowlXPCCommunicationAttempt.h"
#import "GrowlXPCNotificationAttempt.h"
#import "GrowlXPCRegistrationAttempt.h"

@interface GNTPForwarder ()

@property (nonatomic, retain) NSMutableArray *attemptArray;
@property (nonatomic, retain) NSMutableArray *attemptQueue;

@end

@implementation GNTPForwarder

@synthesize preferences;
@synthesize destinations;
@synthesize alreadyBrowsing;

@synthesize attemptArray = _attemptArray;

+ (GNTPForwarder*)sharedController {
   static GNTPForwarder *instance;
   static dispatch_once_t onceToken;
   dispatch_once(&onceToken, ^{
      instance = [[self alloc] init];
   });
   return instance;
}

- (id)init {
   if((self = [super init])) {
      self.alreadyBrowsing = NO;
      self.preferences = [GrowlPreferencesController sharedController];
      
      // create a deep mutable copy of the forward destinations
      NSArray *dests = [self.preferences objectForKey:GrowlForwardDestinationsKey];
      __block NSMutableArray *theServices = [NSMutableArray array];
      __block GNTPForwarder *blockFowarder = self;
      [dests enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
         if([obj isKindOfClass:[NSDictionary dictionary]])
            return;
         
         GrowlBrowserEntry *entry = [[GrowlBrowserEntry alloc] initWithDictionary:obj];
         [entry setOwner:blockFowarder];
         [theServices addObject:entry];
         [entry release];
      }];
      [self setDestinations:theServices];
      
      NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
      [center addObserver:self
                 selector:@selector(appRegistered:)
                     name:@"ApplicationRegistered"
                   object:nil];
      
      [center addObserver:self 
                 selector:@selector(serviceFound:) 
                     name:GNTPServiceFoundNotification 
                   object:[GrowlBonjourBrowser sharedBrowser]];
      [center addObserver:self 
                 selector:@selector(serviceRemoved:) 
                     name:GNTPServiceRemovedNotification 
                   object:[GrowlBonjourBrowser sharedBrowser]];
      [center addObserver:self 
                 selector:@selector(browserStopped:) 
                     name:GNTPBrowserStopNotification 
                   object:[GrowlBonjourBrowser sharedBrowser]];
      [center addObserver:self
                 selector:@selector(addressChanged:)
                     name:PrimaryIPChangeNotification
                   object:[GrowlNetworkObserver sharedObserver]];
      
      [center addObserver:self
                 selector:@selector(preferencesChanged:) 
                     name:GrowlPreferencesChanged 
                   object:nil];
      [self preferencesChanged:nil];
   }
   return self;
}

- (void)dealloc {
   [[NSNotificationCenter defaultCenter] removeObserver:self];
   [destinations release];
   [super dealloc];
}

- (void)preferencesChanged:(NSNotification*)note {
   id object = [note object];
   if(!object || [object isEqualToString:GrowlEnableForwardKey]){
      if([preferences isForwardingEnabled] && !alreadyBrowsing){
         [[GrowlBonjourBrowser sharedBrowser] startBrowsing];
         self.alreadyBrowsing = YES;
      }else if(![preferences isForwardingEnabled] && alreadyBrowsing){
         [[GrowlBonjourBrowser sharedBrowser] stopBrowsing];
         self.alreadyBrowsing = NO;
      }
   }
   if(!object || [object isEqualToString:@"AddressCachingEnabled"]){
      if(![preferences boolForKey:@"AddressCachingEnabled"]){
         [self clearCachedAddresses];
      }
   }
}

- (void)clearCachedAddresses
{
   [destinations enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      [obj setLastKnownAddress:nil];
   }];
}

#pragma mark UI Support

- (void)newManualEntry {
   GrowlBrowserEntry *newEntry = [[[GrowlBrowserEntry alloc] initWithComputerName:@""] autorelease];
   [newEntry setManualEntry:YES];
   [newEntry setOwner:self];
   [self willChangeValueForKey:@"destinations"];
   [destinations addObject:newEntry];
   [self didChangeValueForKey:@"destinations"];
}

- (void)removeEntryAtIndex:(NSUInteger)index {
    if(index >= [destinations count])
        return;
   
    GrowlBrowserEntry *toRemove = [destinations objectAtIndex:index];
    
    if([toRemove password])
        if(![GrowlKeychainUtilities removePasswordForService:GrowlOutgoingNetworkPassword accountName:[toRemove uuid]])
            NSLog(@"Error removing password from keychain for %@", [toRemove computerName]);

    [self willChangeValueForKey:@"destinations"];
    [destinations removeObjectAtIndex:index];
    [self didChangeValueForKey:@"destinations"];
    [self writeForwardDestinations];
}

- (void)writeForwardDestinations {
   NSArray *currentNames = [[self.preferences objectForKey:GrowlForwardDestinationsKey] valueForKey:@"computer"];
	NSMutableArray *newDestinations = [[NSMutableArray alloc] initWithCapacity:[destinations count]];
   
   [destinations enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      if([obj use] || [obj password] || [obj manualEntry] || [currentNames containsObject:[obj computerName]])
         [newDestinations addObject:[obj properties]];
   }];
	[self.preferences setObject:newDestinations forKey:GrowlForwardDestinationsKey];
	[newDestinations release];
}

#pragma mark Forwarding support

- (NSArray*)sendingDetaulsForEnabledHosts {
   NSMutableArray *enabledArray = [NSMutableArray array];
   [destinations enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      if(![obj isKindOfClass:[GrowlBrowserEntry class]])
         return;
      //If we are using it, and either its a manual, and if we are browsing, we should know if its active
		if ([obj use] && ([obj manualEntry] || (![[GrowlBonjourBrowser sharedBrowser] browser] || [obj active]))) {
         [enabledArray addObject:obj];
      }
   }];
   return [self sendingDetailsForBrowserEntries:enabledArray];
}

- (NSArray*)sendingDetailsForBrowserEntryIDs:(NSArray*)entryIDs {
   NSMutableArray *entriesArray = [NSMutableArray array];
   [destinations enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      if(![obj isKindOfClass:[GrowlBrowserEntry class]])
         return;
      if([entryIDs containsObject:[obj uuid]] && ([obj manualEntry] || (![[GrowlBonjourBrowser sharedBrowser] browser] || [obj active]))){
         [entriesArray addObject:obj];
      }
   }];
   return [self sendingDetailsForBrowserEntries:entriesArray];
}

- (NSArray*)sendingDetailsForBrowserEntries:(NSArray*)hosts {
   NSMutableArray *hostResults = [NSMutableArray array];
   @autoreleasepool {
      [hosts enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
         
         if(![obj isKindOfClass:[GrowlBrowserEntry class]])
            return;
         //If we are using it, and either its a manual, and if we are browsing, we should know if its active
         if ([obj use] && ([obj manualEntry] || (![[GrowlBonjourBrowser sharedBrowser] browser] || [obj active]))) {
            //NSLog(@"Looking up address for %@", [entry computerName]);
            NSData *destAddress = nil;//[preferences boolForKey:@"AddressCachingEnabled"] ? [obj lastKnownAddress] : nil;
            if(!destAddress){
               destAddress = [GrowlNetworkUtilities addressDataForGrowlServerOfType:@"_gntp._tcp." withName:[obj computerName] withDomain:[obj domain]];
               [obj setLastKnownAddress:destAddress];
            }
            if (!destAddress) {
               /* No destination address. Nothing to see here; move along. */
               NSLog(@"Could not obtain destination address for %@", [obj computerName]);
               return;
            }
            
            NSMutableDictionary *sendingDetails = [NSMutableDictionary dictionary];
            [sendingDetails setObject:destAddress forKey:@"GNTPAddressData"];
            if([obj password])
               [sendingDetails setObject:[obj password] forKey:@"GNTPPassword"];
            [hostResults addObject:sendingDetails];
         }
      }];
   }
   return hostResults;
}

- (void)forwardDictionary:(NSDictionary*)dict isRegistration:(BOOL)registration toEntryIDs:(NSArray*)entryIDs {
   __block GNTPForwarder *blockForwarder = self;
   if(!registration){
      NSMutableArray *keys = [[dict allKeys] mutableCopy];
      [keys removeObject:GROWL_NOTIFICATION_ALREADY_SHOWN];
      dict = [dict dictionaryWithValuesForKeys:keys];
   }
   dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      NSArray *sendingDetails = nil;
      if(!entryIDs || [entryIDs count] == 0){
         sendingDetails = [self sendingDetaulsForEnabledHosts];
      }else{
         sendingDetails = [self sendingDetailsForBrowserEntryIDs:entryIDs];
      }
      [sendingDetails enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
         GrowlXPCCommunicationAttempt *attempt = nil;
         if(registration){
            attempt = [[GrowlXPCRegistrationAttempt alloc] initWithDictionary:dict];
         }else{
            attempt = [[GrowlXPCNotificationAttempt alloc] initWithDictionary:dict];
         }
         [attempt setSendingDetails:obj];
         [attempt setDelegate:blockForwarder];
         dispatch_async(dispatch_get_main_queue(), ^{
				//send note
				[[blockForwarder attemptArray] addObject:attempt];
				[attempt begin];
         });
         [attempt release];
      }];
   });
}

- (void)forwardNotification:(NSDictionary *)dict
{
   if([preferences isForwardingEnabled])
      [self forwardDictionary:dict isRegistration:NO toEntryIDs:nil];
}

- (void)appRegistered:(NSNotification*)dict 
{
   if([preferences isForwardingEnabled])
      [self forwardRegistration:[dict userInfo]];
}

- (void)forwardRegistration:(NSDictionary *)dict
{
   if([preferences isForwardingEnabled])
      [self forwardDictionary:dict isRegistration:YES toEntryIDs:nil];
}

-(void)addressChanged:(NSNotification*)note
{
   [self clearCachedAddresses];
}

#pragma mark GrowlBonjourBrowser notification methods

-(void)browserStopped:(NSNotification*)note
{
   /* Clean up any entries which we wont be saving, as well as turning the active flag off on all entries */
   NSArray *currentNames = [[self.preferences objectForKey:GrowlForwardDestinationsKey] valueForKey:@"computer"];
   __block NSMutableArray *toRemove = [NSMutableArray array];
   [destinations enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      if(![obj isKindOfClass:[GrowlBrowserEntry class]])
         return;
      if(![obj manualEntry])
         [obj setActive:NO];
      
      if(![obj use] && ![obj password] && ![currentNames containsObject:[obj computerName]])
         [toRemove addObject:obj];
   }];
   if([toRemove count] > 0){
      [self willChangeValueForKey:@"destinations"];
      [destinations removeObjectsInArray:toRemove];
      [self didChangeValueForKey:@"destinations"];
      [self writeForwardDestinations];
   }
}

-(void)serviceFound:(NSNotification*)note
{
	// check if a computer with this name has already been added
   NSNetService *aNetService = [[note userInfo] valueForKey:GNTPServiceKey];
	NSString *name = [aNetService name];
	__block GrowlBrowserEntry *entry = nil;
   [destinations enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      if(![obj isKindOfClass:[GrowlBrowserEntry class]])
         return;
		if ([[obj computerName] caseInsensitiveCompare:name] == NSOrderedSame) {
			[obj setActive:YES];
         entry = obj;
			return;
		}
   }];
   
   if(entry)
      return;
   
	// don't add the local machine    
   if([name isLocalHost])
      return;
   
	// add a new entry at the end
	entry = [[GrowlBrowserEntry alloc] initWithComputerName:name];
   [entry setDomain:[aNetService domain]];
   [entry setOwner:self];
   
   [self willChangeValueForKey:@"destinations"];
	[destinations addObject:entry];
   [self didChangeValueForKey:@"destinations"];
	[entry release];
}

-(void)serviceRemoved:(NSNotification*)note
{
   NSNetService *aNetService = [[note userInfo] valueForKey:GNTPServiceKey];
   NSArray *destinationNames = [[self.preferences objectForKey:GrowlForwardDestinationsKey] valueForKey:@"computer"];
	__block GrowlBrowserEntry *toRemove = nil;
	NSString *name = [aNetService name];
   [destinations enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      if(![obj isKindOfClass:[GrowlBrowserEntry class]])
         return;
      
		if ([[obj computerName] isEqualToString:name]) {
			[obj setActive:NO];
         
         /* If we dont need this one anymore, get rid of it */
         if(![obj use] && ![obj password] && ![destinationNames containsObject:[obj computerName]])
            toRemove = obj;
			*stop = YES;
         return;
		}
   }];
   
   if(toRemove){
      [self willChangeValueForKey:@"destinations"];
      [destinations removeObject:toRemove];
      [self didChangeValueForKey:@"destinations"];
   }
}

#pragma mark GrowlCommunicationDelegate

- (void) attemptDidSucceed:(GrowlCommunicationAttempt *)attempt {
	__block GNTPForwarder *blockForwarder = self;
	if([attempt attemptType] == GrowlCommunicationAttemptTypeRegister){
		//Not the most efficient way to do this, we could probably add in checks about whether the succesfull registration had anything to do with the queued notes
		dispatch_async(dispatch_get_main_queue(), ^{
			if([blockForwarder attemptQueue]){
				[[blockForwarder attemptQueue] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
					if([obj isKindOfClass:[NSDictionary class]])
						[blockForwarder forwardNotification:obj];
				}];
			}
			[blockForwarder setAttemptQueue:nil];
		});
	}
}
- (void) attemptDidFail:(GrowlCommunicationAttempt *)attempt {
	__block GNTPForwarder *blockForwarder = self;
	if([attempt attemptType] == GrowlCommunicationAttemptTypeRegister){
		//Not the most efficient way to do this, we could probably add in checks about whether the succesfull registration had anything to do with the queued notes
		dispatch_async(dispatch_get_main_queue(), ^{
			if([blockForwarder attemptQueue]){
				NSLog(@"Failed to register with %lu notes in the queue", [[blockForwarder attemptQueue] count]);
				[blockForwarder setAttemptQueue:nil];
			}
		});
	}
}
- (void) finishedWithAttempt:(GrowlCommunicationAttempt *)attempt {
	__block GNTPForwarder *blockForwarder = self;
	dispatch_async(dispatch_get_main_queue(), ^{
		[[blockForwarder attemptArray] removeObject:attempt];
	});
}
- (void) queueAndReregister:(GrowlCommunicationAttempt *)attempt {
	__block GNTPForwarder *blockForwarder = self;
	dispatch_async(dispatch_get_main_queue(), ^{
		NSString *appName = [[attempt dictionary] valueForKey:GROWL_APP_NAME];
		GrowlTicketDatabaseApplication *ticket = [[GrowlTicketDatabase sharedInstance] ticketForApplicationName:appName hostName:nil];
		NSDictionary *dictionary = [ticket registrationFormatDictionary];
		//We should have a dictionary, but just to be safe
		if(dictionary){
			[self forwardRegistration:dictionary];
			if(![blockForwarder attemptQueue]){
				[blockForwarder setAttemptQueue:[NSMutableArray array]];
			}
			[[blockForwarder attemptQueue] addObject:[attempt dictionary]];
			[[blockForwarder attemptArray] removeObject:attempt];
		}
	});
}

//Sent after success
- (void) notificationClicked:(GrowlCommunicationAttempt *)attempt context:(id)context {
	//Send click
}
- (void) notificationTimedOut:(GrowlCommunicationAttempt *)attempt context:(id)context {
	//Send timeout
}
- (void) notificationClosed:(GrowlCommunicationAttempt *)attempt context:(id)context {
   //send closed
}

@end
