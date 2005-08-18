//
//  JKPreferencesController.m
//  Rawr-endezvous
//
//  Created by Jeremy Knope on 9/17/04.
//  Copyright 2004 Jeremy Knope. All rights reserved.
//

#import "JKPreferencesController.h"
#import "JKMenuController.h"

@implementation JKPreferencesController
- (void)awakeFromNib {
	// *** Load service 'presets'
	NSString *dbPath;
	dbPath = [NSString stringWithFormat:@"%@/%@",[[NSBundle mainBundle] resourcePath],@"serviceDb.plist"];
	if (DEBUG)
		NSLog(@"Loading : %@",dbPath);
	//NSMutableDictionary *serviceList;
	serviceList = [NSDictionary dictionaryWithContentsOfFile:dbPath];
	itemPresets = [[NSMutableDictionary alloc] init];
	NSDictionary *myDict;
	NSEnumerator *myEnum;
	myEnum = [[serviceList objectForKey:@"services"] objectEnumerator];
	while ((myDict = [myEnum nextObject])) {
		//if(DEBUG)
		//	NSLog(@"Loopdaloop %@",[myDict objectForKey:@"service"]);
		NSMenuItem *newItem = [[NSMenuItem alloc] init];
		[newItem setTitle:[myDict objectForKey:@"name"]];
		[newItem setTarget:self];
		[newItem setAction:@selector(addPreset:)];
		[[servicePopUp menu] insertItem:newItem atIndex:[[servicePopUp menu] numberOfItems]];
		[itemPresets setObject:myDict forKey:[newItem title]];
	}
	//services = [[NSMutableArray alloc] init];
	//services = [NSMutableArray arrayWithObjects:@"_http._tcp.",@"_ssh._tcp.",@"_ftp._tcp.",nil];
	//NSLog(@"Number of services %i",[services count]);
	//serviceNames = [NSMutableArray arrayWithObjects:@"http",@"ssh",@"ftp",nil];
	//NSMutableDictionary *myServices = [[NSMutableDictionary alloc] init];
	//prefs = [[NSMutableDictionary alloc] init];
	//NSArray *mServices = [NSArray arrayWithObjects:[NSDictionary 
	//[services retain];
	//[serviceNames retain];
	//tableData = [[NSMutableDictionary alloc] init];
	//[tableData setObject:services forKey:@"services"];
	//[tableData setObject:serviceNames forKey:@"serviceNames"];
	//[self openPrefs];
	[removeServiceButton setEnabled:NO];
	[serviceTable setTarget:self];
	[serviceTable setAction:@selector(tableClick)];
	[serviceTable reloadData];
	showStatusMenuItem = YES;
}

- (void)openPrefs {
	if(DEBUG)
		NSLog(@"PrefsController:: Opening prefs");
	if([[NSUserDefaults standardUserDefaults] arrayForKey:@"services"] == nil) { // if nothing, set our default prefs, should clean this
		// set defaults
		//NSLog(@"PrefsController:: Setting default pref settings");
		NSMutableDictionary *mySsh = [[NSMutableDictionary alloc] init];
		[mySsh setObject:@"_ssh._tcp." forKey:@"service"];
		[mySsh setObject:@"ssh" forKey:@"protocol"];
		[mySsh setObject:@"SSH" forKey:@"name"];
		NSMutableDictionary *myAfp = [[NSMutableDictionary alloc] init];
		[myAfp setObject:@"_afpovertcp._tcp." forKey:@"service"];
		[myAfp setObject:@"afp" forKey:@"protocol"];
		[myAfp setObject:@"Apple File Sharing" forKey:@"name"];
		NSMutableDictionary *myFtp = [[NSMutableDictionary alloc] init];
		[myFtp setObject:@"_ftp._tcp." forKey:@"service"];
		[myFtp setObject:@"ftp" forKey:@"protocol"];
		[myFtp setObject:@"FTP" forKey:@"name"];
		NSMutableDictionary *myHttp = [[NSMutableDictionary alloc] init];
		[myHttp setObject:@"_http._tcp." forKey:@"service"];
		[myHttp setObject:@"http" forKey:@"protocol"];
		[myHttp setObject:@"Web" forKey:@"name"];
		NSArray *myArray = [NSArray arrayWithObjects:mySsh,myAfp,myFtp,myHttp,nil];
		//[myArray retain];
		[[NSUserDefaults standardUserDefaults] setObject:myArray forKey:@"services"];
		[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"hideLocalhost"];
		[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"showStatusMenuItem"];
	}
	// open
	//[services release];
	services = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] arrayForKey:@"services"]];
	if([[NSUserDefaults standardUserDefaults] boolForKey:@"hideLocalhost"])
		[localHideCheck setState:NSOnState];
	else
		[localHideCheck setState:NSOffState];
	for (unsigned i=0;i<[services count];i++) {
		if(DEBUG)
			NSLog(@"PrefsController:: Changing %i into mutable dict",i);
		id myDict = [services objectAtIndex:i];
		[services replaceObjectAtIndex:i withObject:[myDict mutableCopy]];
	}
	showStatusMenuItem = [[NSUserDefaults standardUserDefaults] boolForKey:@"showStatusMenuItem"];
	if (showStatusMenuItem)
		[showStatusMenuItemCheck setState:NSOnState];
	else
		[showStatusMenuItemCheck setState:NSOffState];
	[services retain];
	[serviceTable reloadData];
}

