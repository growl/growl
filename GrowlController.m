//
//  GrowlController.m
//  Growl
//
//  Created by Karl Adam on Thu Apr 22 2004.
//  Copyright 2004 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to License.txt for details

#import "GrowlController.h"
#import "GrowlApplicationTicket.h"
#import "NSGrowlAdditions.h"
#import "GrowlNotificationServer.h"
#import "GrowlUDPServer.h"
#import <sys/socket.h>

@interface GrowlController (private)
- (void) loadDisplay;
- (BOOL) _tryLockQueue;
- (void) _unlockQueue;
- (void) _processNotificationQueue;
- (void) _processRegistrationQueue;
- (void) _registerApplication:(NSNotification *) note;
- (void) _postGrowlIsReady;
@end

#pragma mark -

static id singleton = nil;

@implementation GrowlController

+ (id) singleton {
	return singleton;
}

- (void) connectionDidDie:(NSDictionary *)userInfo {
	NSLog( @"NSConnection died" );
}

- (id) init {
	if ( (self = [super init]) ) {
		NSDistributedNotificationCenter * NSDNC = [NSDistributedNotificationCenter defaultCenter];

		[NSDNC addObserver:self 
				  selector:@selector( _registerApplication: ) 
					  name:GROWL_APP_REGISTRATION
					object:nil];
		[NSDNC addObserver:self
				  selector:@selector( preferencesChanged: )
					  name:GrowlPreferencesChanged
					object:nil];
		[NSDNC addObserver:self
				  selector:@selector( shutdown: )
					  name:GROWL_SHUTDOWN
					object:nil];
		[NSDNC addObserver:self
				  selector:@selector( dispatchNotification: )
					  name:GROWL_NOTIFICATION
					object:nil];
		[NSDNC addObserver:self
				  selector:@selector( replyToPing:)
					  name:GROWL_PING
					object:nil];
	
		tickets = [[NSMutableDictionary alloc] init];
		registrationLock = [[NSLock alloc] init];
		notificationQueue = [[NSMutableArray alloc] init];
		registrationQueue = [[NSMutableArray alloc] init];
		
		[[GrowlPreferences preferences] registerDefaults:
				[NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"GrowlDefaults" ofType:@"plist"]]];

		[self preferencesChanged:nil];
		
		if (!singleton) {
			singleton = self;
		}
	}

	return self;
}

- (void)startStopServer {
	BOOL enabled = [[[GrowlPreferences preferences] objectForKey:GrowlStartServerKey] boolValue];

	// Setup notification server
	if ( enabled && !service ) {
		// turn on
		NSSocketPort *socketPort = [[NSSocketPort alloc] initWithTCPPort:GROWL_TCP_PORT];
		NSConnection *connection;
		connection = [[NSConnection alloc] initWithReceivePort:socketPort sendPort:nil];
		GrowlNotificationServer *server = [[GrowlNotificationServer alloc] init];
		[socketPort autorelease];
		[server autorelease];
		[connection autorelease];
		[connection setRootObject:server];
		[connection setDelegate:self];

		// register with the default NSPortNameServer on the local host
		if ( ![connection registerName:@"GrowlServer"] ) {
			NSLog( @"Could not register Growl server." );
		}

		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(connectionDidDie:)
													 name:NSConnectionDidDieNotification
												   object:connection];

		// configure and publish the Rendezvous service
		service = [[NSNetService alloc] initWithDomain:@""	// use local registration domain
												  type:@"_growl._tcp."
												  name:@""	// use local computer name
												  port:GROWL_TCP_PORT];
		[service setDelegate:self];
		[service publish];

		// start UDP service
		udpServer = [[GrowlUDPServer alloc] init];
	} else if( !enabled && service ) {
		// turn off
		[service stop];
		[service release];
		service = nil;
		[udpServer release];
	}
}

- (void) dealloc {
	//free your world
	[tickets release];
	[registrationLock release];
	[notificationQueue release];
	[registrationQueue release];

	[super dealloc];
}

