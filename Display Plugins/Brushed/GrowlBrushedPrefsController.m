//
//  GrowlBrushedPrefsController.m
//  Display Plugins
//
//  Created by Ingmar Stein on 12/01/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "GrowlBrushedPrefsController.h"
#import "GrowlBrushedDefines.h"
#import "GrowlDefinesInternal.h"


@implementation GrowlBrushedPrefsController

- (NSString *) mainNibName {
	return @"BrushedPrefs";
}

- (void) mainViewDidLoad {
	// duration
	float durationPref = GrowlBrushedDurationPrefDefault;
	READ_GROWL_PREF_FLOAT(GrowlBrushedDurationPref, GrowlBrushedPrefDomain, &durationPref);
	[slider_duration setFloatValue:durationPref];
	[text_duration setStringValue:[NSString stringWithFormat:@"%.2f s", durationPref]];

	// float icon checkbox
	BOOL floatIconPref = GrowlBrushedFloatIconPrefDefault;
	READ_GROWL_PREF_BOOL(GrowlBrushedFloatIconPref, GrowlBrushedPrefDomain, &floatIconPref);
	if (floatIconPref) {
		[floatIconSwitch setState:NSOnState];
	} else {
		[floatIconSwitch setState:NSOffState];
	}

	// limit
	BOOL limitPref = GrowlBrushedLimitPrefDefault;
	READ_GROWL_PREF_BOOL(GrowlBrushedLimitPref, GrowlBrushedPrefDomain, &limitPref);
	if (limitPref) {
		[limitCheck setState:NSOnState];
	} else {
		[limitCheck setState:NSOffState];
	}

	// aqua
	BOOL aquaPref = GrowlBrushedAquaPrefDefault;
	READ_GROWL_PREF_BOOL(GrowlBrushedAquaPref, GrowlBrushedPrefDomain, &aquaPref);
	if (aquaPref) {
		[aquaCheck setState:NSOnState];
	} else {
		[aquaCheck setState:NSOffState];
	}
	
	// priority colour settings
	NSArray *array = nil;
	NSColor *color;
	NSColor *defaultColor = [NSColor colorWithCalibratedWhite:0.1f alpha:1.0f];
  	float alpha;

	READ_GROWL_PREF_VALUE(GrowlBrushedVeryLowTextColor, GrowlBrushedPrefDomain, CFArrayRef, (CFArrayRef*)&array);
	if (array) {
		alpha = ([array count] >= 4U) ? [[array objectAtIndex:3U] floatValue] : 1.0f;
		color = [NSColor colorWithCalibratedRed:[[array objectAtIndex:0] floatValue]
										  green:[[array objectAtIndex:1] floatValue]
										   blue:[[array objectAtIndex:2] floatValue]
										  alpha:alpha];
		[array release];
		array = nil;
	} else {
		color = defaultColor;
	}
	[text_veryLow setColor:color];
	
	READ_GROWL_PREF_VALUE(GrowlBrushedModerateTextColor, GrowlBrushedPrefDomain, CFArrayRef, (CFArrayRef*)&array);
	if (array) {
		alpha = ([array count] >= 4U) ? [[array objectAtIndex:3U] floatValue] : 1.0f;
		color = [NSColor colorWithCalibratedRed:[[array objectAtIndex:0] floatValue]
										  green:[[array objectAtIndex:1] floatValue]
										   blue:[[array objectAtIndex:2] floatValue]
										  alpha:alpha];
		[array release];
		array = nil;
	} else {
		color = defaultColor;
	}
	[text_moderate setColor:color];
	
	READ_GROWL_PREF_VALUE(GrowlBrushedNormalTextColor, GrowlBrushedPrefDomain, CFArrayRef, (CFArrayRef*)&array);
	if (array) {
		alpha = ([array count] >= 4U) ? [[array objectAtIndex:3U] floatValue] : 1.0f;
		color = [NSColor colorWithCalibratedRed:[[array objectAtIndex:0] floatValue]
										  green:[[array objectAtIndex:1] floatValue]
										   blue:[[array objectAtIndex:2] floatValue]
										  alpha:alpha];
		[array release];
		array = nil;
	} else {
		color = defaultColor;
	}
	[text_normal setColor:color];
	
	READ_GROWL_PREF_VALUE(GrowlBrushedHighTextColor, GrowlBrushedPrefDomain, CFArrayRef, (CFArrayRef*)&array);
	if (array) {
		alpha = ([array count] >= 4U) ? [[array objectAtIndex:3U] floatValue] : 1.0f;
		color = [NSColor colorWithCalibratedRed:[[array objectAtIndex:0] floatValue]
										  green:[[array objectAtIndex:1] floatValue]
										   blue:[[array objectAtIndex:2] floatValue]
										  alpha:alpha];
		[array release];
		array = nil;
	} else {
		color = defaultColor;
	}
	[text_high setColor:color];
	
	READ_GROWL_PREF_VALUE(GrowlBrushedEmergencyTextColor, GrowlBrushedPrefDomain, CFArrayRef, (CFArrayRef*)&array);
	if (array) {
		alpha = ([array count] >= 4U) ? [[array objectAtIndex:3U] floatValue] : 1.0f;
		color = [NSColor colorWithCalibratedRed:[[array objectAtIndex:0] floatValue]
										  green:[[array objectAtIndex:1] floatValue]
										   blue:[[array objectAtIndex:2] floatValue]
										  alpha:alpha];
		[array release];
		array = nil;
	} else {
		color = defaultColor;
	}
	[text_emergency setColor:color];
}

