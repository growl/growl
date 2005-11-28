//
//	GrowlPathwayController.m
//	Growl
//
//	Created by Mac-arena the Bored Zo on 2005-08-08.
//	Copyright 2005 The Growl Project. All rights reserved.
//
//	This file is under the BSD License, refer to License.txt for details

@class GrowlPlugin;
@protocol GrowlPathwayPlugin;

@class GrowlUDPPathway, GrowlRemotePathway;

@interface GrowlPathwayController : NSObject {
	NSMutableSet   *pathways;

	// remote DistributedObjects server
	NSNetService				*service;
	NSPort						*socketPort;
	NSConnection				*serverConnection;
	GrowlRemotePathway			*vendedPathway;

	// UDP server
	GrowlUDPPathway				*UDPPathway;
}

+ (GrowlPathwayController *) sharedController;

- (BOOL) loadPathwaysFromPlugin:(GrowlPlugin <GrowlPathwayPlugin> *)plugin;

@end
