//
//  GrowlController.h
//  Growl
//
//  Created by Karl Adam on Thu Apr 22 2004.
//  Copyright 2004-2005 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to License.txt for details

#import <Foundation/Foundation.h>

@protocol GrowlDisplayPlugin;

@class GrowlDistributedNotificationPathway, GrowlUDPPathway, GrowlRemotePathway,
	MD5Authenticator, GrowlNotificationCenter;

@interface GrowlController : NSObject {
	NSMutableDictionary			*tickets;				//Application tickets
	NSLock						*registrationLock;
	NSMutableArray				*notificationQueue;
	NSMutableArray				*registrationQueue;
	MD5Authenticator			*authenticator;

	//XXX temporary DNC pathway hack - remove when real pathway support is in
	// DNC server
	GrowlDistributedNotificationPathway *dncPathway;

	// local GrowlNotificationCenter
	NSConnection				*growlNotificationCenterConnection;
	GrowlNotificationCenter		*growlNotificationCenter;

	// remote DistributedObjects server
	NSNetService				*service;
	NSPort						*socketPort;
	NSConnection				*serverConnection;
	GrowlRemotePathway			*server;

	// UDP server
	GrowlUDPPathway				*udpServer;

	id<GrowlDisplayPlugin>		displayController;

	BOOL						growlIsEnabled;
	BOOL						growlFinishedLaunching;
	BOOL						enableForward;
	NSArray						*destinations;

	NSDictionary				*versionInfo;
	NSImage						*growlIcon;
	NSData						*growlIconData;

	NSURL						*versionCheckURL;
	NSTimer						*updateTimer;
}

+ (GrowlController *) standardController;

- (void) startServer;
- (void) stopServer;
- (void) startStopServer;

- (BOOL) application:(NSApplication *)theApplication openFile:(NSString *)filename;

+ (NSString *) growlVersion;

- (void) dispatchNotificationWithDictionary:(NSDictionary *)dict;
- (BOOL) registerApplicationWithDictionary:(NSDictionary *) userInfo;

- (NSDictionary *) versionDictionary;
- (NSString *) stringWithVersionDictionary:(NSDictionary *)d;

- (void) preferencesChanged:(NSNotification *) note;

- (void) shutdown:(NSNotification *)note;

- (void) replyToPing:(NSNotification *)note;

- (void) checkVersion:(NSTimer *)timer;

@end

