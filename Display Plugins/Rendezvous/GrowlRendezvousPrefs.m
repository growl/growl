//
//  GrowlRendezvousPrefs.m
//  Display Plugins
//
//  Created by Ingmar Stein on 15.11.04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "GrowlRendezvousPrefs.h"
#import "GrowlRendezvousDefines.h"

@implementation GrowlRendezvousPrefs
- (NSString *)mainNibName {
	return( @"GrowlRendezvousPrefs" );
}

- (void)awakeFromNib
{
    browser = [[NSNetServiceBrowser alloc] init];
    services = [[NSMutableArray alloc] init];
    [browser setDelegate:self];
	[browser searchForServicesOfType:@"_growl._tcp." inDomain:@""];
}

- (void)dealloc
{
	[browser release];
	[services release];
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing
{
	[services addObject:aNetService];
	
	if(!moreComing) {
		[growlServiceList reloadData];
	}
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didRemoveService:(NSNetService *)aNetService moreComing:(BOOL)moreComing
{
	// This case is slightly more complicated. We need to find the object in the list and remove it.
	NSEnumerator * enumerator = [services objectEnumerator];
	NSNetService * currentNetService;
	
	while( (currentNetService = [enumerator nextObject]) ) {
		if ([currentNetService isEqual:aNetService]) {
			[services removeObject:currentNetService];
			break;
		}
	}
	
	if (serviceBeingResolved && [serviceBeingResolved isEqual:aNetService]) {
		[serviceBeingResolved stop];
		[serviceBeingResolved release];
		serviceBeingResolved = nil;
	}
	
	if(!moreComing) {
		[growlServiceList reloadData];        
	}
}

- (int)numberOfRowsInTableView:(NSTableView *)theTableView
{
	return( [services count] );
}

- (id)tableView:(NSTableView *)theTableView objectValueForTableColumn:(NSTableColumn *)theColumn row:(int)rowIndex
{
	return( [[services objectAtIndex:rowIndex] name] );
}

- (IBAction)serviceClicked:(id)sender
{
	// The row that was clicked corresponds to the object in services we wish to contact.
	int row = [sender selectedRow];

	// Make sure to cancel any previous resolves.
	if (serviceBeingResolved) {
		[serviceBeingResolved stop];
		[serviceBeingResolved release];
		serviceBeingResolved = nil;
	}

    if(-1 != row) {
		serviceBeingResolved = [services objectAtIndex:row];
		[serviceBeingResolved retain];
		[serviceBeingResolved setDelegate:self];
		[serviceBeingResolved resolve];
	}
}

- (void)netServiceDidResolveAddress:(NSNetService *)sender
{
    if ([[sender addresses] count] > 0) {
		WRITE_GROWL_PREF_VALUE(GrowlRendezvousRecipientPref, (CFDataRef)[[sender addresses] objectAtIndex:0], GrowlRendezvousPrefDomain );
	}
}

@end
