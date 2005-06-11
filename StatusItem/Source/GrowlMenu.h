//
//  GrowlMenu.h
//
//  Created by rudy on Sun Apr 17 2005.
//  Copyright (c) 2005 The Growl Project. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GrowlPreferences, NSStatusItem;

@interface GrowlMenu : NSObject {
	int					pid;
	GrowlPreferences	*preferences;
	NSStatusItem		*statusItem;

	NSImage				*clawImage;
	NSImage				*clawHighlightImage;
	NSImage				*squelchImage;
	NSImage				*squelchHighlightImage;
}

- (void) shutdown:(id)sender;
- (void) reloadPrefs:(NSNotification *)notification;
- (void) openGrowlPreferences:(id)sender;
- (void) defaultDisplay:(id)sender;
- (void) stopGrowl:(id)sender;
- (void) startGrowl:(id)sender;
- (void) squelchMode:(id)sender;
- (NSMenu *) createMenu;
- (void) setImage;
- (BOOL) validateMenuItem:(NSMenuItem *)item;
- (void) setGrowlMenuEnabled:(BOOL)state;

@end
