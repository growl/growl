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

@implementation GrowlController

- (id) init {
	if ( self = [super init] ) {
		//load bundle for selected View Module
		//View Bundles will conform to a ViewModuleProtocol
		[[NSDistributedNotificationCenter defaultCenter] addObserver:self 
															selector:@selector( _registerApplication: ) 
																name:GROWL_APP_REGISTRATION
															  object:nil]; 
		_tickets = [[NSMutableDictionary alloc] init];

		_displayController = [self loadDisplay];
		[_displayController loadPlugin];
		
		NSLog( @"view loaded: %@\n Author: %@\n Description: %@\n Version: %@", _displayController,
																				[_displayController author],
																				[_displayController userDescription],
																				[_displayController version]
			   );
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
    NSImage *icon = nil;
    
	NSLog( @"%@", note );
	
	NSMutableDictionary *aDict = [NSMutableDictionary dictionaryWithDictionary:[note userInfo]];
	
	if ( ![aDict objectForKey:GROWL_NOTIFICATION_ICON] ) {
		icon = [[_tickets objectForKey:[aDict objectForKey:GROWL_APP_NAME]] icon];
	} else {
            icon = [[[NSImage alloc] initWithData:[aDict objectForKey:GROWL_NOTIFICATION_ICON]] autorelease];
            if(!icon){
                [aDict removeObjectForKey:GROWL_NOTIFICATION_ICON];
            }
	}
        if(icon != nil){
            [aDict setObject:icon forKey:GROWL_NOTIFICATION_ICON];
        }
	
	//NSLog( @"%@", [aDict objectForKey:GROWL_NOTIFICATION_ICON] );
	[_displayController displayNotificationWithInfo:aDict];
}

@end

#pragma mark -

@implementation GrowlController (private)
- (id <GrowlDisplayPlugin>) loadDisplay {
	id <GrowlDisplayPlugin> retVal;
	NSString *viewPath = [NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] resourcePath], @"BubblesNotificationView.growlView" ];
	//NSString *systemBundlesPath = @"/Library/Growl Support/";
	//NSString *userBundlesPath = @"~/Library/Growl Support/";
	
	NSLog( @"default - %@", viewPath );
	
	if ( [[NSUserDefaults standardUserDefaults] stringForKey:@"userDisplayPlugin"] ) {
		viewPath = [[NSUserDefaults standardUserDefaults] stringForKey:@"userDisplayPlugin"];
	}
	
	Class viewClass;
	NSBundle *viewBundle = [NSBundle bundleWithPath:viewPath];
	NSLog ( @"bundle loaded - %@", viewBundle );
	viewClass = [viewBundle principalClass];
	retVal = [[viewClass alloc] init];
	NSLog( @"object initialized - %@", retVal );
	
	return retVal;
}

#pragma mark -

- (void) _registerApplication:(NSNotification *) note {
	NSString *appName = [[note userInfo] objectForKey:GROWL_APP_NAME];
	NSSet *allNotes = [NSSet setWithArray:[[note userInfo] objectForKey:GROWL_NOTIFICATIONS_ALL]];
	NSSet *defaultNotes = [NSSet setWithArray:[[note userInfo] objectForKey:GROWL_NOTIFICATIONS_DEFAULT]];
	
	if ( ! [_tickets objectForKey:appName] ) {
		//add category to NSWorkspace for -iconForApplication later
		NSImage *appIcon = [[NSWorkspace sharedWorkspace] iconForApplication:appName];
		NSLog( @"AppIcon - %@", appIcon );
		GrowlApplicationTicket *newApp = [[GrowlApplicationTicket alloc] initWithApplication:appName 
																					withIcon:appIcon
																			andNotifications:allNotes 
																			   andDefaultSet:defaultNotes 
																				  fromParent:self];
		[_tickets setValue:newApp forKey:appName];
		NSLog( @"%@ has registered", appName );
	} else {
		NSLog( @"%@ has already registered", appName );
		GrowlApplicationTicket *aApp = [_tickets objectForKey:appName];
		[aApp setAllNotifications:allNotes];
		[aApp setDefaultNotifications:defaultNotes];
	}
	
}
@end
