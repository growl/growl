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
- (void) loadDisplay;
- (BOOL) _tryLockQueue;
- (void) _unlockQueue;
- (void) _processNotificationQueue;
- (void) _processRegistrationQueue;
- (void) _registerApplication:(NSNotification *) note;
- (void) _registerApplicationWithDictionary:(NSDictionary *) userInfo;
@end

#pragma mark -

static id _singleton = nil;

@implementation GrowlController

+ (id) singleton {
	return _singleton;
}

- (id) init {
	if ( self = [super init] ) {

		[[NSDistributedNotificationCenter defaultCenter] addObserver:self 
															selector:@selector( _registerApplication: ) 
																name:GROWL_APP_REGISTRATION
															  object:nil];
		[[NSDistributedNotificationCenter defaultCenter] addObserver:self
															selector:@selector( dispatchNotification: )
																name:GROWL_NOTIFICATION
															  object:nil];
		[[NSDistributedNotificationCenter defaultCenter] addObserver:self
															selector:@selector( preferencesChanged: )
																name:GrowlPreferencesChanged
															  object:nil];
		[[NSDistributedNotificationCenter defaultCenter] addObserver:self
															selector:@selector( shutdown: )
																name:GROWL_SHUTDOWN
															  object:nil];
		_tickets = [[NSMutableDictionary alloc] init];
		_registrationLock = [[NSLock alloc] init];
		_notificationQueue = [[NSMutableArray alloc] init];
		_registrationQueue = [[NSMutableArray alloc] init];
		
		[[GrowlPreferences preferences] registerDefaults:
				[NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"GrowlDefaults" ofType:@"plist"]]];

		[self preferencesChanged:nil];
	}
	
	if (!_singleton)
		_singleton = self;
	
	return self;
}

- (void) dealloc {
	//free your world
	[_tickets release];
	[_registrationLock release];
	[_notificationQueue release];
	[_registrationQueue release];
	
	[super dealloc];
}


#pragma mark -

- (void) dispatchNotification:(NSNotification *) note {
	if ([self _tryLockQueue]) {
		// It's unlocked. We can notify
		[self dispatchNotificationWithDictionary:[note userInfo] overrideCheck:NO];
		[self _unlockQueue];
	} else {
		// It's locked. We need to queue this notification
		[_notificationQueue addObject:[note userInfo]];
	}
}

- (void) dispatchNotificationWithDictionary:(NSDictionary *) dict overrideCheck:(BOOL) override {
	// Make sure this notification is actually registered
	GrowlApplicationTicket *ticket = [_tickets objectForKey:[dict objectForKey:GROWL_APP_NAME]];
	if (!override && 
		(!ticket || ![ticket isNotificationAllowed:[dict objectForKey:GROWL_NOTIFICATION_NAME]])) {
		// Either the app isn't registered or the notification is turned off
		// We should do nothing
		return;
	}
	
	NSMutableDictionary *aDict = [NSMutableDictionary dictionaryWithDictionary:dict];
	NSImage *icon = nil;
	if ( ![dict objectForKey:GROWL_NOTIFICATION_ICON] ) {
		icon = [ticket icon];
	} else {
		icon = [[NSImage alloc] initWithData:[aDict objectForKey:GROWL_NOTIFICATION_ICON]];
		if(icon)
			icon = [icon autorelease];
	}
	if(icon) {
		[aDict setObject:icon 
				 forKey:GROWL_NOTIFICATION_ICON];
	} else {
		[aDict removeObjectForKey:GROWL_NOTIFICATION_ICON];
	}
	
	id <GrowlDisplayPlugin> display;
	
	if([ticket usesCustomDisplay])
		display = [ticket displayPlugin];
	else
		display = displayController;
	
	[display displayNotificationWithInfo:aDict];
}

- (void) loadTickets {
	[_tickets addEntriesFromDictionary:[GrowlApplicationTicket allSavedTickets]];
}

- (void) saveTickets {
	NSString *destDir;
	NSArray *searchPath = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, /*expandTilde*/ YES);

	destDir = [searchPath objectAtIndex:0];
	destDir = [destDir stringByAppendingPathComponent:@"Application Support"];
	destDir = [destDir stringByAppendingPathComponent:@"Growl"];
	destDir = [destDir stringByAppendingPathComponent:@"Tickets"];

	[[_tickets allValues] makeObjectsPerformSelector:@selector(saveTicketToPath:) withObject:destDir];
}

