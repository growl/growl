//
//  
//  Growl
//
//  Created by Kevin Ballard on 9/7/04.
//  Name changed from KABubblePrefsController.h by Justin Burns on Fri Nov 05 2004.
//	Adapted for iCal by Takumi Murayama on Thu Aug 17 2006.
//  Copyright 2004 TildeSoft. All rights reserved.
//

#import "GrowlPluginPreferencePane.h"

@interface GrowliCalPrefsController : GrowlPluginPreferencePane {
	IBOutlet NSPopUpButton	*overall_color;
	IBOutlet NSSlider		*slider_opacity;
}

@property (nonatomic, retain) NSString *colorLabel;
@property (nonatomic, retain) NSArray *colorNames;

- (CGFloat) duration;
- (void) setDuration:(CGFloat)value;
- (CGFloat) opacity;
- (void) setOpacity:(CGFloat)value;
- (BOOL) isLimit;
- (void) setLimit:(BOOL)value;
- (int) screen;
- (void) setScreen:(int)value;
- (int) size;
- (void) setSize:(int)value;

@end
