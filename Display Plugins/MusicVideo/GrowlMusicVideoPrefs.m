//
//  GrowlMusicVideoPrefs.m
//  Display Plugins
//
//  Created by Jorge Salvador Caffarena on 14/09/04.
//  Copyright 2004 Jorge Salvador Caffarena. All rights reserved.
//

#import "GrowlMusicVideoPrefs.h"
#import <GrowlDefinesInternal.h>

@implementation GrowlMusicVideoPrefs

- (NSString *) mainNibName {
	return @"GrowlMusicVideoPrefs";
}

- (void) mainViewDidLoad {
	[slider_opacity setAltIncrementValue:5.0];

	opacity = MUSICVIDEO_DEFAULT_OPACITY;
	READ_GROWL_PREF_FLOAT(MUSICVIDEO_OPACITY_PREF, MusicVideoPrefDomain, &opacity);
	[self setOpacity:opacity];

	size = 0;
	READ_GROWL_PREF_INT(MUSICVIDEO_SIZE_PREF, MusicVideoPrefDomain, &size);
	[self setSize:size];

	duration = MUSICVIDEO_DEFAULT_DURATION;
	READ_GROWL_PREF_FLOAT(MUSICVIDEO_DURATION_PREF, MusicVideoPrefDomain, &duration);
	[self setDuration:duration];

	int screenNumber = 0;
	READ_GROWL_PREF_INT(MUSICVIDEO_SCREEN_PREF, MusicVideoPrefDomain, &screenNumber);
	[combo_screen setIntValue:screenNumber];
}

- (void) didSelect {
	SYNCHRONIZE_GROWL_PREFS();
}

#pragma mark Accessors

- (float) duration {
	return duration;
}
- (void) setDuration:(float)value {
	if (duration != value) {
		duration = value;
		WRITE_GROWL_PREF_FLOAT(MUSICVIDEO_DURATION_PREF, value, MusicVideoPrefDomain);
		UPDATE_GROWL_PREFS();
	}
}

- (unsigned) effect {
	int effect = 0;
	READ_GROWL_PREF_INT(MUSICVIDEO_EFFECT_PREF, MusicVideoPrefDomain, &effect);
	switch(effect) {
		default:
			effect = MUSICVIDEO_EFFECT_SLIDE;

		case MUSICVIDEO_EFFECT_SLIDE:
		case MUSICVIDEO_EFFECT_WIPE:
			;
	}
	return (unsigned)effect;
}
- (void) setEffect:(unsigned)newEffect {
	switch(newEffect) {
		default:
			NSLog(@"(Music Video) Invalid effect number %u (slide is %u; wipe is %u)", newEffect, MUSICVIDEO_EFFECT_SLIDE, MUSICVIDEO_EFFECT_WIPE);
			break;

		case MUSICVIDEO_EFFECT_SLIDE:
		case MUSICVIDEO_EFFECT_WIPE:
			WRITE_GROWL_PREF_INT(MUSICVIDEO_EFFECT_PREF, newEffect, MusicVideoPrefDomain);
			UPDATE_GROWL_PREFS();
	}
}

- (float) opacity {
	return opacity;
}
- (void) setOpacity:(float)value {
	if (opacity != value) {
		opacity = value;
		WRITE_GROWL_PREF_FLOAT(MUSICVIDEO_OPACITY_PREF, value, MusicVideoPrefDomain);
		UPDATE_GROWL_PREFS();
	}
}

- (int) size {
	return size;
}
- (void) setSize:(int)value {
	if (size != value) {
		size = value;
		WRITE_GROWL_PREF_INT(MUSICVIDEO_SIZE_PREF, value, MusicVideoPrefDomain);
		UPDATE_GROWL_PREFS();
	}
}

#pragma mark Combo box support

- (int) numberOfItemsInComboBox:(NSComboBox *)aComboBox {
	return [[NSScreen screens] count];
}

- (id) comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(int)idx {
	return [NSNumber numberWithInt:idx];
}

- (IBAction) takeScreenAsIntValueFrom:(id)sender {
	int pref = [sender intValue];
	WRITE_GROWL_PREF_INT(MUSICVIDEO_SCREEN_PREF, pref, MusicVideoPrefDomain);	
	UPDATE_GROWL_PREFS();
}

@end
