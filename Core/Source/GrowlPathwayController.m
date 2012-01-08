//
//	GrowlPathwayController.m
//	Growl
//
//	Created by Peter Hosey on 2005-08-08.
//	Copyright 2005 The Growl Project. All rights reserved.
//
//	This file is under the BSD License, refer to License.txt for details

#import "GrowlPathwayController.h"
#import "GrowlDefinesInternal.h"
#import "GrowlLog.h"
#import "GrowlPluginController.h"
#import "GrowlPlugin.h"

#import "GrowlTCPPathway.h"
#import "GrowlApplicationBridgePathway.h"

static GrowlPathwayController *sharedController = nil;

NSString *GrowlPathwayControllerWillInstallPathwayNotification = @"GrowlPathwayControllerWillInstallPathwayNotification";
NSString *GrowlPathwayControllerDidInstallPathwayNotification  = @"GrowlPathwayControllerDidInstallPathwayNotification";
NSString *GrowlPathwayControllerWillRemovePathwayNotification  = @"GrowlPathwayControllerWillRemovePathwayNotification";
NSString *GrowlPathwayControllerDidRemovePathwayNotification   = @"GrowlPathwayControllerDidRemovePathwayNotification";

NSString *GrowlPathwayControllerNotificationKey = @"GrowlPathwayController";
NSString *GrowlPathwayNotificationKey = @"GrowlPathway";

@interface GrowlPathwayController (PRIVATE)

- (void) setServerEnabledFromPreferences;

@end

@implementation GrowlPathwayController

+ (GrowlPathwayController *) sharedController {
	if (!sharedController)
		sharedController = [[GrowlPathwayController alloc] init];

	return sharedController;
}

- (id) init {
	if ((self = [super init])) {
		pathways = [[NSMutableSet alloc] initWithCapacity:4U];

		BOOL loadOldPathways = YES;
		NSNumber *num = [[NSUserDefaults standardUserDefaults] objectForKey:@"GrowlPreGNTPCompatibility"];
		if (num && [num respondsToSelector:@selector(boolValue)] && ([num boolValue] == NO))
			loadOldPathways = NO;

		if (loadOldPathways) {
			id<GrowlPathway> pw = [GrowlApplicationBridgePathway standardPathway];
			if (pw)
				[self installPathway:pw];
		}

		GrowlTCPPathway *rpw = [[GrowlTCPPathway alloc] init];
		[self installPathway:rpw];
		[rpw release];

		//set it to the contrary value, so that -setServerEnabledFromPreferences (which compares the values) will turn the server on if necessary.
		serverEnabled = ![[GrowlPreferencesController sharedController] isGrowlServerEnabled];
		[self setServerEnabledFromPreferences];
	}

	return self;
}

- (void) dealloc {
	/*releasing pathways first, and setting it to nil, means that the
	 *	-removeObject: calls that we get to from -stopServer will be no-ops.
	 */
	[pathways release];
	 pathways = nil;
    
	[self setServerEnabled:NO];

	[super dealloc];
}

#pragma mark -
#pragma mark Adding and removing pathways

- (void) installPathway:(id<GrowlPathway>)newPathway {
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
		self, GrowlPathwayControllerNotificationKey,
		newPathway, GrowlPathwayNotificationKey,
		nil];
		
	[nc postNotificationName:GrowlPathwayControllerWillInstallPathwayNotification
	                  object:self
	                userInfo:userInfo];
	[pathways addObject:newPathway];
    [newPathway openPathway];
	[nc postNotificationName:GrowlPathwayControllerDidInstallPathwayNotification
	                  object:self
	                userInfo:userInfo];
}

- (void) removePathway:(id<GrowlPathway>)newPathway {
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
		self, GrowlPathwayControllerNotificationKey,
		newPathway, GrowlPathwayNotificationKey,
		nil];
		
	[nc postNotificationName:GrowlPathwayControllerWillRemovePathwayNotification
	                  object:self
	                userInfo:userInfo];
    [newPathway closePathway];
	[pathways removeObject:newPathway];
	[nc postNotificationName:GrowlPathwayControllerDidRemovePathwayNotification
	                  object:self
	                userInfo:userInfo];
}

#pragma mark -
#pragma mark Remote pathways

- (BOOL) isServerEnabled {
	return serverEnabled;
}
- (void) setServerEnabled:(BOOL)flag {
	if ((BOOL)serverEnabled != flag) {
		serverEnabled = flag;
	}
}

- (void) pathwayCouldNotEnable:(id<GrowlPathway>)pathway {
	[[GrowlLog sharedController] writeToLog:@"Could not set enabled state to YES on pathway %@", pathway];

	NSError *error = [NSError errorWithDomain:GrowlErrorDomain code:GrowlPathwayErrorCouldNotEnable userInfo:nil];
	[NSApp presentError:error];
}
- (void) pathwayCouldNotDisable:(id<GrowlPathway>)pathway {
	[[GrowlLog sharedController] writeToLog:@"Could not set enabled state to NO on pathway %@", pathway];

	NSError *error = [NSError errorWithDomain:GrowlErrorDomain code:GrowlPathwayErrorCouldNotDisable userInfo:nil];
	[NSApp presentError:error];
}


@end

@implementation GrowlPathwayController (PRIVATE)

- (void) setServerEnabledFromPreferences {
	[self setServerEnabled:[[GrowlPreferencesController sharedController] isGrowlServerEnabled]];
}

@end
