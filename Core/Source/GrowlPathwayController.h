//
//	GrowlPathwayController.m
//	Growl
//
//	Created by Mac-arena the Bored Zo on 2005-08-08.
//	Copyright 2005 The Growl Project. All rights reserved.
//
//	This file is under the BSD License, refer to License.txt for details

@class GrowlPlugin;

@protocol GrowlPathwayPlugin <NSObject>

- (NSArray *) pathways;

@end

@class GrowlPathway, GrowlUDPPathway, GrowlTCPPathway;

extern NSString *GrowlPathwayControllerWillInstallPathwayNotification;
extern NSString *GrowlPathwayControllerDidInstallPathwayNotification;
extern NSString *GrowlPathwayControllerWillRemovePathwayNotification;
extern NSString *GrowlPathwayControllerDidRemovePathwayNotification;

//userInfo keys.
extern NSString *GrowlPathwayControllerNotificationKey;
extern NSString *GrowlPathwayNotificationKey;

@interface GrowlPathwayController : NSObject {
	NSMutableSet *pathways;
	NSMutableSet *remotePathways;

	unsigned reserved: 31;
	unsigned serverEnabled: 1;
}

+ (GrowlPathwayController *) sharedController;

#pragma mark Installing and removing pathways

- (void) installPathway:(GrowlPathway *)newPathway;
- (void) removePathway:(GrowlPathway *)newPathway;

#pragma mark Network control

- (BOOL) isServerEnabled;
- (void) setServerEnabled:(BOOL)enabled;

#pragma mark Eating plug-ins

//XXX make GrowlPathwayController a plug-in handler

- (BOOL) loadPathwaysFromPlugin:(GrowlPlugin <GrowlPathwayPlugin> *)plugin;

@end

@interface GrowlPathwayController (Private_ForApplicationControllerOnly)
- (void)setServerEnabledFromPreferences;
@end

