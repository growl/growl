//
//  JKMenuController.m
//  Rawr-endezvous
//
//  Created by Jeremy Knope on 9/17/04.
//  Copyright 2004 Jeremy Knope. All rights reserved.
//

#import "JKMenuController.h"
#import "JKPreferencesController.h"
#import "JKServiceManager.h"
#import <Growl/Growl.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <unistd.h>

@implementation JKMenuController
- (void) awakeFromNib {
	menuServices = [[NSMutableDictionary alloc] initWithCapacity:1U];
	[prefs openPrefs];
	if (DEBUG)
		NSLog(@"Registering growl");
	[GrowlApplicationBridge setGrowlDelegate:self];
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(foundService:) name:@"RawrEndezvousNewService" object:nil];
	[nc addObserver:self selector:@selector(serviceWentOffline:) name:@"RawrEndezvousRemoveService" object:nil];
	if (DEBUG)
		NSLog(@"Starting up service manager");
	//serviceManager = [JKServiceManager serviceManagerForProtocols:[prefs getServices]];
	serviceManager = [[JKServiceManager serviceManagerForPreferences:prefs] retain];

	// Status item code
	if ([prefs getShowStatusMenuItem]) {
		statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength] retain];
		[statusItem setHighlightMode:YES];
		//[statusItem setTitle:@"R"];
		[statusItem setMenu:dockMenu];
		[statusItem setEnabled:YES];
		[statusItem setImage:[NSImage imageNamed:@"statusItemIcon"]];
	}
}

- (NSString *) applicationNameForGrowl {
	return @"Rawr-endezvous";
}

- (NSData *) applicationIconDataForGrowl {
	return [[NSImage imageNamed:@"rendezvous"] TIFFRepresentation];
}

- (NSDictionary *) registrationDictionaryForGrowl {
	NSArray *allNotes = [[NSArray alloc] initWithObjects:
		@"New Service Discovered",
		@"Service offline",
		nil];

	NSDictionary *regDict = [NSDictionary dictionaryWithObjectsAndKeys:
		allNotes, GROWL_NOTIFICATIONS_ALL,
		allNotes, GROWL_NOTIFICATIONS_DEFAULT,
		nil
	];

	[allNotes release];

	return regDict;
}

- (void) addMenuItemForService:(NSNetService *)newService {
	NSMenu *servicesMenu;
	NSMenuItem *newItem;
	NSMenu *proMenu;
	NSMenuItem *proItem;
	NSString *protocolName;
	//NSLog(@"main::addService: Checking for %@ got: %@",[newService type],[protocolNames objectForKey:[newService type]]);
	protocolName = [[[serviceManager getProtocolNames] objectForKey:[newService type]] objectForKey:@"name"];
	if ([[menuServices objectForKey:protocolName] containsObject:newService]) {
		//NSLog(@"Service already exists: %@ %@, not adding to menu of services",[newService type], [newService name]);
		return;
	}
	servicesMenu = dockMenu;
	//NSLog(@"Checking for protocol menu %@",protocolName);
	proItem = (NSMenuItem *)[servicesMenu itemWithTitle:protocolName];
	//NSLog(@"Found: %@",[proItem title]);
	//NSString *aKey = [[protocolNames objectForKey:[newService type]] objectForKey:@"protocol"];
	if (!proItem) {
		//NSLog(@"Creating new protocol menu item");
		proItem = [[NSMenuItem alloc] init];
		[proItem setTitle:protocolName];
		proMenu = [[NSMenu alloc] init];
		[proMenu setTitle:protocolName];
		[proItem setSubmenu:proMenu];
		[servicesMenu insertItem:proItem atIndex:[servicesMenu numberOfItems]];
		//NSLog(@"Adding new array to menuServices for %@",protocolName);

		[menuServices setObject:[NSMutableArray arrayWithObjects:newService,nil] forKey:protocolName];
	} else {
		proMenu = [proItem submenu];
		//NSLog(@"Adding new object to array of services for key: %@ at %i",[newService type],[[menuServices objectForKey:aKey] count]);
		//[[menuServices objectForKey:protocolName] addObject:newService]; // add new object to array of services
	}
	// setting up new Menu Item, set name to service name
	newItem = [[NSMenuItem alloc] init];
	[newItem setTitle:[newService name]];

	int j=0; // counter to go thru protocol menu
	int newIndex = -1; // for inserting item

	for (j=0;j<[proMenu numberOfItems];j++) {
		if (DEBUG)
			NSLog(@"Comparing %@ < %@ or == ",[[proMenu itemAtIndex:j] title],[newItem title]);
		if ([[[proMenu itemAtIndex:j] title] caseInsensitiveCompare:[newItem title]] == NSOrderedAscending || [[[proMenu itemAtIndex:j] title] caseInsensitiveCompare:[newItem title]] == NSOrderedSame) {
			newIndex = j+1;
			if (DEBUG)
				NSLog(@"Found first item less than second, setting: %i",newIndex);
		}
	}
	if (newIndex == -1)
		newIndex = 0;
	[proMenu insertItem:newItem atIndex:newIndex];
	// add service to dict of services
	if (![[menuServices objectForKey:protocolName] containsObject:newService])
		[[menuServices objectForKey:protocolName] insertObject:newService atIndex:newIndex];
	//else
	//	NSLog(@"Service already exists: %@ %@, not adding to list of services",[newService type],[newService name]);
	[newItem setTarget:self];
	[newItem setAction:@selector(itemClicked:)];
}