#pragma mark -

- (BOOL) application:(NSApplication *)theApplication openFile:(NSString *)filename {	
	BOOL retVal = NO;
	NSString *pathExtension = [filename pathExtension];
	
	if ( [pathExtension isEqualToString:@"growlView"] ) {
		[[GrowlPluginController controller] installPlugin:filename];
		
		[self _postGrowlIsReady];

		return( YES );

	} else if( [pathExtension isEqualToString:GROWL_REG_DICT_EXTENSION] ) {						
		NSDictionary	*regDict = [NSDictionary dictionaryWithContentsOfFile:filename];
		
		//Register this app using the indicated dictionary
		if ([self _tryLockQueue]) {
			[self _registerApplicationWithDictionary:regDict];
			[self _unlockQueue];
		} else {
			[registrationQueue addObject:regDict];
		}

		//If growl is not enabled and was not already running before (for example, via an autolaunch even
		//though the user's last preference setting was to click "Stop Growl," setting enabled to NO),
		//quit having registered; otherwise, we will remain running
		if ( !growlIsEnabled &&  !growlFinishedLaunching ) {
			//We want to hold in this thread until we can lock/unlock the queue and
			//ensure our registration is sent
			[registrationLock lock]; [registrationLock unlock];
			[self _unlockQueue];
			
			[NSApp terminate:self];
		} else {
			[self _postGrowlIsReady];	
		}

		retVal = YES;
	}
	
	return retVal;
}

#pragma mark -

- (void) dispatchNotification:(NSNotification *) note {
	if ([self _tryLockQueue]) {
		// It's unlocked. We can notify
		[self dispatchNotificationWithDictionary:[note userInfo]];
		[self _unlockQueue];
	} else {
		// It's locked. We need to queue this notification
		[notificationQueue addObject:[note userInfo]];
	}
}

- (void) dispatchNotificationWithDictionary:(NSDictionary *) dict {
	// Make sure this notification is actually registered
	GrowlApplicationTicket *ticket = [tickets objectForKey:[dict objectForKey:GROWL_APP_NAME]];
	if (!ticket || ![ticket isNotificationAllowed:[dict objectForKey:GROWL_NOTIFICATION_NAME]]) {
		// Either the app isn't registered or the notification is turned off
		// We should do nothing
		return;
	}

	NSMutableDictionary *aDict = [NSMutableDictionary dictionaryWithDictionary:dict];

	// Check icon
	NSImage *icon = nil;
	if ([aDict objectForKey:GROWL_NOTIFICATION_ICON]) {
		icon = [[[NSImage alloc] initWithData:[aDict objectForKey:GROWL_NOTIFICATION_ICON]]
					autorelease];
	} else {
		icon = [[[NSImage alloc] initWithData:[[ticket icon] TIFFRepresentation]] autorelease];
	}
	if (icon) {
		[aDict setObject:icon forKey:GROWL_NOTIFICATION_ICON];
	} else {
		[aDict removeObjectForKey:GROWL_NOTIFICATION_ICON]; // remove any invalid NSDatas
	}

	// If app icon present, convert to NSImage
	if ([aDict objectForKey:GROWL_NOTIFICATION_APP_ICON]) {
		icon = [[NSImage alloc] initWithData:[aDict objectForKey:GROWL_NOTIFICATION_APP_ICON]];
		[aDict setObject:icon forKey:GROWL_NOTIFICATION_APP_ICON];
		[icon release]; icon = nil;
	}
	
	// To avoid potential exceptions, make sure we have both text and title
	if (![aDict objectForKey:GROWL_NOTIFICATION_DESCRIPTION]) {
		[aDict setObject:@"" forKey:GROWL_NOTIFICATION_DESCRIPTION];
	}
	if (![aDict objectForKey:GROWL_NOTIFICATION_TITLE]) {
		[aDict setObject:@"" forKey:GROWL_NOTIFICATION_TITLE];
	}

    //Retrieve and set the the priority of the notification
	int priority = [ticket priorityForNotification:[dict objectForKey:GROWL_NOTIFICATION_NAME]];
	if (priority == GP_unset) {
		priority = [[dict objectForKey:GROWL_NOTIFICATION_PRIORITY] intValue];
	}
    [aDict setObject:[NSNumber numberWithInt:priority] forKey:GROWL_NOTIFICATION_PRIORITY];

    // Retrieve and set the sticky bit of the notification
    int sticky = [ticket stickyForNotification:[dict objectForKey:GROWL_NOTIFICATION_NAME]];
	if (ticket != nil && sticky >= 0) {
		[aDict setObject:[NSNumber numberWithBool:(sticky ? YES : NO)]
				  forKey:GROWL_NOTIFICATION_STICKY];
	}
    
	id <GrowlDisplayPlugin> display;

	if ([ticket usesCustomDisplay]) {
		display = [ticket displayPlugin];
	} else {
		display = displayController;
	}

	[display displayNotificationWithInfo:aDict];

	if (enableForward) {
		NSEnumerator *enumerator = [destinations objectEnumerator];
		NSData *destAddress;
		while ( (destAddress = [enumerator nextObject]) ) {
			NSSocketPort *serverPort = [[NSSocketPort alloc]
			initRemoteWithProtocolFamily:AF_INET
							  socketType:SOCK_STREAM
								protocol:0
								 address:destAddress];

			NSConnection *connection = [[NSConnection alloc] initWithReceivePort:nil sendPort:serverPort];
			NSDistantObject *theProxy = [connection rootProxy];
			[theProxy setProtocolForProxy:@protocol(GrowlNotificationProtocol)];
			id<GrowlNotificationProtocol> growlProxy = (id)theProxy;
			[growlProxy postNotification:dict];
			[serverPort release];
			[connection release];
		}
	}
}

