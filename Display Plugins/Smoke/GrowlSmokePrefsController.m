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

- (void) mainViewDidLoad {
	// opacity
	float alphaPref = GrowlSmokeAlphaPrefDefault;
	READ_GROWL_PREF_FLOAT(GrowlSmokeAlphaPref, GrowlSmokePrefDomain, &alphaPref);
	[slider_opacity setMinValue:0.05];
	[slider_opacity setFloatValue:alphaPref];
	[text_opacity setStringValue:[NSString stringWithFormat:@"%d%%", (int)floorf(alphaPref * 100.0f)]];
  
	// duration
	float durationPref = GrowlSmokeDurationPrefDefault;
	READ_GROWL_PREF_FLOAT(GrowlSmokeDurationPref, GrowlSmokePrefDomain, &durationPref);
	[slider_duration setFloatValue:durationPref];
	[text_duration setStringValue:[NSString stringWithFormat:@"%.2f s", durationPref]];
	
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
	NSArray *array = nil;
	NSColor *color;
	NSColor *defaultColor = [NSColor colorWithCalibratedWhite:0.1f alpha:1.0f];
  	float alpha;

	READ_GROWL_PREF_VALUE(GrowlSmokeVeryLowColor, GrowlSmokePrefDomain, NSArray *, &array);
	if (array) {
		alpha = ([array count] >= 4U) ? [[array objectAtIndex:3U] floatValue] : 1.0f;
		color = [NSColor colorWithCalibratedRed:[[array objectAtIndex:0U] floatValue]
										  green:[[array objectAtIndex:1U] floatValue]
										   blue:[[array objectAtIndex:2U] floatValue]
										  alpha:alpha];
		[array release];
		array = nil;
	} else {
		color = defaultColor;
	}
	[color_veryLow setColor:color];
	
	READ_GROWL_PREF_VALUE(GrowlSmokeModerateColor, GrowlSmokePrefDomain, NSArray *, &array);
	if (array) {
		alpha = ([array count] >= 4U) ? [[array objectAtIndex:3U] floatValue] : 1.0f;
		color = [NSColor colorWithCalibratedRed:[[array objectAtIndex:0U] floatValue]
										  green:[[array objectAtIndex:1U] floatValue]
										   blue:[[array objectAtIndex:2U] floatValue]
										  alpha:alpha];
		[array release];
		array = nil;
	}
	[color_moderate setColor:color];
	
	READ_GROWL_PREF_VALUE(GrowlSmokeNormalColor, GrowlSmokePrefDomain, NSArray *, &array);
	if (array) {
		alpha = ([array count] >= 4U) ? [[array objectAtIndex:3U] floatValue] : 1.0f;
		color = [NSColor colorWithCalibratedRed:[[array objectAtIndex:0U] floatValue]
										  green:[[array objectAtIndex:1U] floatValue]
										   blue:[[array objectAtIndex:2U] floatValue]
										  alpha:alpha];
		[array release];
		array = nil;
	} else {
		color = defaultColor;
	}
	[color_normal setColor:color];
	
	READ_GROWL_PREF_VALUE(GrowlSmokeHighColor, GrowlSmokePrefDomain, NSArray *, &array);
	if (array) {
		alpha = ([array count] >= 4U) ? [[array objectAtIndex:3U] floatValue] : 1.0f;
		color = [NSColor colorWithCalibratedRed:[[array objectAtIndex:0U] floatValue]
										  green:[[array objectAtIndex:1U] floatValue]
										   blue:[[array objectAtIndex:2U] floatValue]
										  alpha:alpha];
		[array release];
		array = nil;
	} else {
		color = defaultColor;
	}
	[color_high setColor:color];
	
	READ_GROWL_PREF_VALUE(GrowlSmokeEmergencyColor, GrowlSmokePrefDomain, NSArray *, &array);
	if (array) {
		alpha = ([array count] >= 4U) ? [[array objectAtIndex:3U] floatValue] : 1.0f;
		color = [NSColor colorWithCalibratedRed:[[array objectAtIndex:0U] floatValue]
										  green:[[array objectAtIndex:1U] floatValue]
										   blue:[[array objectAtIndex:2U] floatValue]
										  alpha:alpha];
		[array release];
		array = nil;
	}
	[color_emergency setColor:color];

	defaultColor = [NSColor whiteColor];

	READ_GROWL_PREF_VALUE(GrowlSmokeVeryLowTextColor, GrowlSmokePrefDomain, NSArray *, &array);
	if (array) {
		alpha = ([array count] >= 4U) ? [[array objectAtIndex:3U] floatValue] : 1.0f;
		color = [NSColor colorWithCalibratedRed:[[array objectAtIndex:0U] floatValue]
										  green:[[array objectAtIndex:1U] floatValue]
										   blue:[[array objectAtIndex:2U] floatValue]
										  alpha:alpha];
		[array release];
		array = nil;
	} else {
		color = defaultColor;
	}
	[text_veryLow setColor:color];
	
	READ_GROWL_PREF_VALUE(GrowlSmokeModerateTextColor, GrowlSmokePrefDomain, NSArray *, &array);
	if (array) {
		alpha = ([array count] >= 4U) ? [[array objectAtIndex:3U] floatValue] : 1.0f;
		color = [NSColor colorWithCalibratedRed:[[array objectAtIndex:0U] floatValue]
										  green:[[array objectAtIndex:1U] floatValue]
										   blue:[[array objectAtIndex:2U] floatValue]
										  alpha:alpha];
		[array release];
		array = nil;
	} else {
		color = defaultColor;
	}
	[text_moderate setColor:color];
	
	READ_GROWL_PREF_VALUE(GrowlSmokeNormalTextColor, GrowlSmokePrefDomain, NSArray *, &array);
	if (array) {
		alpha = ([array count] >= 4U) ? [[array objectAtIndex:3U] floatValue] : 1.0f;
		color = [NSColor colorWithCalibratedRed:[[array objectAtIndex:0U] floatValue]
										  green:[[array objectAtIndex:1U] floatValue]
										   blue:[[array objectAtIndex:2U] floatValue]
										  alpha:alpha];
		[array release];
		array = nil;
	} else {
		color = defaultColor;
	}
	[text_normal setColor:color];
	
	READ_GROWL_PREF_VALUE(GrowlSmokeHighTextColor, GrowlSmokePrefDomain, NSArray *, &array);
	if (array) {
		alpha = ([array count] >= 4U) ? [[array objectAtIndex:3U] floatValue] : 1.0f;
		color = [NSColor colorWithCalibratedRed:[[array objectAtIndex:0U] floatValue]
										  green:[[array objectAtIndex:1U] floatValue]
										   blue:[[array objectAtIndex:2U] floatValue]
										  alpha:alpha];
		[array release];
		array = nil;
	} else {
		color = defaultColor;
	}
	[text_high setColor:color];
	
	READ_GROWL_PREF_VALUE(GrowlSmokeEmergencyTextColor, GrowlSmokePrefDomain, NSArray *, &array);
	if (array) {
		alpha = ([array count] >= 4U) ? [[array objectAtIndex:3U] floatValue] : 1.0f;
		color = [NSColor colorWithCalibratedRed:[[array objectAtIndex:0U] floatValue]
										  green:[[array objectAtIndex:1U] floatValue]
										   blue:[[array objectAtIndex:2U] floatValue]
										  alpha:alpha];
		[array release];
		array = nil;
	} else {
		color = defaultColor;
	}
	[text_emergency setColor:color];
}

