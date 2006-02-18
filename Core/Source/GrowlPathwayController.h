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
//XXX figure out if there needs to be anything here.
@end

@class GrowlUDPPathway, GrowlTCPPathway;

extern NSString *GrowlPathwayControllerWillInstallPathwayNotification;
extern NSString *GrowlPathwayControllerDidInstallPathwayNotification;
extern NSString *GrowlPathwayControllerWillRemovePathwayNotification;
extern NSString *GrowlPathwayControllerDidRemovePathwayNotification;

//userInfo keys.
extern NSString *GrowlPathwayControllerNotificationKey;
extern NSString *GrowlPathwayNotificationKey;

@interface GrowlPathwayController : NSObject {
	NSMutableSet   *pathways;

	// TCP server
	GrowlTCPPathway			*TCPPathway;

	// UDP server
	GrowlUDPPathway			*UDPPathway;
}

+ (GrowlPathwayController *) sharedController;

#pragma mark Installing and removing pathways

- (void) installPathway:(GrowlPathway *)newPathway;
- (void) removePathway:(GrowlPathway *)newPathway;

#pragma mark Batch operation

- (BOOL) loadPathwaysFromPlugin:(GrowlPlugin <GrowlPathwayPlugin> *)plugin;

@end
