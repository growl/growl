//
//  GrowlController.m
//  Growl
//
//  Created by Karl Adam on Thu Apr 22 2004.
//

#import "GrowlController.h"


@implementation GrowlController

- (id) init {
	if ( self = [super init] ) {
		//load bundle for selected View Module
		//View Bundles will conform to a ViewModuleProtocol
		[[NSDistributedNotificationCenter defaultCenter] addObserver:self 
													  selector:@selector( _registerApplication: ) 
														  name:@"GrowlApplicationRegistrationNotification" 
														object:nil]; 
	}
	
	return self;
}

- (void) dealloc {
	//free your world
	NSLog( @"Controller goes bye now" );
	
	[super dealloc];
}

#pragma mark -

- (void) _registerApplication:(NSNotification *) note {
	NSLog( @"an application registered" );
	
	
}

#pragma mark -

- (void) dispatchNotification:(NSNotification *) note {
	
}

@end
