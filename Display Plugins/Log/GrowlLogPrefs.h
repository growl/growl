//
//  GrowlLogPrefs.h
//  Growl
//
//  Created by Olivier Bonnet on 13/12/04.
//  Copyright 2004 Olivier Bonnet. All rights reserved.
//

#import <PreferencePanes/PreferencePanes.h>


@interface GrowlLogPrefs : NSPreferencePane {
	IBOutlet NSMatrix		*fileType;
	IBOutlet NSButton		*consoleAppButton;
	IBOutlet NSPopUpButton	*customMenuButton;
	
	NSMutableArray					*customHistArray;
}

- (IBAction) typeChanged:(id)sender;
- (IBAction) openConsoleApp:(id)sender;
- (IBAction) customFileChosen:(id)sender;
- (void) updatePopupMenu;

@end
