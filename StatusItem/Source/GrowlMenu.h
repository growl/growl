//
//  GrowlMenu.h
//
//  Created by rudy on Sun Apr 17 2005.
//  Copyright (c) 2005 The Growl Project. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GrowlApplicationBridge.h"
#import "GrowlAbstractDatabase.h"

@class GrowlPreferencesController, NSStatusItem;

enum {
	kGrowlNotRunningState,
	kGrowlRunningState
};

@interface GrowlMenu : NSObject <GrowlApplicationBridgeDelegate, GrowlDatabaseUpdateDelegate> {
	int							pid;
	GrowlPreferencesController	*preferences;
	NSStatusItem				*statusItem;

	NSImage						*clawImage;
	NSImage						*clawHighlightImage;
	NSImage						*disabledImage;
}

- (void) reloadPrefs:(NSNotification *)notification;
- (void) openGrowlPreferences:(id)sender;
- (void) stopGrowl:(id)sender;
- (void) startGrowl:(id)sender;
- (NSMenu *) createMenu;
- (void) setImage:(NSNumber*)state;
- (BOOL) validateMenuItem:(NSMenuItem *)item;
- (void) setGrowlMenuEnabled:(BOOL)state;

@end
