//
//  GrowlSmokePrefsController.m
//  Display Plugins
//
//  Created by Matthew Walton on 11/09/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "GrowlSmokePrefsController.h"
#import "GrowlSmokeDefines.h"
#import "GrowlDefines.h"


@implementation GrowlSmokePrefsController

- (NSString *) mainNibName {
	return @"SmokePrefs";
}

- (void) mainViewDidLoad {
	// opacity
	float alphaPref = GrowlSmokeAlphaPrefDefault;
	READ_GROWL_PREF_FLOAT(GrowlSmokeAlphaPref, GrowlSmokePrefDomain, &alphaPref);
	[opacitySlider setMinValue:0.05];
	[opacitySlider setFloatValue:alphaPref];
	[text_Opacity setStringValue:[NSString stringWithFormat:@"%d%%",(int)floorf(alphaPref * 100.0f)]];
  
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

	READ_GROWL_PREF_VALUE(GrowlSmokeVeryLowColor, GrowlSmokePrefDomain, CFArrayRef, (CFArrayRef*)&array);
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
	
	READ_GROWL_PREF_VALUE(GrowlSmokeModerateColor, GrowlSmokePrefDomain, CFArrayRef, (CFArrayRef*)&array);
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
	
	READ_GROWL_PREF_VALUE(GrowlSmokeNormalColor, GrowlSmokePrefDomain, CFArrayRef, (CFArrayRef*)&array);
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
	
	READ_GROWL_PREF_VALUE(GrowlSmokeHighColor, GrowlSmokePrefDomain, CFArrayRef, (CFArrayRef*)&array);
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
	
	READ_GROWL_PREF_VALUE(GrowlSmokeEmergencyColor, GrowlSmokePrefDomain, CFArrayRef, (CFArrayRef*)&array);
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

	defaultColor = [NSColor colorWithCalibratedWhite:1.0f alpha:1.0f];

	READ_GROWL_PREF_VALUE(GrowlSmokeVeryLowTextColor, GrowlSmokePrefDomain, CFArrayRef, (CFArrayRef*)&array);
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
	
	READ_GROWL_PREF_VALUE(GrowlSmokeModerateTextColor, GrowlSmokePrefDomain, CFArrayRef, (CFArrayRef*)&array);
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
	
	READ_GROWL_PREF_VALUE(GrowlSmokeNormalTextColor, GrowlSmokePrefDomain, CFArrayRef, (CFArrayRef*)&array);
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
	
	READ_GROWL_PREF_VALUE(GrowlSmokeHighTextColor, GrowlSmokePrefDomain, CFArrayRef, (CFArrayRef*)&array);
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
	
	READ_GROWL_PREF_VALUE(GrowlSmokeEmergencyTextColor, GrowlSmokePrefDomain, CFArrayRef, (CFArrayRef*)&array);
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

- (IBAction) opacitySliderChanged:(id)sender {
	float newValue = [opacitySlider floatValue];
	WRITE_GROWL_PREF_FLOAT(GrowlSmokeAlphaPref, newValue, GrowlSmokePrefDomain);
	[text_Opacity setStringValue:[NSString stringWithFormat:@"%d%%",(int)floorf(newValue * 100.0f)]];
	SYNCHRONIZE_GROWL_PREFS();
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

    SYNCHRONIZE_GROWL_PREFS();
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
	
    SYNCHRONIZE_GROWL_PREFS();
    UPDATE_GROWL_PREFS();
}

-(IBAction) floatIconSwitchChanged:(id)sender {
	BOOL pref = ([floatIconSwitch state] == NSOnState);
	WRITE_GROWL_PREF_BOOL(GrowlSmokeFloatIconPref, pref, GrowlSmokePrefDomain);	
	SYNCHRONIZE_GROWL_PREFS();
	UPDATE_GROWL_PREFS();
}

- (IBAction) setLimit:(id)sender {
	WRITE_GROWL_PREF_BOOL(GrowlSmokeLimitPref, ([sender state] == NSOnState), GrowlSmokePrefDomain);
	UPDATE_GROWL_PREFS();
}

@end
