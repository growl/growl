//
//  GrowlController.m
//  Growl
//
//  Created by Karl Adam on Thu Apr 22 2004.
//

#import "GrowlController.h"
#import "GrowlApplicationTicket.h"
#import "NSGrowlAdditions.h"

@interface GrowlController (private)
- (id <GrowlDisplayPlugin>) loadDisplay;
- (void) _registerApplication:(NSNotification *) note;
@end

#pragma mark -

@implementation GrowlController

- (id) init {
	if ( self = [super init] ) {

		[[NSDistributedNotificationCenter defaultCenter] addObserver:self 
															selector:@selector( _registerApplication: ) 
																name:GROWL_APP_REGISTRATION
															  object:nil]; 
		_tickets = [[NSMutableDictionary alloc] init];

		//load bundle for selected View Module
		_displayController = [self loadDisplay];
		[_displayController loadPlugin];
		
		NSLog( @"view loaded: %@\n Author: %@\n Description: %@\n Version: %@", _displayController,
																				[_displayController author],
																				[_displayController userDescription],
																				[_displayController version]
			   );
		[self loadTickets];
	}
	
	return self;
}

- (void) dealloc {
	//free your world
	NSLog( @"Controller goes bye now" );
	[_tickets release];
	_tickets = nil;
	
	[super dealloc];
}


#pragma mark -

- (void) dispatchNotification:(NSNotification *) note {
	//NSLog( @"%@", note );
	
	NSMutableDictionary *aDict = [NSMutableDictionary dictionaryWithDictionary:[note userInfo]];
	NSImage *icon = nil;
	if ( ![aDict objectForKey:GROWL_NOTIFICATION_ICON] ) {
		icon = [[_tickets objectForKey:[aDict objectForKey:GROWL_APP_NAME]] icon];
	} else {
		icon = [[[NSImage alloc] initWithData:[aDict objectForKey:GROWL_NOTIFICATION_ICON]] autorelease];
	}
	if(icon) {
		[aDict setObject:icon 
				  forKey:GROWL_NOTIFICATION_ICON];
	} else {
		[aDict removeObjectForKey:GROWL_NOTIFICATION_ICON];
	}
	
	[_displayController displayNotificationWithInfo:aDict];
}


- (void) loadTickets {
	NSString *aTicket;
	NSDirectoryEnumerator *t = [[NSFileManager defaultManager] enumeratorAtPath:GROWL_TICKETS_DIR];
	NSLog( @"Available Tickets - %@", t );
	
	while ( aTicket = [t nextObject] ) {
		aTicket = [NSString stringWithFormat:@"%@/%@", GROWL_TICKETS_DIR, aTicket];
		if ( [[aTicket pathExtension] isEqualTo:@"growlTicket"] ) {
			NSString *appName = [[aTicket lastPathComponent] stringByDeletingPathExtension];
			//NSLog( @"%@ is being loaded", aTicket );
			[_tickets setValue:[[GrowlApplicationTicket alloc] initTicketFromPath:aTicket withParent:self] forKey:appName];
		}
	}
	NSLog( @"tickets loaded - %@", _tickets );
}

- (void) saveTickets {
	[[_tickets allValues] makeObjectsPerformSelector:@selector( saveTicket )];
}

#pragma mark NSApplication Delegate Methods
- (void)applicationWillFinishLaunching:(NSNotification *)aNotification {
	BOOL dir;
	NSFileManager *fs = [NSFileManager defaultManager];
	
	if ( ! ([fs fileExistsAtPath:GROWL_SUPPORT_DIR isDirectory:&dir] && dir) ) {
		[fs createDirectoryAtPath:GROWL_SUPPORT_DIR attributes:nil];
		[fs createDirectoryAtPath:GROWL_TICKETS_DIR attributes:nil];
		[fs createDirectoryAtPath:GROWL_PLUGINS_DIR attributes:nil];
	}
}

//Post a notification when we are done launching so the application bridge can inform participating applications
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:GROWL_IS_READY 
																   object:nil 
																 userInfo:nil
													   deliverImmediately:YES];
}

//Same as applicationDidFinishLaunching, called when we are asked to reopen (that is, we are already running)
- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag {
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:GROWL_IS_READY 
																   object:nil 
																 userInfo:nil
													   deliverImmediately:YES];
	
	return YES;
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication*) theApplication {
	return NO;
}

@end

#pragma mark -

@implementation GrowlController (private)
- (id <GrowlDisplayPlugin>) loadDisplay {
	id <GrowlDisplayPlugin> retVal;
	NSString *viewPath = [NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] resourcePath], @"BubblesNotificationView.growlView" ];
	
	if ( [[NSUserDefaults standardUserDefaults] stringForKey:@"userDisplayPlugin"] ) {
		viewPath = [[NSUserDefaults standardUserDefaults] stringForKey:@"userDisplayPlugin"];
	}
	
	Class viewClass;
	NSBundle *viewBundle = [NSBundle bundleWithPath:viewPath];
	viewClass = [viewBundle principalClass];
	retVal = [[viewClass alloc] init];
	
	return retVal;
}

#pragma mark -

- (void) _registerApplication:(NSNotification *) note {
	NSString *appName = [[note userInfo] objectForKey:GROWL_APP_NAME];
	
	NSImage *appIcon;
	
	NSData  *iconData = [[note userInfo] objectForKey:GROWL_APP_ICON];
	if(iconData) {
		appIcon = [[NSImage alloc] initWithData:iconData];
	} else {
		appIcon = [[NSWorkspace sharedWorkspace] iconForApplication:appName];
	}
	
	NSArray * allNotes = [[note userInfo] objectForKey:GROWL_NOTIFICATIONS_ALL];
	NSArray * defaultNotes = [[note userInfo] objectForKey:GROWL_NOTIFICATIONS_DEFAULT];
	
	GrowlApplicationTicket *newApp = [[GrowlApplicationTicket alloc] initWithApplication:appName 
																				withIcon:appIcon
																		andNotifications:allNotes
																		 andDefaultNotes:defaultNotes
																			  fromParent:self];
	
	if ( ! [_tickets objectForKey:appName] ) {
		[_tickets setValue:newApp forKey:appName];
		NSLog( @"%@ has registered", appName );
	} else {
		NSLog( @"%@ has already registered", appName );
		GrowlApplicationTicket *aApp = [_tickets objectForKey:appName];
		[aApp setAllNotifications:allNotes];
		[aApp setDefaultNotifications:defaultNotes];
	}
	
	[newApp saveTicket];
	
}
@end

