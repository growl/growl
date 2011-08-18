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

@class GrowlNotificationCenter, GrowlTicketController, GrowlMenu, GrowlFirstLaunchWindowController;

typedef enum {
	GrowlNotificationResultPosted,
	GrowlNotificationResultNotRegistered,
	GrowlNotificationResultDisabled
} GrowlNotificationResult;

@interface GrowlApplicationController : GrowlAbstractSingletonObject <GrowlApplicationBridgeDelegate> {
	GrowlTicketController		*ticketController;

	// local GrowlNotificationCenter
	NSConnection				*growlNotificationCenterConnection;
	GrowlNotificationCenter		*growlNotificationCenter;

	GrowlDisplayPlugin			*defaultDisplayPlugin;

	BOOL						growlIsEnabled;
	BOOL						growlFinishedLaunching;
	BOOL						quitAfterOpen;
	BOOL						enableForward;
	NSArray						*destinations;

	NSDictionary				*versionInfo;
	NSImage						*growlIcon;
	NSData						*growlIconData;
	
	CFRunLoopTimerRef			updateTimer;
	
	NSThread					*mainThread;
    
    GrowlMenu                   *statusMenu;
    
    GrowlFirstLaunchWindowController *firstLaunchWindow;
}

+ (GrowlApplicationController *) sharedController;

- (BOOL) application:(NSApplication *)theApplication openFile:(NSString *)filename;

+ (NSString *) growlVersion;

- (GrowlNotificationResult) dispatchNotificationWithDictionary:(NSDictionary *)dict;
- (BOOL) registerApplicationWithDictionary:(NSDictionary *)userInfo;
- (void)growlNotificationDict:(NSDictionary *)growlNotificationDict didCloseViaNotificationClick:(BOOL)viaClick onLocalMachine:(BOOL)wasLocal;

- (NSDictionary *) versionDictionary;
- (NSString *) stringWithVersionDictionary:(NSDictionary *)d;

- (void) preferencesChanged:(NSNotification *) note;

- (void) replyToPing:(NSNotification *)note;

#pragma mark Accessors

//To be used by the GAB pathway if it can't register its connection (which means that there's already a GHA running).
- (BOOL) quitAfterOpen;
- (void) setQuitAfterOpen:(BOOL)flag;

- (NSThread *)mainThread;
	
@property (retain) GrowlMenu                   *statusMenu;
@end
