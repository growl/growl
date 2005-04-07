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
}

- (void) didSelect {
	SYNCHRONIZE_GROWL_PREFS();
}

#pragma mark Accessors

- (float) duration {
	float value = MUSICVIDEO_DEFAULT_DURATION;
	READ_GROWL_PREF_FLOAT(MUSICVIDEO_DURATION_PREF, MusicVideoPrefDomain, &value);
	return value;
}
- (void) setDuration:(float)value {
	WRITE_GROWL_PREF_FLOAT(MUSICVIDEO_DURATION_PREF, value, MusicVideoPrefDomain);
	UPDATE_GROWL_PREFS();
}

- (unsigned) effect {
	int effect = 0;
	READ_GROWL_PREF_INT(MUSICVIDEO_EFFECT_PREF, MusicVideoPrefDomain, &effect);
	switch (effect) {
		default:
			effect = MUSICVIDEO_EFFECT_SLIDE;

		case MUSICVIDEO_EFFECT_SLIDE:
		case MUSICVIDEO_EFFECT_WIPE:
			;
	}
	return (unsigned)effect;
}
- (void) setEffect:(unsigned)newEffect {
	switch (newEffect) {
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
	float value = MUSICVIDEO_DEFAULT_OPACITY;
	READ_GROWL_PREF_FLOAT(MUSICVIDEO_OPACITY_PREF, MusicVideoPrefDomain, &value);
	return value;
}
- (void) setOpacity:(float)value {
	WRITE_GROWL_PREF_FLOAT(MUSICVIDEO_OPACITY_PREF, value, MusicVideoPrefDomain);
	UPDATE_GROWL_PREFS();
}

- (int) size {
	int value = 0;
	READ_GROWL_PREF_INT(MUSICVIDEO_SIZE_PREF, MusicVideoPrefDomain, &value);
	return value;
}
- (void) setSize:(int)value {
	WRITE_GROWL_PREF_INT(MUSICVIDEO_SIZE_PREF, value, MusicVideoPrefDomain);
	UPDATE_GROWL_PREFS();
}

#pragma mark Combo box support

- (int) numberOfItemsInComboBox:(NSComboBox *)aComboBox {
	return [[NSScreen screens] count];
}

- (id) comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(int)idx {
	return [NSNumber numberWithInt:idx];
}

- (int) screen {
	int value = 0;
	READ_GROWL_PREF_INT(MUSICVIDEO_SCREEN_PREF, MusicVideoPrefDomain, &value);
	return value;
}
- (void) setScreen:(int)value {
	WRITE_GROWL_PREF_INT(MUSICVIDEO_SCREEN_PREF, value, MusicVideoPrefDomain);	
	UPDATE_GROWL_PREFS();
}

@end
