//
//  GrowlServerViewController.m
//  Growl
//
//  Created by Daniel Siemer on 11/10/11.
//  Copyright (c) 2011 The Growl Project. All rights reserved.
//

#import "GrowlServerViewController.h"
#import "ACImageAndTextCell.h"
#import "GrowlPreferencesController.h"
#import "GrowlBrowserEntry.h"
#include "NSStringAdditions.h"

#import <SystemConfiguration/SystemConfiguration.h>
#include <ifaddrs.h>
#include <arpa/inet.h>


/** A reference to the SystemConfiguration dynamic store. */
static SCDynamicStoreRef dynStore;

/** Our run loop source for notification. */
static CFRunLoopSourceRef rlSrc;

static void scCallback(SCDynamicStoreRef store, CFArrayRef changedKeys, void *info);

@implementation GrowlServerViewController

@synthesize services;
@synthesize browser;
@synthesize serviceNameColumn;
@synthesize servicePasswordColumn;
@synthesize networkTableView;

@synthesize currentServiceIndex;

@synthesize networkAddressString;

- (void)dealloc {
   [[NSNotificationCenter defaultCenter] removeObserver:self];
   if (rlSrc)
		CFRunLoopRemoveSource(CFRunLoopGetCurrent(), rlSrc, kCFRunLoopDefaultMode);
   if (dynStore)
		CFRelease(dynStore);
	[services release];
   [browser release];
   [networkAddressString release];
   [super dealloc];
}

- (void) awakeFromNib {
   ACImageAndTextCell *imageTextCell = [[[ACImageAndTextCell alloc] init] autorelease];

   NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
   [nc addObserver:self selector:@selector(reloadPrefs:)     name:GrowlPreferencesChanged object:nil];
   
	// create a deep mutable copy of the forward destinations
	NSArray *destinations = [self.preferencesController objectForKey:GrowlForwardDestinationsKey];
	NSMutableArray *theServices = [NSMutableArray array];
	for(NSDictionary *destination in destinations) {
		GrowlBrowserEntry *entry = [[GrowlBrowserEntry alloc] initWithDictionary:destination];
		[entry setOwner:self];
		[theServices addObject:entry];
		[entry release];
	}
	[self setServices:theServices];
    
   self.networkAddressString = nil;
   
   SCDynamicStoreContext context = {0, self, NULL, NULL, NULL};
   
	dynStore = SCDynamicStoreCreate(kCFAllocatorDefault,
                                   CFBundleGetIdentifier(CFBundleGetMainBundle()),
                                   scCallback,
                                   &context);
	if (!dynStore) {
		NSLog(@"SCDynamicStoreCreate() failed: %s", SCErrorString(SCError()));
	}
   
   const CFStringRef keys[1] = {
		CFSTR("State:/Network/Interface/*"),
	};
	CFArrayRef watchedKeys = CFArrayCreate(kCFAllocatorDefault,
                                          (const void **)keys,
                                          1,
                                          &kCFTypeArrayCallBacks);
	if (!SCDynamicStoreSetNotificationKeys(dynStore,
                                          NULL,
                                          watchedKeys)) {
		NSLog(@"SCDynamicStoreSetNotificationKeys() failed: %s", SCErrorString(SCError()));
		CFRelease(dynStore);
		dynStore = NULL;
	}
	CFRelease(watchedKeys);
   
   rlSrc = SCDynamicStoreCreateRunLoopSource(kCFAllocatorDefault, dynStore, 0);
	CFRunLoopAddSource(CFRunLoopGetCurrent(), rlSrc, kCFRunLoopDefaultMode);
   CFRelease(rlSrc);

   [serviceNameColumn setDataCell:imageTextCell];
	[networkTableView reloadData];
}

- (void)viewWillLoad
{
   [self startBrowsing];
   [self updateAddresses];
}

- (void)viewDidUnload
{
   [self stopBrowsing];
}

- (void) reloadPrefs:(NSNotification *)notification {
	// ignore notifications which are sent by ourselves
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
   
   id object = [notification object];
   if(!object || [object isEqualToString:GrowlStartServerKey])
      [self updateAddresses];
   
	[pool release];
}

