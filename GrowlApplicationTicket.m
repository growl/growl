//
//  GrowlApplicationTicket.m
//  Growl
//
//  Created by Karl Adam on Tue Apr 27 2004.
//

#import "GrowlApplicationTicket.h"
#import "GrowlController.h"
#import "NSGrowlAdditions.h"

@implementation GrowlApplicationTicket
- (id) initWithApplication:(NSString *)inAppName 
				  withIcon:(NSImage *)inIcon 
		  andNotifications:(NSArray *) inAllNotifications 
		   andDefaultNotes:(NSArray *) inDefaults 
				fromParent:(GrowlController *)parent {

	if ( self = [super init] ) {
		_appName	= [inAppName retain];
		_icon		= [inIcon retain];
		_allNotifications = [inAllNotifications retain];
		_defaultNotifications = [inDefaults retain];
		_allowedNotifications = [inDefaults copy];
		_parent = [parent retain];
		
		_useDefaults = YES;
		[self registerParentForNotifications:inDefaults];
	}
	return self;
}

- (void) dealloc {
	[self unregisterParentForNotifications:_allowedNotifications];
	
	[_appName release];
	[_icon release];
	[_allNotifications release];
	[_defaultNotifications release];
	[_allowedNotifications release];
	[_parent release];
	
	_appName = nil;
	_icon = nil;
	_allNotifications = nil;
	_defaultNotifications = nil;
	_allowedNotifications = nil;
	_parent = nil;
	
	[super dealloc];
}

#pragma mark -
- (id) initTicketFromPath:(NSString *) inPath withParent:(GrowlController *) inParent {
	//load a Plist file of this object to maintain configuration through launches
	if ( self = [super init] ) {
		NSString *curTicket = [NSString stringWithContentsOfFile:inPath];
		NSDictionary *ticketsList = [curTicket propertyList];
		_appName = [[ticketsList objectForKey:GROWL_APP_NAME] retain];
		_defaultNotifications = [[NSArray alloc] initWithArray:[ticketsList objectForKey:GROWL_NOTIFICATIONS_DEFAULT]];
		_allNotifications = [[NSArray alloc] initWithArray:[ticketsList objectForKey:GROWL_NOTIFICATIONS_ALL]];
		_allowedNotifications = [[ticketsList objectForKey:GROWL_NOTIFICATIONS_USER_SET] retain];		
		_icon = [[[NSWorkspace sharedWorkspace] iconForApplication:_appName] retain];
		_parent = [inParent retain];
		_useDefaults = NO;
		
		[self registerParentForNotifications:_allowedNotifications];
	}
	
	return self;
}

- (void) saveTicket {
	// save a Plist file of this object to configure the prefs of apps that aren't running
	// construct a dictionary of our state data then save that dictionary to a file.
	NSString *savePath = [GROWL_TICKETS_DIR stringByAppendingPathComponent: [_appName stringByAppendingString:@".growlTicket"]];
	NSDictionary *saveDict = [NSDictionary dictionaryWithObjectsAndKeys:	_appName, GROWL_APP_NAME,
																			/*[_icon TIFFRepresentation], GROWL_NOTIFICATION_ICON,*/
																			_allNotifications, GROWL_NOTIFICATIONS_ALL,
																			_defaultNotifications, GROWL_NOTIFICATIONS_DEFAULT,
																			_allowedNotifications, GROWL_NOTIFICATIONS_USER_SET,
																			[NSNumber numberWithBool:_useDefaults], @"useDefaults",
																			nil];
	
	NSString *aString = [saveDict description];
	NSLog( @"%@ to be saved as \"Plist\"", aString );
	[aString writeToFile:savePath atomically:YES];
	NSLog( @"File saved to %@", savePath );
}

#pragma mark -

- (NSImage *) icon {
	return _icon;
}
- (void) setIcon:(NSImage *) inIcon {
	if(_icon != inIcon) {
		[_icon release];
		_icon = [inIcon retain];
	}
}

#pragma mark -

- (NSArray *) allNotifications {
	return _allNotifications;
}

- (void) setAllNotifications:(NSArray *) inArray {
	if ( inArray != _allNotifications ) {
		[_allNotifications release];
		_allNotifications = [inArray retain];
	}
	
	NSMutableSet * tmp;
	NSSet * inSet = [NSSet setWithArray:inArray];
	
#warning Someone look at this - it doesn't seem efficient, but it's the easiest way I came up with.
	//Intersect the allowed and default sets with the new set
	[self unregisterParentForNotifications:_allowedNotifications];
	tmp = [NSMutableSet setWithArray:_allowedNotifications];
	[tmp intersectSet:inSet];
	[_allowedNotifications release];
	_allowedNotifications = [[tmp allObjects] retain];
	[self registerParentForNotifications:_allowedNotifications];
	
	tmp = [NSMutableSet setWithArray:_defaultNotifications];
	[tmp intersectSet:inSet];
	[_defaultNotifications release];
	_defaultNotifications = [[tmp allObjects] retain];
}

- (NSArray *) defaultNotifications {
	return _defaultNotifications;
}

- (void) setDefaultNotifications:(NSArray *) inArray {
	[_defaultNotifications release];
	_defaultNotifications = [inArray retain];
	
	if(_useDefaults) {
		[self unregisterParentForNotifications:_allowedNotifications];
		[self registerParentForNotifications:inArray];
		[_allowedNotifications release];
		_allowedNotifications = [inArray retain];
	}
}


#pragma mark -
- (void) registerParentForNotifications:(NSArray *) inArray {
	NSEnumerator *note = [inArray objectEnumerator];
	NSString *obj = nil;
	NSDistributedNotificationCenter *distCenter = [NSDistributedNotificationCenter defaultCenter];
	while ( obj = [note nextObject] ) { //register the Controller for all the passed Notifications
		//NSLog(@"Registering for notification @\"%@\" from app with name @\"%@\"", obj, _appName);
		[distCenter addObserver:_parent 
					   selector:@selector(dispatchNotification:) 
						   name:obj 
						 object:nil];
	}
}

- (void) unregisterParentForNotifications:(NSArray *) inArray {
	NSEnumerator *note = [inArray objectEnumerator];
	NSString *obj = nil; 
	NSDistributedNotificationCenter *distCenter = [NSDistributedNotificationCenter defaultCenter];
	while ( obj = [note nextObject] ) { //unregister the Controller for all the passed Notifications
		//NSLog(@"Unregistering for notification @\"%@\" from app with name @\"%@\"", obj, _appName);
		[distCenter removeObserver:_parent 
							  name:obj 
							object:nil];
	}
}
@end

