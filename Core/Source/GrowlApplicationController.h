//
//  GrowlApplicationController.h
//  Growl
//
//  Created by Karl Adam on Thu Apr 22 2004.
//  Renamed from GrowlController by Peter Hosey on 2005-06-28.
//  Copyright 2004-2006 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to License.txt for details

#import <Foundation/Foundation.h>
#import "GrowlApplicationBridge.h"

@class GrowlNotificationCenter, GrowlMenu, GrowlFirstLaunchWindowController, GrowlPreferencePane;

typedef enum {
	GrowlNotificationResultPosted,
	GrowlNotificationResultNotRegistered,
	GrowlNotificationResultDisabled
} GrowlNotificationResult;

@interface GrowlApplicationController : NSObject<NSApplicationDelegate> {
	// local GrowlNotificationCenter
	NSConnection				*growlNotificationCenterConnection;
	GrowlNotificationCenter		*growlNotificationCenter;

	GrowlDisplayPlugin			*defaultDisplayPlugin;

	BOOL						growlIsEnabled;
	BOOL						growlFinishedLaunching;
	BOOL						quitAfterOpen;

	NSDictionary				*versionInfo;
	
	CFRunLoopTimerRef			updateTimer;
	    
    GrowlMenu                   *statusMenu;
    
    GrowlFirstLaunchWindowController *firstLaunchWindow;
    
    NSString                    *audioDeviceIdentifier;
   NSString                     *urlOnLaunch;
   
   GrowlPreferencePane *preferencesWindow;
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

- (void) firstLaunchClosed;
- (void) showPreferences;
- (void) updateMenu:(NSInteger)state;
#pragma mark Accessors

//To be used by the GAB pathway if it can't register its connection (which means that there's already a GHA running).
- (BOOL) quitAfterOpen;
- (void) setQuitAfterOpen:(BOOL)flag;
- (IBAction)quitWithWarning:(id)sender;

@property (retain) NSString                    *audioDeviceIdentifier;
@property (retain) GrowlMenu                   *statusMenu;

@end
