//
//  GrowlController.h
//  Growl
//
//  Created by Karl Adam on Thu Apr 22 2004.
//  Copyright 2004 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to License.txt for details

#import <Foundation/Foundation.h>

@protocol GrowlDisplayPlugin;

@class GrowlDistributedNotificationPathway, GrowlUDPPathway, GrowlRemotePathway;

@interface GrowlController : NSObject {
	NSMutableDictionary			*tickets;				//Application tickets
	NSLock						*registrationLock;
	NSMutableArray				*notificationQueue;
	NSMutableArray				*registrationQueue;

	//XXX temporary DNC pathway hack - remove when real pathway support is in
	// DNC server
	GrowlDistributedNotificationPathway *dncPathway;

	// DistributedObjects server
	NSNetService				*service;
	NSSocketPort				*socketPort;
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
	NSURL						*downloadURL;
	NSTimer						*updateTimer;
}

+ (id) standardController;

- (void) startServer;
- (void) stopServer;
- (void) startStopServer;

- (BOOL) application:(NSApplication *)theApplication openFile:(NSString *)filename;

+ (NSString *) growlVersion;

- (void) dispatchNotificationWithDictionary:(NSDictionary *)dict;
- (void) registerApplicationWithDictionary:(NSDictionary *) userInfo;

- (NSDictionary *) versionDictionary;
- (NSString *) stringWithVersionDictionary:(NSDictionary *)d;

//the current screenshots directory: $HOME/Library/Application\ Support/Growl/Screenshots
- (NSString *)screenshotsDirectory;
//returns e.g. @"Screenshot 1". you append your own pathname extension; it is guaranteed not to exist.
- (NSString *)nextScreenshotName;

- (void) preferencesChanged:(NSNotification *) note;

- (void) shutdown:(NSNotification *)note;

- (void) replyToPing:(NSNotification *)note;

- (void) checkVersion:(NSTimer *)timer;

@end

