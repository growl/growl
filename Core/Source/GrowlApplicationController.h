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
#import "GrowlDefinesInternal.h"
#import "GrowlApplicationBridge.h"

@class GrowlNotificationCenter, GrowlMenu, GrowlFirstLaunchWindowController, GrowlPreferencePane;

#if defined(MAC_OS_X_VERSION_10_8) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_8
@interface GrowlApplicationNotificationCenterDelegate : NSObject<NSUserNotificationCenterDelegate> {
}

@end
#endif

@interface GrowlApplicationController : NSObject<NSApplicationDelegate> {
	// local GrowlNotificationCenter
	NSConnection				*growlNotificationCenterConnection;
	GrowlNotificationCenter	*growlNotificationCenter;
	
	BOOL							growlFinishedLaunching;
	
	NSDictionary				*versionInfo;
	
	GrowlMenu					*statusMenu;
	
	GrowlFirstLaunchWindowController *firstLaunchWindow;
	
#if defined(MAC_OS_X_VERSION_10_8) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_8
   GrowlApplicationNotificationCenterDelegate *appleNotificationDelegate;
#endif
   NSString						*urlOnLaunch;
   
   GrowlPreferencePane		*preferencesWindow;
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
- (IBAction)quitWithWarning:(id)sender;

@property (retain) GrowlMenu                   *statusMenu;

@end