- (void)savePrefs {
	//NSLog(@"Saving prefs");
	[[NSUserDefaults standardUserDefaults] setObject:services forKey:@"services"];
	if([localHideCheck state] == NSOnState)
		[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"hideLocalhost"];
	else
		[[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"hideLocalhost"];
	if([showStatusMenuItemCheck state] == NSOnState) {
		[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"showStatusMenuItem"];
		showStatusMenuItem = YES;
	}
	else {
		[[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"showStatusMenuItem"];
		showStatusMenuItem = NO;
	}
	[main refreshServices:nil];
}

- (NSArray *)getServices {
	//NSLog(@"Sending services array %i",[services count]);
	return services;
}

- (BOOL)getShowStatusMenuItem {
	return showStatusMenuItem;
}

- (NSArray *)getOldServices {
	return oldServices;
}

- (IBAction) addService:(id)sender {
#pragma unused(sender)
	//[[tableData objectForKey:@"services"] addObject:@"_????._tcp."];
	//[[tableData objectForKey:@"serviceNames"] addObject:@"????"];
	if (DEBUG)
		NSLog(@"PrefsController:: Add service clicked");
	NSMutableDictionary *temp = [[NSMutableDictionary alloc] init];
	[temp setObject:@"_protocol._tcp." forKey:@"service"];
	[temp setObject:@"protocol" forKey:@"protocol"];
	[services addObject:temp];
	[serviceTable reloadData];
}

- (IBAction)removeService:(id)sender {
#pragma unused(sender)
	//[[tableData objectForKey:@"services"] removeObjectAtIndex:[serviceTable selectedRow]];
	//[[tableData objectForKey:@"serviceNames"] removeObjectAtIndex:[serviceTable selectedRow]];
	if ([serviceTable selectedRow] >= 0)
		[services removeObjectAtIndex:[serviceTable selectedRow]];
	[serviceTable reloadData];
}

- (IBAction)addPreset:(id)sender {
	//int index;
	//index = [servicePopUp indexOfSelectedItem];
	BOOL found;
	found = NO;
	NSString *myStr;
	myStr = [[itemPresets objectForKey:[sender title]] objectForKey:@"service"];
	NSEnumerator *myEnum;
	myEnum = [services objectEnumerator];
	NSDictionary *myDict;
	while ((myDict = [myEnum nextObject])) {
		//NSLog(@"Checking for %@ in %@",myStr,[myDict objectForKey:@"service"]);
		if ([[myDict objectForKey:@"service"] isEqualToString:myStr]) {
			found = YES;
			break;
		}
	}
	if (!found) {
		NSMutableDictionary *temp = [[NSMutableDictionary alloc] init];
		[temp setObject:[[itemPresets objectForKey:[sender title]] objectForKey:@"service"] forKey:@"service"];
		[temp setObject:[[itemPresets objectForKey:[sender title]] objectForKey:@"protocol"] forKey:@"protocol"];
		[temp setObject:[[itemPresets objectForKey:[sender title]] objectForKey:@"name"] forKey:@"name"];
		[services addObject:temp];
		[serviceTable reloadData];
	}
}

- (IBAction) saveClicked:(id)sender {
#pragma unused(sender)
	[prefWindow orderOut:self];
	[self savePrefs];
}

- (IBAction) openPrefsWindow:(id)sender {
#pragma unused(sender)
	[self openPrefs];
	if (oldServices)
		[oldServices release]; // rid of it automatically?
	oldServices = [[services copy] retain]; // save our old services so we can check them later in service manager
	[prefWindow makeKeyAndOrderFront:nil];
}

- (IBAction)closePrefsWindow:(id)sender {
#pragma unused(sender)
	[prefWindow orderOut:nil];
}

// -------------- NSTableView data source ----------------
- (int) numberOfRowsInTableView:(NSTableView *)theTableView {
#pragma unused(theTableView)
	if (DEBUG)
		NSLog(@"Returning table row count: %i",[services count]);
	return [services count];
}

- (id)tableView:(NSTableView *)theTableView objectValueForTableColumn:(NSTableColumn *)theColumn row:(int)rowIndex {
#pragma unused(theTableView)
	if(DEBUG)
		NSLog(@"Returning row & col value: %@", [[services objectAtIndex:rowIndex] objectForKey:[theColumn identifier]]);
	return [[services objectAtIndex:rowIndex] objectForKey:[theColumn identifier]];
}

- (void)tableView:(NSTableView *)theTableView setObjectValue:anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex {
#pragma unused(theTableView)
	if(DEBUG)
		NSLog(@"PrefsController:: Setting %@ for %@",anObject,[aTableColumn identifier]);
	[[services objectAtIndex:rowIndex] setObject:anObject forKey:[aTableColumn identifier]];
}

- (void) tableClick {
	[removeServiceButton setEnabled:([serviceTable selectedRow] >= 0)];
}

@end
