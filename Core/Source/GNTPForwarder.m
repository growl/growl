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
#import "GrowlKeychainUtilities.h"
#import "GrowlPreferencesController.h"
#import "GrowlGNTPOutgoingPacket.h"
#import "GrowlNetworkUtilities.h"

@implementation GNTPForwarder

@synthesize preferences;
@synthesize destinations;
@synthesize browser;

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
      self.preferences = [GrowlPreferencesController sharedController];
      
      // create a deep mutable copy of the forward destinations
      NSArray *dests = [self.preferences objectForKey:GrowlForwardDestinationsKey];
      NSMutableArray *theServices = [NSMutableArray array];
      for(NSDictionary *destination in dests) {
         GrowlBrowserEntry *entry = [[GrowlBrowserEntry alloc] initWithDictionary:destination];
         [entry setOwner:self];
         [theServices addObject:entry];
         [entry release];
      }
      [self setDestinations:theServices];
      
      [[NSNotificationCenter defaultCenter] addObserver:self
                                               selector:@selector(appRegistered:)
                                                   name:@"ApplicationRegistered"
                                                 object:nil];
   }
   return self;
}

- (void)dealloc {
   [[NSNotificationCenter defaultCenter] removeObserver:self];
   [destinations release];
   [browser release];
   [super dealloc];
}

#pragma mark UI Support

-(void)startBrowsing
{
   if(!browser){
      browser = [[NSNetServiceBrowser alloc] init];
      [browser setDelegate:self];
      [browser searchForServicesOfType:@"_gntp._tcp." inDomain:@""];
   }
}

-(void)stopBrowsing
{
   if(browser){
      [browser stop];
      //Will release in stoppedBrowsing delegate
   }
}

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
   
	for(GrowlBrowserEntry *entry in destinations) {
		if ([entry use]) {
			//NSLog(@"Looking up address for %@", [entry computerName]);
			NSData *destAddress = [GrowlNetworkUtilities addressDataForGrowlServerOfType:@"_gntp._tcp." withName:[entry computerName] withDomain:[entry domain]];
			if (!destAddress) {
				/* No destination address. Nothing to see here; move along. */
				NSLog(@"Could not obtain destination address for %@", [entry computerName]);
				continue;
			}
			[packet setKey:[entry key]];
         __block GNTPForwarder *blockForwarder = self;
         dispatch_async(dispatch_get_main_queue(), ^{
            [blockForwarder mainThread_sendViaTCP:[NSDictionary dictionaryWithObjectsAndKeys:
                                                   destAddress, @"Destination",
                                                   packet, @"Packet",
                                                   nil]];
         });
		} else {
			//NSLog(@"6  destination %@", entry);
		}
	}
   
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

#pragma mark NSNetServiceBrowser Delegate Methods

- (void)netServiceBrowserDidStopSearch:(NSNetServiceBrowser *)netServiceBrowser
{
   //We switched away from the network pane, remove any unused services which are not already in the file
   NSArray *destinationNames = [[self.preferences objectForKey:GrowlForwardDestinationsKey] valueForKey:@"computer"];
   NSMutableArray *toRemove = [NSMutableArray array];
   [destinations enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      if(![obj use] && ![obj password] && ![obj manualEntry] && ![destinationNames containsObject:[obj computerName]])
         [toRemove addObject:obj];
   }];
   [self willChangeValueForKey:@"destinations"];
   [destinations removeObjectsInArray:toRemove];
   [self didChangeValueForKey:@"destinations"];
   
   /* Now we can get rid of the browser, otherwise we don't get this delegate call, 
    * and possibly, something behind the scenes might not like releasing earlier*/
   self.browser = nil;
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing {
	// check if a computer with this name has already been added
	NSString *name = [aNetService name];
	GrowlBrowserEntry *entry = nil;
	for (entry in destinations) {
		if ([[entry computerName] caseInsensitiveCompare:name] == NSOrderedSame) {
			[entry setActive:YES];
			return;
		}
	}
   
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
   
	if (!moreComing)
		[self writeForwardDestinations];
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didRemoveService:(NSNetService *)aNetService moreComing:(BOOL)moreComing 
{
   NSArray *destinationNames = [[self.preferences objectForKey:GrowlForwardDestinationsKey] valueForKey:@"computer"];
	GrowlBrowserEntry *toRemove = nil;
	NSString *name = [aNetService name];
	for (GrowlBrowserEntry *currentEntry in destinations) {
		if ([[currentEntry computerName] isEqualToString:name]) {
			[currentEntry setActive:NO];
         
         /* If we dont need this one anymore, get rid of it */
         if(!currentEntry.use && !currentEntry.password && ![destinationNames containsObject:currentEntry.computerName])
            toRemove = currentEntry;
			break;
		}
	}
   
   if(toRemove){
      [self willChangeValueForKey:@"destinations"];
      [destinations removeObject:toRemove];
      [self didChangeValueForKey:@"destinations"];
   }
   
	if (!moreComing)
		[self writeForwardDestinations];
}


@end
