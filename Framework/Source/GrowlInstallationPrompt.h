//
//  GrowlInstallationPrompt.h
//  Growl
//
//  Created by Evan Schoenberg on 1/8/05.
//  Copyright 2005 The Growl Project. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface GrowlInstallationPrompt : NSWindowController {
	IBOutlet	NSTextView		*textView_growlInfo;
	IBOutlet	NSScrollView	*scrollView_growlInfo;

	IBOutlet	NSButton	*button_install;
	IBOutlet	NSButton	*button_cancel;
	IBOutlet	NSButton	*checkBox_dontAskAgain;
	
	BOOL isUpdate;
}

+ (void) showInstallationPromptForUpdate:(BOOL)inIsUpdate;

- (IBAction) installGrowl:(id)sender;
- (IBAction) cancel:(id)sender;
- (IBAction) dontAskAgain:(id)sender;

@end
