//
//  GrowlWebKitPrefsController.h
//  Growl
//
//  Created by Kevin Ballard on 9/7/04.
//  Name changed from KABubblePrefsController.h by Justin Burns on Fri Nov 05 2004.
//  Copyright 2004 TildeSoft. All rights reserved.
//

#import <PreferencePanes/PreferencePanes.h>

@interface GrowlWebKitPrefsController : NSPreferencePane {
	IBOutlet NSSlider		*slider_opacity;
}
- (float) duration;
- (void) setDuration:(float)value;
- (float) opacity;
- (void) setOpacity:(float)value;
- (BOOL) isLimit;
- (void) setLimit:(BOOL)value;
- (int) screen;
- (void) setScreen:(int)value;
- (int) size;
- (void) setSize:(int)value;

@end
