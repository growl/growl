//
//  GrowlController.h
//  Growl
//
//  Created by Karl Adam on Thu Apr 22 2004.
//  Copyright 2004 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to License.txt for details

#import <Foundation/Foundation.h>
#import "GrowlDisplayProtocol.h"

@protocol GrowlDisplayPlugin;

@class GrowlUDPServer;

@interface GrowlController : NSObject {
	NSMutableDictionary			*tickets;				//Application tickets
	NSLock						*registrationLock;
	NSMutableArray				*notificationQueue;
	NSMutableArray				*registrationQueue;
	NSNetService				*service;
	GrowlUDPServer				*udpServer;

	id<GrowlDisplayPlugin>		displayController;

	BOOL						growlIsEnabled;
	BOOL						growlFinishedLaunching;
}

+ (id) singleton;

- (BOOL) application:(NSApplication *)theApplication openFile:(NSString *)filename;

- (void) dispatchNotification:(NSNotification *)note;
- (void) dispatchNotificationWithDictionary:(NSDictionary *)dict;

- (void) loadTickets;
- (void) saveTickets;

- (void) preferencesChanged: (NSNotification *) note;

- (void) shutdown:(NSNotification *) note;

- (void) replyToPing:(NSNotification *) note;

// this is only public for the AppleScript commands
- (void) _registerApplicationWithDictionary:(NSDictionary *) userInfo;

@end