- (IBAction) opacityChanged:(id)sender {
	float newValue = [sender floatValue];
	WRITE_GROWL_PREF_FLOAT(GrowlSmokeAlphaPref, newValue, GrowlSmokePrefDomain);
	[text_opacity setStringValue:[NSString stringWithFormat:@"%d%%", (int)floorf(newValue * 100.0f)]];
	UPDATE_GROWL_PREFS();
}

- (IBAction) durationChanged:(id)sender {
	float newValue = [sender floatValue];
	WRITE_GROWL_PREF_FLOAT(GrowlSmokeDurationPref, newValue, GrowlSmokePrefDomain);
	[text_duration setStringValue:[NSString stringWithFormat:@"%.2f s", newValue]];
	UPDATE_GROWL_PREFS();
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
	array = [NSArray arrayWithObjects:
		[NSNumber numberWithFloat:[color redComponent]],
		[NSNumber numberWithFloat:[color greenComponent]],
		[NSNumber numberWithFloat:[color blueComponent]],
		[NSNumber numberWithFloat:[color alphaComponent]],
		nil];
	WRITE_GROWL_PREF_VALUE(key, (CFArrayRef)array, GrowlSmokePrefDomain);

	// NSLog(@"color: %@ array: %@", color, array);

	UPDATE_GROWL_PREFS();
}

- (IBAction) textColorChanged:(id)sender
{
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
	array = [NSArray arrayWithObjects:
		[NSNumber numberWithFloat:[color redComponent]],
		[NSNumber numberWithFloat:[color greenComponent]],
		[NSNumber numberWithFloat:[color blueComponent]],
		[NSNumber numberWithFloat:[color alphaComponent]],
		nil];
	WRITE_GROWL_PREF_VALUE(key, (CFArrayRef)array, GrowlSmokePrefDomain);

	// NSLog(@"color: %@ array: %@", color, array);
	
	UPDATE_GROWL_PREFS();
}

-(IBAction) floatIconSwitchChanged:(id)sender {
	BOOL pref = ([floatIconSwitch state] == NSOnState);
	WRITE_GROWL_PREF_BOOL(GrowlSmokeFloatIconPref, pref, GrowlSmokePrefDomain);	
	UPDATE_GROWL_PREFS();
}

- (IBAction) setLimit:(id)sender {
	WRITE_GROWL_PREF_BOOL(GrowlSmokeLimitPref, ([sender state] == NSOnState), GrowlSmokePrefDomain);
	UPDATE_GROWL_PREFS();
}

@end
