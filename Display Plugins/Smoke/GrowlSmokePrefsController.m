//
//  GrowlSmokePrefsController.m
//  Display Plugins
//
//  Created by Matthew Walton on 11/09/2004.
//  Copyright 2004 The Growl Project. All rights reserved.
//

#import "GrowlSmokePrefsController.h"
#import "GrowlSmokeDefines.h"
#import "GrowlDefinesInternal.h"

@implementation GrowlSmokePrefsController

- (NSString *) mainNibName {
	return @"SmokePrefs";
}

- (void) loadColorWell:(NSColorWell *)colorWell fromKey:(NSString *)key defaultColor:(NSColor *)defaultColor {
	NSData *data = nil;
	NSColor *color;
	READ_GROWL_PREF_VALUE(key, GrowlSmokePrefDomain, NSData *, &data);
	if (data && [data isKindOfClass:[NSData class]]) {
		color = [NSUnarchiver unarchiveObjectWithData:data];
	} else {
		color = defaultColor;
	}
	[colorWell setColor:color];
	[data release];
}

- (void) mainViewDidLoad {
	[slider_opacity setAltIncrementValue:0.05];

	// opacity
	opacity = GrowlSmokeAlphaPrefDefault;
	READ_GROWL_PREF_FLOAT(GrowlSmokeAlphaPref, GrowlSmokePrefDomain, &opacity);
	[self setOpacity:opacity];

	// duration
	duration = GrowlSmokeDurationPrefDefault;
	READ_GROWL_PREF_FLOAT(GrowlSmokeDurationPref, GrowlSmokePrefDomain, &duration);
	[self setDuration:duration];

	// float icon checkbox
	floatingIcon = GrowlSmokeFloatIconPrefDefault;
	READ_GROWL_PREF_BOOL(GrowlSmokeFloatIconPref, GrowlSmokePrefDomain, &floatingIcon);
	[self setFloatingIcon:floatingIcon];

	// limit
	limit = GrowlSmokeLimitPrefDefault;
	READ_GROWL_PREF_BOOL(GrowlSmokeLimitPref, GrowlSmokePrefDomain, &limit);
	[self setLimit:limit];

	// priority colour settings
	NSColor *defaultColor = [NSColor colorWithCalibratedWhite:0.1f alpha:1.0f];

	[self loadColorWell:color_veryLow fromKey:GrowlSmokeVeryLowColor defaultColor:defaultColor];
	[self loadColorWell:color_moderate fromKey:GrowlSmokeModerateColor defaultColor:defaultColor];
	[self loadColorWell:color_normal fromKey:GrowlSmokeNormalColor defaultColor:defaultColor];
	[self loadColorWell:color_high fromKey:GrowlSmokeHighColor defaultColor:defaultColor];
	[self loadColorWell:color_emergency fromKey:GrowlSmokeEmergencyColor defaultColor:defaultColor];

	defaultColor = [NSColor whiteColor];

	[self loadColorWell:text_veryLow fromKey:GrowlSmokeVeryLowTextColor defaultColor:defaultColor];
	[self loadColorWell:text_moderate fromKey:GrowlSmokeModerateTextColor defaultColor:defaultColor];
	[self loadColorWell:text_normal fromKey:GrowlSmokeNormalTextColor defaultColor:defaultColor];
	[self loadColorWell:text_high fromKey:GrowlSmokeHighTextColor defaultColor:defaultColor];
	[self loadColorWell:text_emergency fromKey:GrowlSmokeEmergencyTextColor defaultColor:defaultColor];

	// screen number
	int screenNumber = 0;
	READ_GROWL_PREF_INT(GrowlSmokeScreenPref, GrowlSmokePrefDomain, &screenNumber);
	[combo_screen setIntValue:screenNumber];
}

- (float) getOpacity {
	return opacity;
}

- (void) setOpacity:(float)value {
	if (opacity != value) {
		opacity = value;
		WRITE_GROWL_PREF_FLOAT(GrowlSmokeAlphaPref, value, GrowlSmokePrefDomain);
		UPDATE_GROWL_PREFS();
	}
}

- (float) getDuration {
	return duration;
}

- (void) setDuration:(float)value {
	if (duration != value) {
		duration = value;
		WRITE_GROWL_PREF_FLOAT(GrowlSmokeDurationPref, value, GrowlSmokePrefDomain);
		UPDATE_GROWL_PREFS();
	}
}

- (IBAction) colorChanged:(id)sender {
	NSString *key;
	switch ([sender tag]) {
		case -2:
			key = GrowlSmokeVeryLowColor;
			break;
		case -1:
			key = GrowlSmokeModerateColor;
			break;
		case 1:
			key = GrowlSmokeHighColor;
			break;
		case 2:
			key = GrowlSmokeEmergencyColor;
			break;
		case 0:
		default:
			key = GrowlSmokeNormalColor;
			break;
	}

	NSData *theData = [NSArchiver archivedDataWithRootObject:[sender color]];
	WRITE_GROWL_PREF_VALUE(key, theData, GrowlSmokePrefDomain);
	UPDATE_GROWL_PREFS();
}

- (IBAction) textColorChanged:(id)sender {
	NSString *key;
	switch ([sender tag]) {
		case -2:
			key = GrowlSmokeVeryLowTextColor;
			break;
		case -1:
			key = GrowlSmokeModerateTextColor;
			break;
		case 1:
			key = GrowlSmokeHighTextColor;
			break;
		case 2:
			key = GrowlSmokeEmergencyTextColor;
			break;
		case 0:
		default:
			key = GrowlSmokeNormalTextColor;
			break;
	}

	NSData *theData = [NSArchiver archivedDataWithRootObject:[sender color]];
	WRITE_GROWL_PREF_VALUE(key, theData, GrowlSmokePrefDomain);
	UPDATE_GROWL_PREFS();
}

- (BOOL) isFloatingIcon {
	return floatingIcon;
}

- (void) setFloatingIcon:(BOOL)value {
	if (floatingIcon != value) {
		floatingIcon = value;
		WRITE_GROWL_PREF_BOOL(GrowlSmokeFloatIconPref, value, GrowlSmokePrefDomain);	
		UPDATE_GROWL_PREFS();
	}
}

- (BOOL) getLimit {
	return limit;
}

- (void) setLimit:(BOOL)value {
	if (limit != value) {
		limit = value;
		WRITE_GROWL_PREF_BOOL(GrowlSmokeLimitPref, value, GrowlSmokePrefDomain);
		UPDATE_GROWL_PREFS();
	}
}

- (int) numberOfItemsInComboBox:(NSComboBox *)aComboBox {
	return [[NSScreen screens] count];
}

- (id) comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(int)idx {
	return [NSNumber numberWithInt:idx];
}

- (IBAction) setScreen:(id)sender {
	int pref = [sender intValue];
	WRITE_GROWL_PREF_INT(GrowlSmokeScreenPref, pref, GrowlSmokePrefDomain);	
	UPDATE_GROWL_PREFS();
}

@end
