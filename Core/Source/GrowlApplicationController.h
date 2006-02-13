//
//  GrowlApplicationController.h
//  Growl
//
//  Created by Karl Adam on Thu Apr 22 2004.
//  Renamed from GrowlController by Mac-arena the Bored Zo on 2005-06-28.
//  Copyright 2004-2006 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to License.txt for details

#import <Foundation/Foundation.h>
#import "GrowlApplicationBridge.h"
#import "GrowlAbstractSingletonObject.h"

@class GrowlDistributedNotificationPathway, GrowlUDPPathway, GrowlTCPPathway,
	MD5Authenticator, GrowlNotificationCenter, GrowlTicketController;

@interface GrowlApplicationController : GrowlAbstractSingletonObject <GrowlApplicationBridgeDelegate> {
	MD5Authenticator			*authenticator;
	GrowlTicketController		*ticketController;

	//XXX temporary DNC pathway hack - remove when real pathway support is in
	// DNC server
	GrowlDistributedNotificationPathway *dncPathway;

	// local GrowlNotificationCenter
	NSConnection				*growlNotificationCenterConnection;
	GrowlNotificationCenter		*growlNotificationCenter;

	GrowlDisplayPlugin			*displayController;

	BOOL						growlIsEnabled;
	BOOL						growlFinishedLaunching;
	BOOL						enableForward;
	NSArray						*destinations;

	NSDictionary				*versionInfo;
	NSImage						*growlIcon;
	NSData						*growlIconData;

	NSURL						*versionCheckURL;
	CFRunLoopTimerRef			updateTimer;

	NSThread					*mainThread;

	// remote DistributedObjects server
	GrowlTCPPathway				*tcpServer;

	// UDP server
	GrowlUDPPathway				*udpServer;

}

+ (GrowlApplicationController *) sharedController;

- (BOOL) application:(NSApplication *)theApplication openFile:(NSString *)filename;

+ (NSString *) growlVersion;

- (void) dispatchNotificationWithDictionary:(NSDictionary *)dict;
- (BOOL) registerApplicationWithDictionary:(NSDictionary *)userInfo;

- (NSDictionary *) versionDictionary;
- (NSString *) stringWithVersionDictionary:(NSDictionary *)d;
- (NSURL *) versionCheckURL;

- (void) preferencesChanged:(NSNotification *) note;

- (void) shutdown:(NSNotification *)note;
- (void) stopServer;
- (void) replyToPing:(NSNotification *)note;

- (NSThread *)mainThread;

@end
