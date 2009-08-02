//
//  GrowlWebKitPrefsController.h
//  Growl
//
//  Created by Ingmar Stein on Thu Apr 14 2005.
//  Copyright 2005-2006 The Growl Project. All rights reserved.
//

#import <PreferencePanes/PreferencePanes.h>

@interface GrowlWebKitPrefsController : NSPreferencePane {
	IBOutlet NSSlider		*slider_opacity;
	NSString				*style;
	NSString				*prefDomain;
}
- (id) initWithStyle:(NSString *)style;
- (CGFloat) duration;
- (void) setDuration:(CGFloat)value;
- (CGFloat) opacity;
- (void) setOpacity:(CGFloat)value;
- (BOOL) isLimit;
- (void) setLimit:(BOOL)value;
- (int) screen;
- (void) setScreen:(int)value;

@end