- (void) removeMenuItemForService:(NSNetService *)oldService { // needs old services to find the name...
	NSString *protocol;
	NSMenuItem *anItem;
	NSArray *items;
	NSString *aKey;

	if (oldService) {
		NSLog(@"Old service: %@", oldService);
	} else {
		NSLog(@"**WARNING** we don't have an old service, shouldn't happen");
		return;
	}
	aKey = nil;
	//NSString *aKey = [[[serviceManager getProtocolNames] objectForKey:[oldService type]] objectForKey:@"name"];
	// loop thru each old services comparing type with oldService type
	NSEnumerator *oldServiceEnum = [[prefs getOldServices] objectEnumerator];
	NSDictionary *entry;
	while ((entry = [oldServiceEnum nextObject])) {
		if ([[oldService type] isEqualToString:[entry objectForKey:@"service"]]) {
			aKey = [entry objectForKey:@"name"];
			break;
		}
	}
	if (!aKey) {
		NSLog(@"FAILED to get a key for old service removal");
		return;
	}
	protocol = [oldService type];
	//NSMenu *servicesMenu = dockMenu;
	if (aKey && [aKey isKindOfClass:[NSString class]]) {
		NSMenuItem *proItem = [dockMenu itemWithTitle:aKey];
		NSMenu *proMenu = [[dockMenu itemWithTitle:aKey] submenu];
		//proMenu = [proMenu submenu];
		items = [proMenu itemArray];
		int i = 0;
		NSEnumerator * myEnum = [items objectEnumerator];
		while ((anItem = [myEnum nextObject])) {
			//NSLog(@"Searching... looking for %@",[oldService name]);
			if ([[anItem title] isEqualToString:[oldService name]]) {
				//NSLog(@"We gotta remove %@",[anItem title]);
				[proMenu removeItem:anItem];
				[[menuServices objectForKey:aKey] removeObjectAtIndex:i];
				//NSLog(@"Menu item removed");
			}
			i++;
		}
		if (![[proMenu itemArray] count])
			[dockMenu removeItem:proItem];
	}
}

- (void) itemClicked:(id)sender {
	//NSLog(@"Clicked on: %@",[sender title]);
	NSMenu *proMenu = [sender menu];
	int idx = [proMenu indexOfItem:sender];
	//NSLog(@"Clicked at index: %i",idx);
	//NSLog(@"Requesting array for %@ and index in array: %i",[proMenu title],idx);
	serviceBeingResolved = [[menuServices objectForKey:[proMenu title]] objectAtIndex:idx];
	//NSLog(@"Resolving %@ for %@",[serviceBeingResolved name],[serviceBeingResolved type]);
	[serviceBeingResolved retain];
	[serviceBeingResolved setDelegate:self];
	[serviceBeingResolved resolve];
	//NSLog(@"Should be resolving now");
}

- (IBAction) refreshServices:(id)sender {
#pragma unused(sender)
	//NSMenuItem *anItem;
	//NSArray *items;
	if (![prefs getShowStatusMenuItem]) {
		[[NSStatusBar systemStatusBar] removeStatusItem:statusItem];
		if (statusItem)
			[statusItem release];
		statusItem = nil;
	} else if (!statusItem) {
		statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength] retain];
		[statusItem setHighlightMode:YES];
		//[statusItem setTitle:@"R"];
		[statusItem setMenu:dockMenu];
		[statusItem setEnabled:YES];
		[statusItem setImage:[NSImage imageNamed:@"statusItemIcon"]];
	}
	if (DEBUG)
		NSLog(@"JKMenuController:: Refreshing services");
	//[browsers removeAllObjects];
	/*
	items = [dockMenu itemArray];
	NSEnumerator *anEnum = [items objectEnumerator];
	while ((anItem = [anEnum nextObject])) {
		//NSLog(@"Removing: %@",[anItem title]);
		[dockMenu removeItem:anItem];
	}
	NSLog(@"Telling service manager to refresh");
	*/
	//[serviceManager setProtocols:[prefs getOldServices]];
	[serviceManager refreshServices];
}

