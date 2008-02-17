//
//  GrowlApplicationBridgePathway.m
//  Growl
//
//  Created by Karl Adam on 3/10/05.
//  Copyright 2005-2006 The Growl Project. All rights reserved.
//

#import "GrowlApplicationBridgePathway.h"

#import "GrowlApplicationController.h"

static GrowlApplicationBridgePathway *theOneTrueGrowlApplicationBridgePathway;

@implementation GrowlApplicationBridgePathway

+ (GrowlApplicationBridgePathway *) standardPathway {
	if (!theOneTrueGrowlApplicationBridgePathway)
		theOneTrueGrowlApplicationBridgePathway = [[GrowlApplicationBridgePathway alloc] init];

	return theOneTrueGrowlApplicationBridgePathway;
}

- (id) init {
	if (theOneTrueGrowlApplicationBridgePathway) {
		[self release];
		return theOneTrueGrowlApplicationBridgePathway;
	}

	if ((self = [super init])) {
		/*This uses the default connection since it's assumed that we need to
		 *	talk to apps, hence making this connection more important than the rest
		 */
		NSConnection *aConnection = [NSConnection defaultConnection];
		[aConnection setRootObject:self];

		if (![aConnection registerName:@"GrowlApplicationBridgePathway"]) {
			NSLog(@"WARNING: Could not register connection for GrowlApplicationBridgePathway");
			[self release];
			return nil;
		}

		theOneTrueGrowlApplicationBridgePathway = self;

		//Watch a new run loop for incoming messages
		[aConnection runInNewThread];
		//Stop watching the current (main) run loop
		[aConnection removeRunLoop:[NSRunLoop currentRunLoop]];
	}

	return self;
}

@end
