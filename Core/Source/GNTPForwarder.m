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
#import "GrowlGNTPOutgoingPacket.h"
#import "GrowlNetworkUtilities.h"
#import "GrowlBonjourBrowser.h"
#import "GrowlNetworkObserver.h"
#import "GrowlGNTPPacketParser.h"
#import <GrowlPlugins/GrowlKeychainUtilities.h>

@implementation GNTPForwarder

@synthesize preferences;
@synthesize destinations;
@synthesize alreadyBrowsing;

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
   [self willChangeValueForKey:@"destinations"];
   [destinations removeObjectAtIndex:index];
   [self didChangeValueForKey:@"destinations"];
   [self writeForwardDestinations];
   
   if(![toRemove password])
      return;
   
   if(![GrowlKeychainUtilities removePasswordForService:GrowlOutgoingNetworkPassword accountName:[toRemove uuid]])
      NSLog(@"Error removing password from keychain for %@", [toRemove computerName]);
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

/*!
 * @brief Get address data for a Growl server
 *
 * @param name The name of the server
 * @result An NSData which contains a (struct sockaddr *)'s data. This may actually be a sockaddr_in or a sockaddr_in6.
 */

- (void)mainThread_sendViaTCP:(NSDictionary *)sendingDetails
{
	[[GrowlGNTPPacketParser sharedParser] sendPacket:[sendingDetails objectForKey:@"Packet"]
                                          toAddress:[sendingDetails objectForKey:@"Destination"]];
}

- (void)sendViaTCP:(GrowlGNTPOutgoingPacket *)packet
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
   
   if(![[GrowlPreferencesController sharedController] isForwardingEnabled])
      return;
   
   __block GNTPForwarder *blockForwarder = self;
   [destinations enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      if(![obj isKindOfClass:[GrowlBrowserEntry class]])
         return;
      //If we are using it, and either its a manual, and if we are browsing, we should know if its active
		if ([obj use] && ([obj manualEntry] || (![[GrowlBonjourBrowser sharedBrowser] browser] || [obj active]))) {
			//NSLog(@"Looking up address for %@", [entry computerName]);
			NSData *destAddress = [preferences boolForKey:@"AddressCachingEnabled"] ? [obj lastKnownAddress] : nil;
         if(!destAddress){
            destAddress = [GrowlNetworkUtilities addressDataForGrowlServerOfType:@"_gntp._tcp." withName:[obj computerName] withDomain:[obj domain]];
            [obj setLastKnownAddress:destAddress];
         }
			if (!destAddress) {
				/* No destination address. Nothing to see here; move along. */
				NSLog(@"Could not obtain destination address for %@", [obj computerName]);
				return;
			}
			[packet setKey:[(GrowlBrowserEntry*)obj key]];
         dispatch_async(dispatch_get_main_queue(), ^{
            [blockForwarder mainThread_sendViaTCP:[NSDictionary dictionaryWithObjectsAndKeys:
                                                   destAddress, @"Destination",
                                                   packet, @"Packet",
                                                   nil]];
         });
		}       
   }];
   
	[pool release];	
}

- (void)forwardNotification:(NSDictionary *)dict
{
	GrowlGNTPOutgoingPacket *outgoingPacket = [GrowlGNTPOutgoingPacket outgoingPacketOfType:GrowlGNTPOutgoingPacket_NotifyType
                                                                                   forDict:dict];
   __block GNTPForwarder *blockForwarder = self;
   dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      [blockForwarder sendViaTCP:outgoingPacket];
   });
}

- (void)appRegistered:(NSNotification*)dict 
{
   if([preferences isForwardingEnabled])
      [self forwardRegistration:[dict userInfo]];
}

- (void)forwardRegistration:(NSDictionary *)dict
{
	GrowlGNTPOutgoingPacket *outgoingPacket = [GrowlGNTPOutgoingPacket outgoingPacketOfType:GrowlGNTPOutgoingPacket_RegisterType
                                                                                   forDict:dict];
   __block GNTPForwarder *blockForwarder = self;
   dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      [blockForwarder sendViaTCP:outgoingPacket];
   });
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


@end