- (void) foundService:(NSNotification *)noti {
	NSNetService *aNetService = [noti object];
	//NSLog(@"Notifying growl of new service: %@",[aNetService name]);
	[self addMenuItemForService:aNetService];
	NSString *description = [[NSString alloc] initWithFormat:@"%@\n%@",
		[aNetService name],
		[aNetService type]];
	[GrowlApplicationBridge notifyWithTitle:@"Found Service"
		description:description
		notificationName:@"New Service Discovered"
		iconData:nil
		priority:0
		isSticky:NO
		clickContext:nil];
	[description release];
}

- (void) serviceWentOffline:(NSNotification *)noti {
	NSNetService *aNetService = [noti object];
	//NSLog(@"Notifying growl of disconnected service: %@",[aNetService name]);
	[self removeMenuItemForService:aNetService];
	NSString *description = [[NSString alloc] initWithFormat:@"%@\n%@",
		[aNetService name],
		[aNetService type]];
	[GrowlApplicationBridge notifyWithTitle:@"Service went offline"
		description:description
		notificationName:@"Service offline"
		iconData:nil
		priority:0
		isSticky:NO
		clickContext:nil];
	[description release];
}

- (void) netServiceDidResolveAddress:(NSNetService *)sender {
	//NSLog(@"Did resolve!");
	if ([[sender addresses] count]) {
		NSData * address;
		struct sockaddr * socketAddress = NULL;
		NSString * ipAddressString = nil;
		NSString * portString = nil;
		//int socketToRemoteServer;
		char buffer[256];

		// Iterate through addresses until we find an IPv4 address
		for (unsigned idx = 0; idx < [[sender addresses] count]; ++idx) {
			address = [[sender addresses] objectAtIndex:idx];
			socketAddress = (struct sockaddr *)[address bytes];

			if (socketAddress->sa_len == sizeof(struct sockaddr_in))
				break;
		}

		if (socketAddress) {
			switch(socketAddress->sa_len) {
				case sizeof(struct sockaddr_in):
					if (inet_ntop(AF_INET, &((struct sockaddr_in *)socketAddress)->sin_addr, buffer, sizeof(buffer)))
						ipAddressString = [NSString stringWithCString:buffer];
					portString = [NSString stringWithFormat:@"%d", ntohs(((struct sockaddr_in *)socketAddress)->sin_port)];

					// Cancel the resolve now that we have an IPv4 address.
					[sender stop];
					[sender release];
					serviceBeingResolved = nil;

					break;
				case sizeof(struct sockaddr_in6):
					// PictureSharing server doesn't support IPv6
					return;
			}
		}

		if (ipAddressString && portString) {
			NSString *urlString;
			urlString = [NSString stringWithFormat:@"%@://%@:%@",[[[serviceManager getProtocolNames] objectForKey:[sender type]] objectForKey:@"protocol"],ipAddressString,portString];
			//NSLog(@"Opening: %@",urlString);
			NSURL *myURL = [NSURL URLWithString:urlString];
			[[NSWorkspace sharedWorkspace] openURL:myURL];
		}
			//[ipAddressField setStringValue:ipAddressString];

		//if (portString)
			//NSLog(@"  and port: %@",portString);
			//[portField setStringValue:portString];
/*
		socketToRemoteServer = socket(AF_INET, SOCK_STREAM, 0);
		if (socketToRemoteServer > 0) {
			NSFileHandle * remoteConnection = [[NSFileHandle alloc] initWithFileDescriptor:socketToRemoteServer closeOnDealloc:YES];
			if (remoteConnection) {
				//[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(readAllTheData:) name:NSFileHandleReadToEndOfFileCompletionNotification object:remoteConnection];
				if (connect(socketToRemoteServer, (struct sockaddr *)socketAddress, sizeof(*socketAddress)) == 0) {
				[remoteConnection readToEndOfFileInBackgroundAndNotify];
				}
			} else {
				close(socketToRemoteServer);
			}
		}*/
	}
}
@end
