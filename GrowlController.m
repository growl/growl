//
//  GrowlController.m
//  Growl
//
//  Created by Karl Adam on Thu Apr 22 2004.
//

#import "GrowlController.h"
#import "GrowlApplicationTicket.h"

@implementation GrowlController

- (id) init {
	if ( self = [super init] ) {
		//load bundle for selected View Module
		//View Bundles will conform to a ViewModuleProtocol
		[[NSDistributedNotificationCenter defaultCenter] addObserver:self 
															selector:@selector( _registerApplication: ) 
																name:GROWL_APP_REGISTRATION
															  object:nil]; 
		_tickets = [[NSMutableArray alloc] init];
		//NSBundle *aBundle = [[NSBundle mainBundle] resourcePath]
		_displayController = nil;
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

- (void) _registerApplication:(NSNotification *) note {
	NSString *appName = [[note userInfo] objectForKey:GROWL_APP_NAME];
	NSSet *allNotes = [[note userInfo] objectForKey:GROWL_NOTIFICATIONS_ALL];
	NSSet *defaultNotes = [[note userInfo] objectForKey:GROWL_NOTIFICATIONS_DEFAULT];
	
	//add category to NSWorkspace for -iconForApplication later
	NSImage *appIcon = nil;
	
	GrowlApplicationTicket *newApp = [[GrowlApplicationTicket alloc] initWithApplication:appName 
																				withIcon:appIcon
																		andNotifications:allNotes 
																		   andDefaultSet:defaultNotes 
																			  fromParent:self];
	
	[_tickets addObject:newApp];
	
	NSLog( @"%@ has registered", appName );	
	
}

#pragma mark -

- (void) dispatchNotification:(NSNotification *) note {
	
}

@end
