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
	NSArray *array = nil;
	NSColor *color;
	READ_GROWL_PREF_VALUE(key, GrowlSmokePrefDomain, NSArray *, &array);
	if (array) {
		float alpha = ([array count] >= 4U) ? [[array objectAtIndex:3U] floatValue] : 1.0f;
		color = [NSColor colorWithCalibratedRed:[[array objectAtIndex:0U] floatValue]
										  green:[[array objectAtIndex:1U] floatValue]
										   blue:[[array objectAtIndex:2U] floatValue]
										  alpha:alpha];
		[array release];
	} else {
		color = defaultColor;
	}
	[colorWell setColor:color];
}

- (void) mainViewDidLoad {
	[slider_opacity setAltIncrementValue:0.05];

	// opacity
	float alphaPref = GrowlSmokeAlphaPrefDefault;
	READ_GROWL_PREF_FLOAT(GrowlSmokeAlphaPref, GrowlSmokePrefDomain, &alphaPref);
	[slider_opacity setFloatValue:alphaPref];
	[text_opacity setStringValue:[NSString stringWithFormat:@"%d%%", (int)floorf(alphaPref * 100.0f)]];

	// duration
	duration = GrowlSmokeDurationPrefDefault;
	READ_GROWL_PREF_FLOAT(GrowlSmokeDurationPref, GrowlSmokePrefDomain, &duration);
	[self setDuration:duration];

	// float icon checkbox
	BOOL floatIconPref = GrowlSmokeFloatIconPrefDefault;
	READ_GROWL_PREF_BOOL(GrowlSmokeFloatIconPref, GrowlSmokePrefDomain, &floatIconPref);
	if (floatIconPref) {
		[floatIconSwitch setState:NSOnState];
	} else {
		[floatIconSwitch setState:NSOffState];
	}

	// limit
	BOOL limitPref = GrowlSmokeLimitPrefDefault;
	READ_GROWL_PREF_BOOL(GrowlSmokeLimitPref, GrowlSmokePrefDomain, &limitPref);
	if (limitPref) {
		[limitCheck setState:NSOnState];
	} else {
		[limitCheck setState:NSOffState];
	}

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

- (IBAction) opacityChanged:(id)sender {
	float newValue = [sender floatValue];
	WRITE_GROWL_PREF_FLOAT(GrowlSmokeAlphaPref, newValue, GrowlSmokePrefDomain);
	[text_opacity setStringValue:[NSString stringWithFormat:@"%d%%", (int)floorf(newValue * 100.0f)]];
	UPDATE_GROWL_PREFS();
}

- (float) getDuration {
	return duration;
}

- (void) setDuration:(float)value {
	if (duration != value) {
		WRITE_GROWL_PREF_FLOAT(GrowlSmokeDurationPref, value, GrowlSmokePrefDomain);
		UPDATE_GROWL_PREFS();
	}
	duration = value;
}

- (IBAction) colorChanged:(id)sender {

	NSColor *color;
	NSArray *array;

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

	color = [[sender color] colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
	array = [[NSArray alloc] initWithObjects:
		[NSNumber numberWithFloat:[color redComponent]],
		[NSNumber numberWithFloat:[color greenComponent]],
		[NSNumber numberWithFloat:[color blueComponent]],
		[NSNumber numberWithFloat:[color alphaComponent]],
		nil];
	WRITE_GROWL_PREF_VALUE(key, array, GrowlSmokePrefDomain);
	[array release];

	// NSLog(@"color: %@ array: %@", color, array);

	UPDATE_GROWL_PREFS();
}

- (IBAction) textColorChanged:(id)sender {
	NSColor *color;
	NSArray *array;

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

	color = [[sender color] colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
	array = [[NSArray alloc] initWithObjects:
		[NSNumber numberWithFloat:[color redComponent]],
		[NSNumber numberWithFloat:[color greenComponent]],
		[NSNumber numberWithFloat:[color blueComponent]],
		[NSNumber numberWithFloat:[color alphaComponent]],
		nil];
	WRITE_GROWL_PREF_VALUE(key, array, GrowlSmokePrefDomain);
	[array release];

	// NSLog(@"color: %@ array: %@", color, array);

	UPDATE_GROWL_PREFS();
}

- (IBAction) floatIconSwitchChanged:(id)sender {
	BOOL pref = ([floatIconSwitch state] == NSOnState);
	WRITE_GROWL_PREF_BOOL(GrowlSmokeFloatIconPref, pref, GrowlSmokePrefDomain);	
	UPDATE_GROWL_PREFS();
}

- (IBAction) setLimit:(id)sender {
	WRITE_GROWL_PREF_BOOL(GrowlSmokeLimitPref, ([sender state] == NSOnState), GrowlSmokePrefDomain);
	UPDATE_GROWL_PREFS();
}

- (int)numberOfItemsInComboBox:(NSComboBox *)aComboBox {
	return [[NSScreen screens] count];
}

- (id)comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(int)idx {
	return [NSNumber numberWithInt:idx];
}

- (IBAction) setScreen:(id)sender {
	int pref = [sender intValue];
	WRITE_GROWL_PREF_INT(GrowlSmokeScreenPref, pref, GrowlSmokePrefDomain);	
	UPDATE_GROWL_PREFS();
}

@end
