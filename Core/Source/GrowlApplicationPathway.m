//
//  GrowlApplicationPathway.m
//  Growl
//
//  Created by Karl Adam on 3/10/05.
//  Copyright 2005 The Growl Project. All rights reserved.
//

#import "GrowlApplicationPathway.h"

static GrowlApplicationPathway *_theOneTrueGrowlApplicationPathway;

@implementation GrowlApplicationPathway

+ (GrowlApplicationPathway *) standardPathway {
	if ( ! _theOneTrueGrowlApplicationPathway ) 
		_theOneTrueGrowlApplicationPathway = [[self alloc] init];
	
	return _theOneTrueGrowlApplicationPathway;
}

- (id) init {
	if ( (! _theOneTrueGrowlApplicationPathway) && (self = [super init]) ) {
		// This uses the defaul connection since it's assumed that we need to
		// talk to apps, hence making this connection more important than the rest
		NSConnection *aConnection = [NSConnection defaultConnection];
		[aConnection setRootObject:self];
		
		if ( ! [aConnection registerName:@"GrowlApplicationBridgePathway"] ) {
			NSLog( @"MAKE YOUR TIME, SOMEONE HAS STOLEN OUR BRIDGE" );
			// Considering how important this is, if we are unable to gain this
			// we can assume that another instance of growl is running and terminate
			[NSApp terminate];
		}
		
		_theOneTrueGrowlApplicationPathway = self;
	}
	
	return _theOneTrueGrowlApplicationPathway;
}

@end
