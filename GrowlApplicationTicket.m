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
		  andNotifications:(NSSet *) inAllNotifications 
			 andDefaultSet:(NSSet *) inDefaultSet 
				fromParent:(GrowlController *)parent {

	if ( self = [super init] ) {
		_appName	= [inAppName retain];
		_icon		= [inIcon retain];
		_allNotifications = [inAllNotifications retain];
		_defaultNotifications = [inDefaultSet retain];
		_allowedNotifications = [[inDefaultSet allObjects] retain];
		_parent = [parent retain];
		
		_useDefaults = YES;
		[self registerParentForNotifications:inDefaultSet];
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
	
	_appName = nil;
	_icon = nil;
	_allNotifications = nil;
	_defaultNotifications = nil;
	_allowedNotifications = nil;
	
	[super dealloc];
}

#pragma mark -
- (id) initTicketFromPath:(NSString *) inPath {
	//load a Plist file of this object to maintain configuration through launches
	if ( self = [super init] ) {
		NSString *curTicket = [NSString stringWithContentsOfFile:inPath];
		NSDictionary *ticketsList = [curTicket propertyList];
		_appName = [[ticketsList objectForKey:GROWL_APP_NAME] retain];
		_defaultNotifications = [[NSSet alloc] initWithArray:[ticketsList objectForKey:GROWL_NOTIFICATIONS_DEFAULT]];
		_allNotifications = [[NSSet alloc] initWithArray:[ticketsList objectForKey:GROWL_NOTIFICATIONS_ALL]];
		_allowedNotifications = [[ticketsList objectForKey:GROWL_NOTIFICATIONS_USER_SET] retain];		
		_icon = [[[NSWorkspace sharedWorkspace] iconForApplication:_appName] retain];
		
		_useDefaults = NO;
		
		[self registerParentForNotifications:[NSSet setWithArray:_allowedNotifications]];
	}
	
	return self;
}

- (void) saveTicket {
	// save a Plist file of this object to configure the prefs of apps that aren't running
	// construct a dictionary of our state data then save that dictionary to a file.
	NSString *savePath = [NSString stringWithFormat:@"%@%@/%@", GROWL_SUPPORT_DIR, GROWL_TICKETS_DIR, [_appName stringByAppendingString:@".growlTicket"]];
	NSDictionary *saveDict = [NSDictionary dictionaryWithObjectsAndKeys:	_appName, GROWL_APP_NAME,
																			/*[_icon TIFFRepresentation], GROWL_NOTIFICATION_ICON,*/
																			[_allNotifications allObjects], GROWL_NOTIFICATIONS_ALL,
																			[_defaultNotifications allObjects], GROWL_NOTIFICATIONS_DEFAULT,
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

#pragma mark -

- (NSSet *) allNotifications {
	return _allNotifications;
}

- (void) setAllNotifications:(NSSet *) inSet {
	[inSet retain];
	[_allNotifications release];
	_allNotifications = inSet;
	
	NSMutableSet * tmp;
	
	//Intersect the allowed and default sets with the new set
	[self unregisterParentForNotifications:_allowedNotifications];
	tmp = [NSMutableSet setWithArray:_allowedNotifications];
	[tmp intersectSet:inSet];
	[_allowedNotifications release];
	_allowedNotifications = [[tmp allObjects] retain];
	[self registerParentForNotifications:tmp];
	
	tmp = [NSMutableSet setWithSet:_defaultNotifications];
	[tmp intersectSet:inSet];
	[_defaultNotifications release];
	_defaultNotifications = [tmp retain];
}

- (NSSet *) defaultNotifications {
	return _defaultNotifications;
}

- (void) setDefaultNotifications:(NSSet *) inSet {
	[inSet retain];
	[_defaultNotifications release];
	_defaultNotifications = inSet;
	
	if(_useDefaults) {
		[self unregisterParentForNotifications:_allowedNotifications];
		[self registerParentForNotifications:inSet];
		[_allowedNotifications release];
		_allowedNotifications = [[inSet allObjects] retain];
	}
}


#pragma mark -
- (void) registerParentForNotifications:(NSSet *) inSet {
	NSEnumerator *note = [inSet objectEnumerator];
	id obj = nil;
	while ( obj = [note nextObject] ) { //register the Controller for all the passed Notifications
		[[NSDistributedNotificationCenter defaultCenter] addObserver:_parent 
															selector:@selector(dispatchNotification:) 
																name:(NSString *)obj 
															  object:nil];
	}
}

- (void) unregisterParentForNotifications:(NSArray *) inArray {
	NSEnumerator *note = [inArray objectEnumerator];
	id obj = nil; 
	while ( obj = [note nextObject] ) { //unregister the Controller for all the passed Notifications
		[[NSDistributedNotificationCenter defaultCenter] removeObserver:_parent 
																   name:(NSString *)obj 
																 object:nil];
	}
}
@end
