//
//	GrowlPathwayController.m
//	Growl
//
//	Created by Mac-arena the Bored Zo on 2005-08-08.
//	Copyright 2005 The Growl Project. All rights reserved.
//
//	This file is under the BSD License, refer to License.txt for details

#import "GrowlPathwayController.h"
#import "GrowlDefinesInternal.h"
#import "GrowlPluginController.h"

static GrowlPathwayController *sharedController;

@implementation GrowlPathwayController

+ (GrowlPathwayController *) sharedController {
	if (!sharedController)
		sharedController = [[GrowlPathwayController alloc] init];

	return sharedController;
}

- (id) init {
	if ((self = [super init])) {
		pathways = [[NSMutableSet alloc] initWithCapacity:4U];

		GrowlPathway *pw = [[GrowlDistributedNotificationPathway alloc] init];
		[self installPathway:pw];
		[pw release];

		[self installPathway:[GrowlApplicationBridgePathway standardPathway]];

		if (isGrowlServerEnabled)
			[self startServer];
	}

	return self;
}

- (void) dealloc {
	/*releasing pathways first, and setting it to nil, means that the
	 *	-removeObject: calls that we get to from -stopServer will be no-ops.
	 */
	[pathways release];
	 pathways = nil;

	[self stopServer];

	[super dealloc];
}

#pragma mark -
#pragma mark Adding and removing pathways

- (void) installPathway:(GrowlPathway *)newPathway {
	[pathways addObject:newPathway];
}

- (void) uninstallPathway:(GrowlPathway *)newPathway {
	[pathways removeObject:newPathway];
}

@end