- (void) loadTickets {
	[tickets addEntriesFromDictionary:[GrowlApplicationTicket allSavedTickets]];
}

- (void) saveTickets {
	[[tickets allValues] makeObjectsPerformSelector:@selector(saveTicket)];
}

- (void) preferencesChanged: (NSNotification *) note {
	//[note object] is the changed key. A nil key means reload our tickets.	
	if (note == nil || [[note object] isEqualTo:GrowlStartServerKey]) {
		[self startStopServer];
	}
	if (note == nil || [[note object] isEqualTo:GrowlUserDefaultsKey]) {
		[[GrowlPreferences preferences] synchronize];
	}
	if (note == nil || [[note object] isEqualTo:GrowlEnabledKey]) {
		growlIsEnabled = [[[GrowlPreferences preferences] objectForKey:GrowlEnabledKey] boolValue];
	}
	if (note == nil || [[note object] isEqualTo:GrowlEnableForwardKey]) {
		enableForward = [[[GrowlPreferences preferences] objectForKey:GrowlEnableForwardKey] boolValue];
	}
	if (note == nil || [[note object] isEqualTo:GrowlForwardDestinationsKey]) {
		destinations = [[GrowlPreferences preferences] objectForKey:GrowlForwardDestinationsKey];
	}
	if (note == nil || [note object] == nil) {
		[tickets removeAllObjects];
		[self loadTickets];
	}
	if (note == nil || [[note object] isEqualTo:GrowlDisplayPluginKey]) {
		[self loadDisplay];
	}
}

- (void) shutdown:(NSNotification *) note {
	[NSApp terminate: nil];
}

- (void) replyToPing:(NSNotification *) note {
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:GROWL_PONG object:nil];
}

