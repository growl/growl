//
//  GrowlApplicationTicket.m
//  Growl
//
//  Created by Karl Adam on Tue Apr 27 2004.
//

#import "GrowlApplicationTicket.h"
#import "GrowlController.h"

@implementation GrowlApplicationTicket
- (id) initWithApplication:(NSString *)inAppName withIcon:(NSImage *)inIcon andNotifications:(NSSet *) inAllNotifications andDefaultSet:(NSSet *) inDefaultSet fromParent:(GrowlController *)parent {

	if ( self = [super init] ) {
		_appName	= [inAppName retain];
		_icon		= [inIcon retain];
		_allNotifications = [inAllNotifications retain];
		_defaultNotifications = [inDefaultSet retain];
		_allowedNotifications = [inDefaultSet allObjects];
		_parent = [parent retain];
		
		useDefaults = YES;
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
- (void) loadTicket {
	//load an XML file of this object to maintain configuration through launches
}

- (void) saveTicket {
	//save an XML file of this object to configure the prefs of apps that aren't running
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
}

- (NSSet *) defaultNotifications {
	return _defaultNotifications;
}

- (void) setDefaultNotifications:(NSSet *) inSet {
	[inSet retain];
	[_defaultNotifications release];
	_defaultNotifications = inSet;
}


#pragma mark -
- (void) registerParentForNotifications:(NSSet *) inSet {
	NSEnumerator *note = [inSet objectEnumerator];
	id obj = nil;
	while ( obj = [note nextObject] ) { //register the Controller for all the passed Notifications
		[[NSDistributedNotificationCenter defaultCenter] addObserver:_parent selector:@selector(dispatchNotification:) name:(NSString *)obj object:nil];
	}
}

- (void) unregisterParentForNotifications:(NSArray *) inArray {
	NSEnumerator *note = [inArray objectEnumerator];
	id obj = nil; 
	while ( obj = [note nextObject] ) { //register the Controller for all the passed Notifications
		[[NSDistributedNotificationCenter defaultCenter] removeObserver:_parent name:(NSString *)obj object:nil];
	}
}
@end
