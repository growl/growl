//
//  BubblePrefsController.h
//  Growl
//
//  Created by Kevin Ballard on 9/7/04.
//  Copyright 2004 TildeSoft. All rights reserved.
//

#define KALimitPref @"Bubbles - Limit"

@interface BubblePrefsController : NSObject {
	IBOutlet NSView *displayPrefView;
	
	IBOutlet NSButton *limitCheck;
}
- (IBAction) setLimit:(id)sender;
- (NSView *) displayPrefView;
@end