- (IBAction) removeSelectedForwardDestination:(id)sender
{
   GrowlBrowserEntry *toRemove = [services objectAtIndex:[networkTableView selectedRow]];
   [networkTableView noteNumberOfRowsChanged];
   [self willChangeValueForKey:@"services"];
   [services removeObjectAtIndex:[networkTableView selectedRow]];
   [self didChangeValueForKey:@"services"];
   [self writeForwardDestinations];
   
   if(![toRemove password])
      return;

   OSStatus status;
	SecKeychainItemRef itemRef = nil;
	const char *uuidChars = [[toRemove uuid] UTF8String];
	status = SecKeychainFindGenericPassword(NULL,
                                           (UInt32)strlen("GrowlOutgoingNetworkConnection"), "GrowlOutgoingNetworkConnection",
                                           (UInt32)strlen(uuidChars), uuidChars,
                                           NULL, NULL, &itemRef);
   if (status == errSecItemNotFound) {
      // Do nothing, we cant find it
	} else {
		status = SecKeychainItemDelete(itemRef);
      if(status != errSecSuccess)
         NSLog(@"Error deleting the password for %@: %@", [toRemove computerName], [(NSString*)SecCopyErrorMessageString(status, NULL) autorelease]);
      if(itemRef)
         CFRelease(itemRef);
    }
}

- (IBAction)newManualForwader:(id)sender {
    GrowlBrowserEntry *newEntry = [[[GrowlBrowserEntry alloc] initWithComputerName:@""] autorelease];
    [newEntry setManualEntry:YES];
    [newEntry setOwner:self];
    [networkTableView noteNumberOfRowsChanged];
    [self willChangeValueForKey:@"services"];
    [services addObject:newEntry];
    [self didChangeValueForKey:@"services"];
}

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

-(void)updateAddresses
{
   if(![self.preferencesController isGrowlServerEnabled]){
      self.networkAddressString = nil;
      return;
   }
   NSMutableString *newString = nil;
   struct ifaddrs *interfaces = NULL;
   struct ifaddrs *current = NULL;
   
   if(getifaddrs(&interfaces) == 0)
   {
      current = interfaces;
      while (current != NULL) {
         NSString *currentString = nil;
         
         NSString *interface = [NSString stringWithUTF8String:current->ifa_name];
         
         if(![interface isEqualToString:@"lo0"] && ![interface isEqualToString:@"utun0"])
         {
            if (current->ifa_addr->sa_family == AF_INET) {
               char stringBuffer[INET_ADDRSTRLEN];
               struct sockaddr_in *ipv4 = (struct sockaddr_in *)current->ifa_addr;
               if (inet_ntop(AF_INET, &(ipv4->sin_addr), stringBuffer, INET_ADDRSTRLEN))
                  currentString = [NSString stringWithFormat:@"%s", stringBuffer];
            } else if (current->ifa_addr->sa_family == AF_INET6) {
               char stringBuffer[INET6_ADDRSTRLEN];
               struct sockaddr_in6 *ipv6 = (struct sockaddr_in6 *)current->ifa_addr;
               if (inet_ntop(AF_INET6, &(ipv6->sin6_addr), stringBuffer, INET6_ADDRSTRLEN))
                  currentString = [NSString stringWithFormat:@"%s", stringBuffer];
            }          
            
            if(currentString && ![currentString isLocalHost]){
               if(!newString)
                  newString = [[currentString mutableCopy] autorelease];
               else
                  [newString appendFormat:@"\n%@", currentString];
            }
         }
         
         current = current->ifa_next;
      }
   }
   if(newString){
      self.networkAddressString = newString;
      NSLog(@"new addresses %@", newString);
   }
   else
      self.networkAddressString = nil;
   
   freeifaddrs(interfaces);
}

static void scCallback(SCDynamicStoreRef store, CFArrayRef changedKeys, void *info) {
	GrowlPreferencePane *prefPane = info;
	CFIndex count = CFArrayGetCount(changedKeys);
	for (CFIndex i=0; i<count; ++i) {
		CFStringRef key = CFArrayGetValueAtIndex(changedKeys, i);
      if (CFStringCompare(key, CFSTR("State:/Network/Interface"), 0) == kCFCompareEqualTo) {
			[prefPane updateAddresses];
		}
	}
}

