//
//  GrowlBubblesPrefsController.m
//  Growl
//
//  Created by Kevin Ballard on 9/7/04.
//  Copyright 2004 TildeSoft. All rights reserved.
//

#import "GrowlBubblesPrefsController.h"
#import "GrowlBubblesDefines.h"
#import "GrowlDefines.h"

@implementation GrowlBubblesPrefsController
- (NSString *) mainNibName {
	return @"BubblesPrefs";
}

- (void) mainViewDidLoad {
	BOOL limitPref = YES;
	READ_GROWL_PREF_BOOL(KALimitPref, GrowlBubblesPrefDomain, &limitPref);
	if (limitPref) {
		[limitCheck setState:NSOnState];
	} else {
		[limitCheck setState:NSOffState];
	}
	
	// priority colour settings
	NSArray *array = nil;
	NSColor *color;
	
	READ_GROWL_PREF_VALUE(GrowlBubblesVeryLowColor, GrowlBubblesPrefDomain, CFArrayRef, (CFArrayRef*)&array);
	color = [NSColor colorWithCalibratedRed: .69412f green:.83147f blue:.96078f alpha:.95f];
	if (array) {
		color = [NSColor colorWithCalibratedRed:[[array objectAtIndex:0] floatValue]
										  green:[[array objectAtIndex:1] floatValue]
										   blue:[[array objectAtIndex:2] floatValue]
										  alpha:1.0f];
		[array release];
		array = nil;
	}
	[color_veryLow setColor:color];
	
	READ_GROWL_PREF_VALUE(GrowlBubblesModerateColor, GrowlBubblesPrefDomain, CFArrayRef, (CFArrayRef*)&array);
	color = [NSColor colorWithCalibratedRed: .69412f green:.83147f blue:.96078f alpha:.95f];
	if (array) {
		color = [NSColor colorWithCalibratedRed:[[array objectAtIndex:0] floatValue]
										  green:[[array objectAtIndex:1] floatValue]
										   blue:[[array objectAtIndex:2] floatValue]
										  alpha:1.0f];
		[array release];
		array = nil;
	}
	[color_moderate setColor:color];
	
	READ_GROWL_PREF_VALUE(GrowlBubblesNormalColor, GrowlBubblesPrefDomain, CFArrayRef, (CFArrayRef*)&array);
	color = [NSColor colorWithCalibratedRed: .69412f green:.83147f blue:.96078f alpha:.95f];
	if (array) {
		color = [NSColor colorWithCalibratedRed:[[array objectAtIndex:0] floatValue]
										  green:[[array objectAtIndex:1] floatValue]
										   blue:[[array objectAtIndex:2] floatValue]
										  alpha:1.0f];
		[array release];
		array = nil;
	}
	[color_normal setColor:color];

	READ_GROWL_PREF_VALUE(GrowlBubblesHighColor, GrowlBubblesPrefDomain, CFArrayRef, (CFArrayRef*)&array);
	color = [NSColor colorWithCalibratedRed: .69412f green:.83147f blue:.96078f alpha:.95f];
	if (array) {
		color = [NSColor colorWithCalibratedRed:[[array objectAtIndex:0] floatValue]
										  green:[[array objectAtIndex:1] floatValue]
										   blue:[[array objectAtIndex:2] floatValue]
										  alpha:1.0f];
		[array release];
		array = nil;
	}
	[color_high setColor:color];
	
	READ_GROWL_PREF_VALUE(GrowlBubblesEmergencyColor, GrowlBubblesPrefDomain, CFArrayRef, (CFArrayRef*)&array);
	color = [NSColor colorWithCalibratedRed: .69412f green:.83147f blue:.96078f alpha:.95f];
	if (array) {
		color = [NSColor colorWithCalibratedRed:[[array objectAtIndex:0] floatValue]
										  green:[[array objectAtIndex:1] floatValue]
										   blue:[[array objectAtIndex:2] floatValue]
										  alpha:1.0f];
		[array release];
		array = nil;
	}
	[color_emergency setColor:color];
	
	READ_GROWL_PREF_VALUE(GrowlBubblesVeryLowTextColor, GrowlBubblesPrefDomain, CFArrayRef, (CFArrayRef*)&array);
	color = [NSColor controlTextColor];
	if (array) {
		color = [NSColor colorWithCalibratedRed:[[array objectAtIndex:0] floatValue]
										  green:[[array objectAtIndex:1] floatValue]
										   blue:[[array objectAtIndex:2] floatValue]
										  alpha:1.0f];
		[array release];
		array = nil;
	}
	[text_veryLow setColor:color];
	
	READ_GROWL_PREF_VALUE(GrowlBubblesModerateTextColor, GrowlBubblesPrefDomain, CFArrayRef, (CFArrayRef*)&array);
	color = [NSColor controlTextColor];
	if (array) {
		color = [NSColor colorWithCalibratedRed:[[array objectAtIndex:0] floatValue]
										  green:[[array objectAtIndex:1] floatValue]
										   blue:[[array objectAtIndex:2] floatValue]
										  alpha:1.0f];
		[array release];
		array = nil;
	}
	[text_moderate setColor:color];
	
	READ_GROWL_PREF_VALUE(GrowlBubblesNormalTextColor, GrowlBubblesPrefDomain, CFArrayRef, (CFArrayRef*)&array);
	color = [NSColor controlTextColor];
	if (array) {
		color = [NSColor colorWithCalibratedRed:[[array objectAtIndex:0] floatValue]
										  green:[[array objectAtIndex:1] floatValue]
										   blue:[[array objectAtIndex:2] floatValue]
										  alpha:1.0f];
		[array release];
		array = nil;
	}
	[text_normal setColor:color];
	
	READ_GROWL_PREF_VALUE(GrowlBubblesHighTextColor, GrowlBubblesPrefDomain, CFArrayRef, (CFArrayRef*)&array);
	color = [NSColor controlTextColor];
	if (array) {
		color = [NSColor colorWithCalibratedRed:[[array objectAtIndex:0] floatValue]
										  green:[[array objectAtIndex:1] floatValue]
										   blue:[[array objectAtIndex:2] floatValue]
										  alpha:1.0f];
		[array release];
		array = nil;
	}
	[text_high setColor:color];

	READ_GROWL_PREF_VALUE(GrowlBubblesEmergencyTextColor, GrowlBubblesPrefDomain, CFArrayRef, (CFArrayRef*)&array);
	color = [NSColor controlTextColor];
	if (array) {
		color = [NSColor colorWithCalibratedRed:[[array objectAtIndex:0] floatValue]
										  green:[[array objectAtIndex:1] floatValue]
										   blue:[[array objectAtIndex:2] floatValue]
										  alpha:1.0f];
		[array release];
		array = nil;
	}
	[text_emergency setColor:color];
}

- (IBAction) setLimit:(id)sender {
	WRITE_GROWL_PREF_BOOL(KALimitPref, ([sender state] == NSOnState), GrowlBubblesPrefDomain);
	UPDATE_GROWL_PREFS();
}

- (IBAction) colorChanged:(id)sender {

	NSColor *color;
    NSArray *array;
    
    NSString* key;
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
        [NSNumber numberWithFloat:[color blueComponent]], nil];
    WRITE_GROWL_PREF_VALUE(key, (CFArrayRef)array, GrowlBubblesPrefDomain);

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
        [NSNumber numberWithFloat:[color blueComponent]], nil];
    WRITE_GROWL_PREF_VALUE(key, (CFArrayRef)array, GrowlBubblesPrefDomain);

	//NSLog(@"color: %@ array: %@", color, array);
	
    SYNCHRONIZE_GROWL_PREFS();
    UPDATE_GROWL_PREFS();
}

@end
