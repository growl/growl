//
//  GrowlMenu.h
//
//  Created by rudy on Sun Apr 17 2005.
//  Copyright (c) 2005 The Growl Project. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GrowlPreferences, NSStatusItem;

@interface GrowlMenu : NSObject {
	GrowlPreferences	*preferences;
	NSStatusItem		*statusItem;

	NSImage				*clawImage;
	NSImage				*clawHighlightImage;
	NSImage				*squelchImage;
	NSImage				*squelchHighlightImage;
}

- (IBAction) openGrowlPreferences:(id)sender;
- (IBAction) defaultDisplay:(id)sender;
- (IBAction) stopGrowl:(id)sender;
- (IBAction) startGrowl:(id)sender;
- (NSMenu *) buildMenu;
- (BOOL) validateMenuItem:(NSMenuItem *)item;

@end