- (void) preferencesChanged: (NSNotification *) note {
	//[note object] is the changed key. A nil key means reload our tickets.
	if(note == nil || [note object] == nil) {
		[_tickets removeAllObjects];
		[self loadTickets];
	}
	if(note == nil || [[note object] isEqualTo:GrowlDisplayPluginKey]) {
		[self loadDisplay];
	}
}

- (void) shutdown:(NSNotification *) note {
	[NSApp terminate: nil];
}

#pragma mark NSApplication Delegate Methods
- (void)applicationWillFinishLaunching:(NSNotification *)aNotification {
//	BOOL dir;
	NSFileManager *fs = [NSFileManager defaultManager];

	NSString *destDir, *subDir;
	NSArray *searchPath = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, /*expandTilde*/ YES);

	destDir = [searchPath objectAtIndex:0];
	[fs createDirectoryAtPath:destDir attributes:nil];
	destDir = [destDir stringByAppendingPathComponent:@"Application Support"];
	[fs createDirectoryAtPath:destDir attributes:nil];
	destDir = [destDir stringByAppendingPathComponent:@"Growl"];
	[fs createDirectoryAtPath:destDir attributes:nil];

	subDir  = [destDir stringByAppendingPathComponent:@"Tickets"];
	[fs createDirectoryAtPath:subDir attributes:nil];
	subDir  = [destDir stringByAppendingPathComponent:@"Plugins"];
	[fs createDirectoryAtPath:subDir attributes:nil];
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
- (void) loadDisplay {
	
	NSString * displayPlugin = [[GrowlPreferences preferences] objectForKey:GrowlDisplayPluginKey];

	displayController = [[GrowlPluginController controller] displayPluginNamed:displayPlugin];

}

#pragma mark -

- (BOOL) _tryLockQueue {
	return [_registrationLock tryLock];
}

- (void) _unlockQueue {
	// Make sure it's locked
	[_registrationLock tryLock];
	[self _processRegistrationQueue];
	[self _processNotificationQueue];
	[_registrationLock unlock];
}

- (void) _processNotificationQueue {
	NSArray *queue = [NSArray arrayWithArray:_notificationQueue];
	[_notificationQueue removeAllObjects];
	NSEnumerator *e = [queue objectEnumerator];
	NSDictionary *dict;
	while (dict = [e nextObject]) {
		[self dispatchNotificationWithDictionary:dict overrideCheck:NO];
	}
}

- (void) _processRegistrationQueue {
	NSArray *queue = [NSArray arrayWithArray:_registrationQueue];
	[_registrationQueue removeAllObjects];
	NSEnumerator *e = [queue objectEnumerator];
	NSDictionary *dict;
	while (dict = [e nextObject]) {
		[self _registerApplicationWithDictionary:dict];
	}
}

#pragma mark -

- (void) _registerApplication:(NSNotification *) note {
	if ([self _tryLockQueue]) {
		[self _registerApplicationWithDictionary:[note userInfo]];
		[self _unlockQueue];
	} else {
		[_registrationQueue addObject:[note userInfo]];
	}
}

- (void) _registerApplicationWithDictionary:(NSDictionary *) userInfo {
	NSString *appName = [userInfo objectForKey:GROWL_APP_NAME];
	
	NSImage *appIcon;
	
	NSData  *iconData = [userInfo objectForKey:GROWL_APP_ICON];
	if(iconData) {
		appIcon = [[[NSImage alloc] initWithData:iconData] autorelease];
	} else {
		appIcon = [[NSWorkspace sharedWorkspace] iconForApplication:appName];
	}

	NSArray *allNotes     = [userInfo objectForKey:GROWL_NOTIFICATIONS_ALL];
	NSArray *defaultNotes = [userInfo objectForKey:GROWL_NOTIFICATIONS_DEFAULT];

	GrowlApplicationTicket *newApp;

	if ( ! [_tickets objectForKey:appName] ) {
		newApp = [[GrowlApplicationTicket alloc] initWithApplication:appName 
															withIcon:appIcon
													andNotifications:allNotes
													 andDefaultNotes:defaultNotes];
		[_tickets setObject:newApp forKey:appName];
		[newApp autorelease];
	} else {
		newApp = [_tickets objectForKey:appName];
		[newApp setAllNotifications:allNotes];
		[newApp setDefaultNotifications:defaultNotes];
		[newApp setIcon:appIcon];
	}

	[newApp saveTicket];
}

@end
