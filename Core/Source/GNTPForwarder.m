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

#include <netinet/in.h>
#include <arpa/inet.h>

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
      self.destinations = [NSMutableArray array];
      
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
   }
   return self;
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
   [destinations addObject:newEntry];
}

- (void)removeEntryAtIndex:(NSUInteger)index {
   if(index >= [destinations count])
      return;
   
   GrowlBrowserEntry *toRemove = [destinations objectAtIndex:index];;
   [destinations removeObjectAtIndex:index];
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
- (NSData *)addressDataForGrowlServerOfType:(NSString *)type withName:(NSString *)name withDomain:(NSString*)domain
{
	if ([name hasSuffix:@".local"])
		name = [name substringWithRange:NSMakeRange(0, [name length] - [@".local" length])];
   
	if ([name Growl_isLikelyDomainName]) {
		CFHostRef host = CFHostCreateWithName(kCFAllocatorDefault, (CFStringRef)name);
		CFStreamError error;
		if (CFHostStartInfoResolution(host, kCFHostAddresses, &error)) {
			NSArray *addresses = (NSArray *)CFHostGetAddressing(host, NULL);
			
			if ([addresses count]) {
				/* DNS lookup success! */
            CFRelease(host);
				return [addresses objectAtIndex:0];
			}
		}
		if (host) CFRelease(host);
		
	} else if ([name Growl_isLikelyIPAddress]) {
      struct in_addr addr4;
      struct in6_addr addr6;
      
      if(inet_pton(AF_INET, [name cStringUsingEncoding:NSUTF8StringEncoding], &addr4) == 1){
         struct sockaddr_in serverAddr;
         
         memset(&serverAddr, 0, sizeof(serverAddr));
         serverAddr.sin_len = sizeof(struct sockaddr_in);
         serverAddr.sin_family = AF_INET;
         serverAddr.sin_addr.s_addr = addr4.s_addr;
         serverAddr.sin_port = htons(GROWL_TCP_PORT);
         return [NSData dataWithBytes:&serverAddr length:sizeof(serverAddr)];
      }
      else if(inet_pton(AF_INET6, [name cStringUsingEncoding:NSUTF8StringEncoding], &addr6) == 1){
         struct sockaddr_in6 serverAddr;
         
         memset(&serverAddr, 0, sizeof(serverAddr));
         serverAddr.sin6_len        = sizeof(struct sockaddr_in6);
         serverAddr.sin6_family     = AF_INET6;
         serverAddr.sin6_addr       = addr6;
         serverAddr.sin6_port       = htons(GROWL_TCP_PORT);
         return [NSData dataWithBytes:&serverAddr length:sizeof(serverAddr)];
      }else{
         NSLog(@"No address (shouldnt happen)");
         return nil;
      }
   } 
	
   NSString *machineDomain = domain;
   if(!machineDomain)
      machineDomain = @"local.";
	/* If we make it here, treat it as a computer name on the local network */ 
	NSNetService *service = [[[NSNetService alloc] initWithDomain:machineDomain type:type name:name] autorelease];
	if (!service) {
		/* No such service exists. The computer is probably offline. */
		return nil;
	}
	
	/* Work for 8 seconds to resolve the net service to an IP and port. We should be running
	 * on a background concurrent queue, so blocking is fine.
	 */
	[service scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:@"PrivateGrowlMode"];
	[service resolveWithTimeout:8.0];
	CFAbsoluteTime deadline = CFAbsoluteTimeGetCurrent() + 8.0;
	CFTimeInterval remaining;
	while ((remaining = (deadline - CFAbsoluteTimeGetCurrent())) > 0 && [[service addresses] count] == 0) {
		CFRunLoopRunInMode((CFStringRef)@"PrivateGrowlMode", remaining, true);
      NSLog(@"testing");
	}
	[service stop];
	
	NSArray *addresses = [service addresses];
	if (![addresses count]) {
		/* Lookup failed */
		return nil;
	}
	
	return [addresses objectAtIndex:0];
}

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
			NSData *destAddress = [self addressDataForGrowlServerOfType:@"_gntp._tcp." withName:[entry computerName] withDomain:[entry domain]];
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
   [destinations removeObjectsInArray:toRemove];
   
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
   
	[destinations addObject:entry];
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
      [destinations removeObject:toRemove];
   }
   
	if (!moreComing)
		[self writeForwardDestinations];
}


@end