- (void) writeForwardDestinations {
   NSArray *currentNames = [[self.preferencesController objectForKey:GrowlForwardDestinationsKey] valueForKey:@"computer"];
	NSMutableArray *destinations = [[NSMutableArray alloc] initWithCapacity:[services count]];
   
   [services enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      if([obj use] || [obj password] || [obj manualEntry] || [currentNames containsObject:[obj computerName]])
         [destinations addObject:[obj properties]];
   }];
	[self.preferencesController setObject:destinations forKey:GrowlForwardDestinationsKey];
	[destinations release];
}

#pragma mark NSNetServiceBrowser Delegate Methods

- (void)netServiceBrowserDidStopSearch:(NSNetServiceBrowser *)netServiceBrowser
{
   //We switched away from the network pane, remove any unused services which are not already in the file
   NSArray *destinationNames = [[self.preferencesController objectForKey:GrowlForwardDestinationsKey] valueForKey:@"computer"];
   NSMutableArray *toRemove = [NSMutableArray array];
   [services enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      if(![obj use] && ![obj password] && ![obj manualEntry] && ![destinationNames containsObject:[obj computerName]])
         [toRemove addObject:obj];
   }];
   [self willChangeValueForKey:@"services"];
   [services removeObjectsInArray:toRemove];
   [self didChangeValueForKey:@"services"];
   
   /* Now we can get rid of the browser, otherwise we don't get this delegate call, 
    * and possibly, something behind the scenes might not like releasing earlier*/
   self.browser = nil;
}

- (void) netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing {
	// check if a computer with this name has already been added
	NSString *name = [aNetService name];
	GrowlBrowserEntry *entry = nil;
	for (entry in services) {
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
   
	[self willChangeValueForKey:@"services"];
	[services addObject:entry];
	[self didChangeValueForKey:@"services"];
	[entry release];
   
	if (!moreComing)
		[self writeForwardDestinations];
}

- (void) netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didRemoveService:(NSNetService *)aNetService moreComing:(BOOL)moreComing 
{
   NSArray *destinationNames = [[self.preferencesController objectForKey:GrowlForwardDestinationsKey] valueForKey:@"computer"];
	GrowlBrowserEntry *toRemove = nil;
	NSString *name = [aNetService name];
	for (GrowlBrowserEntry *currentEntry in services) {
		if ([[currentEntry computerName] isEqualToString:name]) {
			[currentEntry setActive:NO];
         [networkTableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:[services indexOfObject:currentEntry]] 
                                     columnIndexes:[NSIndexSet indexSetWithIndex:1]];
         
         /* If we dont need this one anymore, get rid of it */
         if(!currentEntry.use && !currentEntry.password && ![destinationNames containsObject:currentEntry.computerName])
            toRemove = currentEntry;
			break;
		}
	}
   
   if(toRemove){
      [self willChangeValueForKey:@"services"];
      [services removeObject:toRemove];
      [self didChangeValueForKey:@"services"];
   }
   
	if (!moreComing)
		[self writeForwardDestinations];
}

#pragma mark TableView data source methods

- (NSInteger) numberOfRowsInTableView:(NSTableView*)tableView {
	if(tableView == networkTableView) {
		return [[self services] count];
	}
	return 0;
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
	if(aTableColumn == servicePasswordColumn) {
		[[services objectAtIndex:rowIndex] setPassword:anObject];
	}
}

- (id) tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
	// we check to make sure we have the image + text column and then set its image manually
   if (aTableColumn == servicePasswordColumn) {
		return [[services objectAtIndex:rowIndex] password];
	} else if (aTableColumn == serviceNameColumn) {
        NSCell *cell = [aTableColumn dataCellForRow:rowIndex];
        static NSImage *manualImage = nil;
        static NSImage *bonjourImage = nil;
        if(!manualImage){
            manualImage = [[NSImage imageNamed:NSImageNameNetwork] retain];
            bonjourImage = [[NSImage imageNamed:NSImageNameBonjour] retain];
            NSSize imageSize = NSMakeSize([cell cellSize].height, [cell cellSize].height);
            [manualImage setSize:imageSize];
            [bonjourImage setSize:imageSize];
        }
        GrowlBrowserEntry *entry = [services objectAtIndex:rowIndex];
        if([entry manualEntry])
            [cell setImage:manualImage];
        else
            [cell setImage:bonjourImage];
    }

	return nil;
}

@end
