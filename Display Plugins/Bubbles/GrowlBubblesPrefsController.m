//
//  GrowlBubblesPrefsController.m
//  Growl
//
//  Created by Kevin Ballard on 9/7/04.
//  Copyright 2004 TildeSoft. All rights reserved.
//

#import "GrowlBubblesPrefsController.h"
#import "GrowlBubblesDefines.h"
#import "GrowlDefinesInternal.h"

@implementation GrowlBubblesPrefsController
- (NSString *) mainNibName {
	return @"BubblesPrefs";
}

- (void) mainViewDidLoad {
	BOOL limitPref = YES;
	READ_GROWL_PREF_BOOL(KALimitPref, GrowlBubblesPrefDomain, &limitPref);
	[limitCheck setState:(limitPref ? NSOnState : NSOffState)];
	
	// priority colour settings
	NSArray *array = nil;
	NSColor *color;
	float alpha;
	float opacityPref = 0.95f;

	READ_GROWL_PREF_FLOAT(GrowlBubblesOpacity, GrowlBubblesPrefDomain, &opacityPref);
	[slider_Opacity setFloatValue:opacityPref];
	[text_Opacity setStringValue:[NSString stringWithFormat:@"%d%%",(int)floorf(opacityPref * 100.0f)]];

	NSColor *defaultColor = [NSColor colorWithCalibratedRed:0.69412f green:0.83147f blue:0.96078f alpha:1.0f];

	READ_GROWL_PREF_VALUE(GrowlBubblesVeryLowColor, GrowlBubblesPrefDomain, NSArray *, &array);
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

	READ_GROWL_PREF_VALUE(GrowlBubblesModerateColor, GrowlBubblesPrefDomain, NSArray *, &array);
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
	[color_moderate setColor:color];
	
	READ_GROWL_PREF_VALUE(GrowlBubblesNormalColor, GrowlBubblesPrefDomain, NSArray *, &array);
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

	READ_GROWL_PREF_VALUE(GrowlBubblesHighColor, GrowlBubblesPrefDomain, NSArray *, &array);
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
	
	READ_GROWL_PREF_VALUE(GrowlBubblesEmergencyColor, GrowlBubblesPrefDomain, NSArray *, &array);
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
	[color_emergency setColor:color];

	defaultColor = [NSColor controlTextColor];	

	READ_GROWL_PREF_VALUE(GrowlBubblesVeryLowTextColor, GrowlBubblesPrefDomain, NSArray *, &array);
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
	
	READ_GROWL_PREF_VALUE(GrowlBubblesModerateTextColor, GrowlBubblesPrefDomain, NSArray *, &array);
	color = [NSColor controlTextColor];
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
	
	READ_GROWL_PREF_VALUE(GrowlBubblesNormalTextColor, GrowlBubblesPrefDomain, NSArray *, &array);
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
	
	READ_GROWL_PREF_VALUE(GrowlBubblesHighTextColor, GrowlBubblesPrefDomain, NSArray *, &array);
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

	READ_GROWL_PREF_VALUE(GrowlBubblesEmergencyTextColor, GrowlBubblesPrefDomain, NSArray *, &array);
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

- (IBAction) setLimit:(id)sender {
	WRITE_GROWL_PREF_BOOL(KALimitPref, ([sender state] == NSOnState), GrowlBubblesPrefDomain);
    SYNCHRONIZE_GROWL_PREFS();
	UPDATE_GROWL_PREFS();
}

- (IBAction) opacityChanged:(id)sender {
	float opacityPref = [slider_Opacity floatValue];
	[text_Opacity setStringValue:[NSString stringWithFormat:@"%d%%",(int)floorf(opacityPref * 100.0f)]];
	WRITE_GROWL_PREF_FLOAT(GrowlBubblesOpacity, opacityPref, GrowlBubblesPrefDomain);
    SYNCHRONIZE_GROWL_PREFS();
	UPDATE_GROWL_PREFS();
}

- (IBAction) colorChanged:(id)sender {

	NSColor *color;
    NSArray *array;

    NSString *key;
    switch ([sender tag]) {
        case -2:
            key = GrowlBubblesVeryLowColor;
            break;
        case -1:
            key = GrowlBubblesModerateColor;
            break;
        case 1:
            key = GrowlBubblesHighColor;
            break;
        case 2:
            key = GrowlBubblesEmergencyColor;
            break;
        case 0:
        default:
            key = GrowlBubblesNormalColor;
            break;
    }

    color = [[sender color] colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
    array = [NSArray arrayWithObjects:
        [NSNumber numberWithFloat:[color redComponent]],
        [NSNumber numberWithFloat:[color greenComponent]],
        [NSNumber numberWithFloat:[color blueComponent]],
        [NSNumber numberWithFloat:[color alphaComponent]],
		nil];
    WRITE_GROWL_PREF_VALUE(key, array, GrowlBubblesPrefDomain);

	//NSLog(@"color: %@ array: %@", color, array);

    SYNCHRONIZE_GROWL_PREFS();
    UPDATE_GROWL_PREFS();
}

- (IBAction) textColorChanged:(id)sender
{	
	NSColor *color;
    NSArray *array;

    NSString* key;
    switch ([sender tag]) {
        case -2:
            key = GrowlBubblesVeryLowTextColor;
            break;
        case -1:
            key = GrowlBubblesModerateTextColor;
            break;
        case 1:
            key = GrowlBubblesHighTextColor;
            break;
        case 2:
            key = GrowlBubblesEmergencyTextColor;
            break;
        case 0:
        default:
            key = GrowlBubblesNormalTextColor;
            break;
    }

    color = [[sender color] colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
	array = [NSArray arrayWithObjects:
        [NSNumber numberWithFloat:[color redComponent]],
        [NSNumber numberWithFloat:[color greenComponent]],
        [NSNumber numberWithFloat:[color blueComponent]],
		nil];
    WRITE_GROWL_PREF_VALUE(key, array, GrowlBubblesPrefDomain);

	//NSLog(@"color: %@ array: %@", color, array);

    SYNCHRONIZE_GROWL_PREFS();
    UPDATE_GROWL_PREFS();
}

@end
