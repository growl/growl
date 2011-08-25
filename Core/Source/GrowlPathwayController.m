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
#import "GrowlLog.h"
#import "GrowlPluginController.h"
#import "GrowlPlugin.h"

#import "GrowlTCPPathway.h"
#import "GrowlPropertyListFilePathway.h"
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
		remotePathways = [[NSMutableSet alloc] initWithCapacity:2U];

		BOOL loadOldPathways = YES;
		NSNumber *num = [[NSUserDefaults standardUserDefaults] objectForKey:@"GrowlPreGNTPCompatibility"];
		if (num && [num respondsToSelector:@selector(boolValue)] && ([num boolValue] == NO))
			loadOldPathways = NO;

		if (loadOldPathways) {
			GrowlPathway *pw = [GrowlPropertyListFilePathway standardPathway];
			if (pw)
				[self installPathway:pw];

			pw = [GrowlApplicationBridgePathway standardPathway];
			if (pw)
				[self installPathway:pw];
		}

		GrowlRemotePathway *rpw = [[GrowlTCPPathway alloc] init];
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
	[remotePathways release];
	 remotePathways = nil;

	[self setServerEnabled:NO];

	[super dealloc];
}

#pragma mark -
#pragma mark Adding and removing pathways

- (void) installPathway:(GrowlPathway *)newPathway {
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
		self, GrowlPathwayControllerNotificationKey,
		newPathway, GrowlPathwayNotificationKey,
		nil];
		
	[nc postNotificationName:GrowlPathwayControllerWillInstallPathwayNotification
	                  object:self
	                userInfo:userInfo];
	[pathways addObject:newPathway];
	if ([newPathway isKindOfClass:[GrowlRemotePathway class]])
		[remotePathways addObject:newPathway];
	[nc postNotificationName:GrowlPathwayControllerDidInstallPathwayNotification
	                  object:self
	                userInfo:userInfo];
}

- (void) removePathway:(GrowlPathway *)newPathway {
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
		self, GrowlPathwayControllerNotificationKey,
		newPathway, GrowlPathwayNotificationKey,
		nil];
		
	[nc postNotificationName:GrowlPathwayControllerWillRemovePathwayNotification
	                  object:self
	                userInfo:userInfo];
	[pathways removeObject:newPathway];
	if ([newPathway isKindOfClass:[GrowlRemotePathway class]])
		[remotePathways removeObject:newPathway];
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
		for (GrowlRemotePathway *remotePathway in remotePathways) {
			remotePathway.enabled = flag;
		}

		serverEnabled = flag;
	}
}

- (void) pathwayCouldNotEnable:(GrowlPathway *)pathway {
	[[GrowlLog sharedController] writeToLog:@"Could not set enabled state to YES on pathway %@", pathway];

	NSError *error = [NSError errorWithDomain:GrowlErrorDomain code:GrowlPathwayErrorCouldNotEnable userInfo:nil];
	[NSApp presentError:error];
}
- (void) pathwayCouldNotDisable:(GrowlPathway *)pathway {
	[[GrowlLog sharedController] writeToLog:@"Could not set enabled state to NO on pathway %@", pathway];

	NSError *error = [NSError errorWithDomain:GrowlErrorDomain code:GrowlPathwayErrorCouldNotDisable userInfo:nil];
	[NSApp presentError:error];
}

#pragma mark -
#pragma mark Eating plug-ins

- (BOOL) loadPathwaysFromPlugin:(GrowlPlugin <GrowlPathwayPlugin> *)plugin {
	NSArray *pathwaysFromPlugin = [plugin pathways];
	if (pathwaysFromPlugin) {
		for (GrowlPathway *pw in pathwaysFromPlugin)
			[self installPathway:pw];

		return YES;
	} else
		return NO;
}

@end

@implementation GrowlPathwayController (PRIVATE)

- (void) setServerEnabledFromPreferences {
	[self setServerEnabled:[[GrowlPreferencesController sharedController] isGrowlServerEnabled]];
}

@end
