//
//  GrowlMusicVideoPrefs.h
//  Display Plugins
//
//  Created by Jorge Salvador Caffarena on 14/09/04.
//  Copyright 2004 Jorge Salvador Caffarena. All rights reserved.
//

#import <PreferencePanes/PreferencePanes.h>
#import "GrowlDefines.h"

#define MUSICVIDEO_OPACITY_PREF			@"Opacity"
#define MUSICVIDEO_DEFAULT_OPACITY		60

#define MUSICVIDEO_SIZE_PREF			@"Size"
#define MUSICVIDEO_SIZE_NORMAL			0
#define MUSICVIDEO_SIZE_HUGE			1

@interface GrowlMusicVideoPrefs : NSPreferencePane {
	IBOutlet NSMatrix		*radio_Size;
	IBOutlet NSSlider		*slider_Opacity;
	IBOutlet NSTextField	*text_Opacity;
}

- (IBAction)preferenceChanged:(id)sender;

@end
