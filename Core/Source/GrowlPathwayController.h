//
//	GrowlPathwayController.m
//	Growl
//
//	Created by Peter Hosey on 2005-08-08.
//	Copyright 2005 The Growl Project. All rights reserved.
//
//	This file is under the BSD License, refer to License.txt for details


@protocol GrowlPathway;
@class GrowlTCPPathway;

extern NSString *GrowlPathwayControllerWillInstallPathwayNotification;
extern NSString *GrowlPathwayControllerDidInstallPathwayNotification;
extern NSString *GrowlPathwayControllerWillRemovePathwayNotification;
extern NSString *GrowlPathwayControllerDidRemovePathwayNotification;

//userInfo keys.
extern NSString *GrowlPathwayControllerNotificationKey;
extern NSString *GrowlPathwayNotificationKey;

@interface GrowlPathwayController : NSObject {
	NSMutableSet *pathways;

	unsigned reserved: 31;
	unsigned serverEnabled: 1;
}

+ (GrowlPathwayController *) sharedController;

#pragma mark Installing and removing pathways

- (void) installPathway:(id<GrowlPathway>)newPathway;
- (void) removePathway:(id<GrowlPathway>)newPathway;

#pragma mark Network control

- (BOOL) isServerEnabled;
- (void) setServerEnabled:(BOOL)enabled;

//Pathways that can be enabled/disabled (e.g., remote pathways) should send the pathway controller these message to report when those actions fail.
- (void) pathwayCouldNotEnable:(id<GrowlPathway>)pathway;
- (void) pathwayCouldNotDisable:(id<GrowlPathway>)pathway;

@end

@interface GrowlPathwayController (Private_ForApplicationControllerOnly)
- (void)setServerEnabledFromPreferences;
@end