- (IBAction) durationChanged:(id)sender {
	float newValue = [sender floatValue];
	WRITE_GROWL_PREF_FLOAT(GrowlBrushedDurationPref, newValue, GrowlBrushedPrefDomain);
	[text_duration setStringValue:[NSString stringWithFormat:@"%.2f s", newValue]];
	SYNCHRONIZE_GROWL_PREFS();
	UPDATE_GROWL_PREFS();
}

- (IBAction) textColorChanged:(id)sender {
    NSColor *color;
    NSArray *array;
    
    NSString* key;
    switch ([sender tag]) {
        case -2:
            key = GrowlBrushedVeryLowTextColor;
            break;
        case -1:
            key = GrowlBrushedModerateTextColor;
            break;
        case 1:
            key = GrowlBrushedHighTextColor;
            break;
        case 2:
            key = GrowlBrushedEmergencyTextColor;
            break;
        case 0:
        default:
            key = GrowlBrushedNormalTextColor;
            break;
    }

    color = [[sender color] colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
    array = [NSArray arrayWithObjects:
        [NSNumber numberWithFloat:[color redComponent]],
        [NSNumber numberWithFloat:[color greenComponent]],
        [NSNumber numberWithFloat:[color blueComponent]],
		[NSNumber numberWithFloat:[color alphaComponent]],
		nil];
    WRITE_GROWL_PREF_VALUE(key, (CFArrayRef)array, GrowlBrushedPrefDomain);

    // NSLog(@"color: %@ array: %@", color, array);
	
    SYNCHRONIZE_GROWL_PREFS();
    UPDATE_GROWL_PREFS();
}

- (IBAction) floatIconSwitchChanged:(id)sender {
	BOOL pref = ([sender state] == NSOnState);
	WRITE_GROWL_PREF_BOOL(GrowlBrushedFloatIconPref, pref, GrowlBrushedPrefDomain);	
	SYNCHRONIZE_GROWL_PREFS();
	UPDATE_GROWL_PREFS();
}

- (IBAction) setLimit:(id)sender {
	WRITE_GROWL_PREF_BOOL(GrowlBrushedLimitPref, ([sender state] == NSOnState), GrowlBrushedPrefDomain);
	SYNCHRONIZE_GROWL_PREFS();
	UPDATE_GROWL_PREFS();
}

- (IBAction) setAqua:(id)sender {
	BOOL pref = ([sender state] == NSOnState);
	WRITE_GROWL_PREF_BOOL(GrowlBrushedAquaPref, pref, GrowlBrushedPrefDomain);	
	SYNCHRONIZE_GROWL_PREFS();
	UPDATE_GROWL_PREFS();
}

@end
