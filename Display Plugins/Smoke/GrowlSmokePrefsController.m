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
	[text_Opacity setStringValue:[NSString stringWithFormat:@"%d%%",(int)floor(alphaPref * 100.)]];
  
	// float icon checkbox
	bool floatIconPref = GrowlSmokeFloatIconPrefDefault;
	READ_GROWL_PREF_BOOL(GrowlSmokeFloatIconPref, GrowlSmokePrefDomain, &floatIconPref);
	if(floatIconPref) {
		[floatIconSwitch setState:NSOnState];
	} else {
		[floatIconSwitch setState:NSOffState];
	}
  
	// priority colour settings
	NSArray *array = nil;
	NSColor *color;
  
	READ_GROWL_PREF_VALUE(GrowlSmokeVeryLowColor, GrowlSmokePrefDomain, CFArrayRef, (CFArrayRef*)&array);
	color = [NSColor colorWithCalibratedWhite:.1 alpha:1.0];
	if (array) {
		color = [NSColor colorWithCalibratedRed:[[array objectAtIndex:0] floatValue]
										  green:[[array objectAtIndex:1] floatValue]
										   blue:[[array objectAtIndex:2] floatValue]
										  alpha:1.0];
		[array release];
		array = nil;
	}
	[color_veryLow setColor:color];
	
	READ_GROWL_PREF_VALUE(GrowlSmokeModerateColor, GrowlSmokePrefDomain, CFArrayRef, (CFArrayRef*)&array);
	color = [NSColor colorWithCalibratedWhite:.1 alpha:1.0];
	if (array) {
		color = [NSColor colorWithCalibratedRed:[[array objectAtIndex:0] floatValue]
										  green:[[array objectAtIndex:1] floatValue]
										   blue:[[array objectAtIndex:2] floatValue]
										  alpha:1.0];
		[array release];
		array = nil;
	}
	[color_moderate setColor:color];
	
	READ_GROWL_PREF_VALUE(GrowlSmokeNormalColor, GrowlSmokePrefDomain, CFArrayRef, (CFArrayRef*)&array);
	color = [NSColor colorWithCalibratedWhite:.1 alpha:1.0];
	if (array) {
		color = [NSColor colorWithCalibratedRed:[[array objectAtIndex:0] floatValue]
										  green:[[array objectAtIndex:1] floatValue]
										   blue:[[array objectAtIndex:2] floatValue]
										  alpha:1.0];
		[array release];
		array = nil;
	}
	[color_normal setColor:color];
	
	READ_GROWL_PREF_VALUE(GrowlSmokeHighColor, GrowlSmokePrefDomain, CFArrayRef, (CFArrayRef*)&array);
	color = [NSColor colorWithCalibratedWhite:.1 alpha:1.0];
	if (array) {
		color = [NSColor colorWithCalibratedRed:[[array objectAtIndex:0] floatValue]
										  green:[[array objectAtIndex:1] floatValue]
										   blue:[[array objectAtIndex:2] floatValue]
										  alpha:1.0];
		[array release];
		array = nil;
	}
	[color_high setColor:color];
	
	READ_GROWL_PREF_VALUE(GrowlSmokeEmergencyColor, GrowlSmokePrefDomain, CFArrayRef, (CFArrayRef*)&array);
	color = [NSColor colorWithCalibratedWhite:.1 alpha:1.0];
	if (array) {
		color = [NSColor colorWithCalibratedRed:[[array objectAtIndex:0] floatValue]
										  green:[[array objectAtIndex:1] floatValue]
										   blue:[[array objectAtIndex:2] floatValue]
										  alpha:1.0];
		[array release];
		array = nil;
	}
	[color_emergency setColor:color];
}

- (IBAction) opacitySliderChanged:(id)sender {
	float newValue = [opacitySlider floatValue];
	WRITE_GROWL_PREF_FLOAT(GrowlSmokeAlphaPref, newValue, GrowlSmokePrefDomain);
	[text_Opacity setStringValue:[NSString stringWithFormat:@"%d%%",(int)floor(newValue * 100.)]];
	SYNCHRONIZE_GROWL_PREFS();
	UPDATE_GROWL_PREFS();
}

- (IBAction) colorChanged:(id)sender {
    
    NSColor *color;
    NSArray *array;
    
    NSString* key;
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
    
    color = [sender color];
    array = [NSArray arrayWithObjects:
        [NSNumber numberWithFloat:[color redComponent]],
        [NSNumber numberWithFloat:[color greenComponent]],
        [NSNumber numberWithFloat:[color blueComponent]], nil];
    WRITE_GROWL_PREF_VALUE(key, (CFArrayRef)array, GrowlSmokePrefDomain);

    // NSLog(@"color: %@ array: %@", color, array);

    SYNCHRONIZE_GROWL_PREFS();
    UPDATE_GROWL_PREFS();
}

-(IBAction)floatIconSwitchChanged:(id)sender {
	int state = [floatIconSwitch state];
	BOOL pref = NO;
	switch(state) {
		case NSOnState:
			pref = YES;
			break;
		case NSOffState:
			pref = NO;
			break;
		default:
			pref = NO;
			break;
	}
	WRITE_GROWL_PREF_BOOL(GrowlSmokeFloatIconPref, pref, GrowlSmokePrefDomain);
	
	SYNCHRONIZE_GROWL_PREFS();
	UPDATE_GROWL_PREFS();
}

@end
