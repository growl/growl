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

@class GrowlUDPServer, GrowlNotificationServer;

@interface GrowlController : NSObject {
	NSMutableDictionary			*tickets;				//Application tickets
	NSLock						*registrationLock;
	NSMutableArray				*notificationQueue;
	NSMutableArray				*registrationQueue;

	// DistributedObjects server
	NSNetService				*service;
	NSSocketPort				*socketPort;
	NSConnection				*serverConnection;
	GrowlNotificationServer		*server;

	// UDP server
	GrowlUDPServer				*udpServer;

	id<GrowlDisplayPlugin>		displayController;

	BOOL						growlIsEnabled;
	BOOL						growlFinishedLaunching;
	BOOL						enableForward;
	NSArray						*destinations;

	NSDictionary				*versionInfo;
}

+ (id) standardController;

- (void) startServer;
- (void) stopServer;
- (void) startStopServer;

- (BOOL) application:(NSApplication *)theApplication openFile:(NSString *)filename;

- (NSString *) growlVersion;

- (void) dispatchNotification:(NSNotification *)note;
- (void) dispatchNotificationWithDictionary:(NSDictionary *)dict;
- (void) registerApplicationWithDictionary:(NSDictionary *) userInfo;

- (NSDictionary *) versionDictionary;
- (NSString *) stringWithVersionDictionary:(NSDictionary *)d;

- (void) loadTickets;
- (void) saveTickets;

- (NSString *)screenshotsDirectory;
- (NSString *)nextScreenshotName;

- (void) preferencesChanged:(NSNotification *) note;

- (void) shutdown:(NSNotification *)note;

- (void) replyToPing:(NSNotification *)note;

@end