#pragma mark NSApplication Delegate Methods
- (void) applicationWillFinishLaunching:(NSNotification *)aNotification {
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
- (void) applicationDidFinishLaunching:(NSNotification *)aNotification {
	[self _postGrowlIsReady];
}

//Same as applicationDidFinishLaunching, called when we are asked to reopen (that is, we are already running)
- (BOOL) applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag {
	[self _postGrowlIsReady];
	
	return YES;
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication*) theApplication {
	return NO;
}

- (void) _registerApplicationWithDictionary:(NSDictionary *) userInfo {
	NSString *appName = [userInfo objectForKey:GROWL_APP_NAME];
	
	NSImage *appIcon;
	
	NSData  *iconData = [userInfo objectForKey:GROWL_APP_ICON];
	if (iconData) {
		appIcon = [[[NSImage alloc] initWithData:iconData] autorelease];
	} else {
		appIcon = [[NSWorkspace sharedWorkspace] iconForApplication:appName];
	}
	
	NSArray *allNotes     = [userInfo objectForKey:GROWL_NOTIFICATIONS_ALL];
	NSArray *defaultNotes = [userInfo objectForKey:GROWL_NOTIFICATIONS_DEFAULT];
	
	GrowlApplicationTicket *newApp;
	
	if ( ! [tickets objectForKey:appName] ) {
		newApp = [[GrowlApplicationTicket alloc] initWithApplication:appName 
															withIcon:appIcon
													andNotifications:allNotes
													 andDefaultNotes:defaultNotes];
		[tickets setObject:newApp forKey:appName];
		[newApp autorelease];
	} else {
		newApp = [tickets objectForKey:appName];
		[newApp reRegisterWithAllNotes:allNotes defaults:defaultNotes icon:appIcon];
	}
	
	[newApp saveTicket];
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:GROWL_APP_REGISTRATION_CONF object:appName];

	if (enableForward) {
		NSEnumerator *enumerator = [destinations objectEnumerator];
		NSData *destAddress;
		while ( (destAddress = [enumerator nextObject]) ) {
			NSSocketPort *serverPort = [[NSSocketPort alloc]
			initRemoteWithProtocolFamily:AF_INET
							  socketType:SOCK_STREAM
								protocol:0
								 address:destAddress];
			
			NSConnection *connection = [[NSConnection alloc] initWithReceivePort:nil sendPort:serverPort];
			NSDistantObject *theProxy = [connection rootProxy];
			[theProxy setProtocolForProxy:@protocol(GrowlNotificationProtocol)];
			id<GrowlNotificationProtocol> growlProxy = (id)theProxy;
			[growlProxy registerApplication:userInfo];
			[serverPort release];
			[connection release];
		}
	}
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
	return [registrationLock tryLock];
}

- (void) _unlockQueue {
	// Make sure it's locked
	[registrationLock tryLock];
	[self _processRegistrationQueue];
	[self _processNotificationQueue];
	[registrationLock unlock];
}

- (void) _processNotificationQueue {
	NSArray *queue = [NSArray arrayWithArray:notificationQueue];
	[notificationQueue removeAllObjects];
	NSEnumerator *e = [queue objectEnumerator];
	NSDictionary *dict;
	
	while( (dict = [e nextObject] ) ) {
		[self dispatchNotificationWithDictionary:dict];
	}
}

- (void) _processRegistrationQueue {
	NSArray *queue = [NSArray arrayWithArray:registrationQueue];
	[registrationQueue removeAllObjects];
	NSEnumerator *e = [queue objectEnumerator];
	NSDictionary *dict;
	
	while( (dict = [e nextObject] ) ) {
		[self _registerApplicationWithDictionary:dict];
	}
}

#pragma mark -

- (void) _registerApplication:(NSNotification *) note {
	if ([self _tryLockQueue]) {
		[self _registerApplicationWithDictionary:[note userInfo]];
		[self _unlockQueue];
	} else {
		[registrationQueue addObject:[note userInfo]];
	}
}

- (void) _postGrowlIsReady {
	growlFinishedLaunching = YES;
	
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:GROWL_IS_READY 
																   object:nil 
																 userInfo:nil
													   deliverImmediately:YES];	
}

@end
