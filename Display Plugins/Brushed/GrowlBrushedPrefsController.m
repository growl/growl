//
//  GrowlBrushedPrefsController.m
//  Display Plugins
//
//  Created by Ingmar Stein on 12/01/2004.
//  Copyright 2004-2005 The Growl Project. All rights reserved.
//

#import "GrowlBrushedPrefsController.h"
#import "GrowlBrushedDefines.h"
#import "GrowlDefinesInternal.h"


@implementation GrowlBrushedPrefsController

- (NSString *) mainNibName {
	return @"BrushedPrefs";
}

- (void) loadColorWell:(NSColorWell *)colorWell fromKey:(NSString *)key defaultColor:(NSColor *)defaultColor {
	NSArray *array = nil;
	NSColor *color;
	READ_GROWL_PREF_VALUE(key, GrowlBrushedPrefDomain, NSArray *, &array);
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
	NSColor *defaultColor = [NSColor colorWithCalibratedWhite:0.1f alpha:1.0f];

	[self loadColorWell:text_veryLow fromKey:GrowlBrushedVeryLowTextColor defaultColor:defaultColor];
	[self loadColorWell:text_moderate fromKey:GrowlBrushedModerateTextColor defaultColor:defaultColor];
	[self loadColorWell:text_normal fromKey:GrowlBrushedNormalTextColor defaultColor:defaultColor];
	[self loadColorWell:text_high fromKey:GrowlBrushedHighTextColor defaultColor:defaultColor];
	[self loadColorWell:text_emergency fromKey:GrowlBrushedEmergencyTextColor defaultColor:defaultColor];

	// screen number
	int screenNumber = 0;
	READ_GROWL_PREF_INT(GrowlBrushedScreenPref, GrowlBrushedPrefDomain, &screenNumber);
	[combo_screen setIntValue:screenNumber];
}

- (int)numberOfItemsInComboBox:(NSComboBox *)aComboBox {
	return [[NSScreen screens] count];
}

- (id)comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(int)idx {
	return [NSNumber numberWithInt:idx];
}

- (IBAction) durationChanged:(id)sender {
	float newValue = [sender floatValue];
	WRITE_GROWL_PREF_FLOAT(GrowlBrushedDurationPref, newValue, GrowlBrushedPrefDomain);
	[text_duration setStringValue:[NSString stringWithFormat:@"%.2f s", newValue]];
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
    WRITE_GROWL_PREF_VALUE(key, array, GrowlBrushedPrefDomain);

    // NSLog(@"color: %@ array: %@", color, array);
	
    UPDATE_GROWL_PREFS();
}

- (IBAction) floatIconSwitchChanged:(id)sender {
	BOOL pref = ([sender state] == NSOnState);
	WRITE_GROWL_PREF_BOOL(GrowlBrushedFloatIconPref, pref, GrowlBrushedPrefDomain);	
	UPDATE_GROWL_PREFS();
}

- (IBAction) setLimit:(id)sender {
	WRITE_GROWL_PREF_BOOL(GrowlBrushedLimitPref, ([sender state] == NSOnState), GrowlBrushedPrefDomain);
	UPDATE_GROWL_PREFS();
}

- (IBAction) setAqua:(id)sender {
	BOOL pref = ([sender state] == NSOnState);
	WRITE_GROWL_PREF_BOOL(GrowlBrushedAquaPref, pref, GrowlBrushedPrefDomain);	
	UPDATE_GROWL_PREFS();
}

- (IBAction) setScreen:(id)sender {
	int pref = [sender intValue];
	WRITE_GROWL_PREF_INT(GrowlBrushedScreenPref, pref, GrowlBrushedPrefDomain);	
	UPDATE_GROWL_PREFS();
}

@end
