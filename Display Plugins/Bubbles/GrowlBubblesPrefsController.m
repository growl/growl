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

- (void) loadColorWell:(NSColorWell *)colorWell fromKey:(NSString *)key defaultColor:(NSColor *)defaultColor {
	NSData *data = nil;
	NSColor *color;
	READ_GROWL_PREF_VALUE(key, GrowlBubblesPrefDomain, NSData *, &data);
	if (data && [data isKindOfClass:[NSData class]]) {
		color = [NSUnarchiver unarchiveObjectWithData:data];
	} else {
		color = defaultColor;
	}
	[colorWell setColor:color];
	[data release];
}

- (void) mainViewDidLoad {
	limit = YES;
	READ_GROWL_PREF_BOOL(KALimitPref, GrowlBubblesPrefDomain, &limit);
	[self setLimit:limit];
	
	[slider_opacity setAltIncrementValue:0.05];

	opacity = 95.0f;
	READ_GROWL_PREF_FLOAT(GrowlBubblesOpacity, GrowlBubblesPrefDomain, &opacity);
	[self setOpacity:opacity];

	duration = 4.0f;
	READ_GROWL_PREF_FLOAT(GrowlBubblesDuration, GrowlBubblesPrefDomain, &duration);
	[self setDuration:duration];

	// priority colour settings
	NSColor *defaultColor = [NSColor colorWithCalibratedRed:0.69412f green:0.83147f blue:0.96078f alpha:1.0f];

	[self loadColorWell:color_veryLow fromKey:GrowlBubblesVeryLowColor defaultColor:defaultColor];
	[self loadColorWell:color_moderate fromKey:GrowlBubblesModerateColor defaultColor:defaultColor];
	[self loadColorWell:color_normal fromKey:GrowlBubblesNormalColor defaultColor:defaultColor];
	[self loadColorWell:color_high fromKey:GrowlBubblesHighColor defaultColor:defaultColor];
	[self loadColorWell:color_emergency fromKey:GrowlBubblesEmergencyColor defaultColor:defaultColor];

	defaultColor = [NSColor controlTextColor];

	[self loadColorWell:text_veryLow fromKey:GrowlBubblesVeryLowTextColor defaultColor:defaultColor];
	[self loadColorWell:text_moderate fromKey:GrowlBubblesModerateTextColor defaultColor:defaultColor];
	[self loadColorWell:text_normal fromKey:GrowlBubblesNormalTextColor defaultColor:defaultColor];
	[self loadColorWell:text_high fromKey:GrowlBubblesHighTextColor defaultColor:defaultColor];
	[self loadColorWell:text_emergency fromKey:GrowlBubblesEmergencyTextColor defaultColor:defaultColor];

	defaultColor = [NSColor colorWithCalibratedRed:0.93725f green:0.96863f blue:0.99216f alpha:0.95f];

	[self loadColorWell:top_veryLow fromKey:GrowlBubblesVeryLowTopColor defaultColor:defaultColor];
	[self loadColorWell:top_moderate fromKey:GrowlBubblesModerateTopColor defaultColor:defaultColor];
	[self loadColorWell:top_normal fromKey:GrowlBubblesNormalTopColor defaultColor:defaultColor];
	[self loadColorWell:top_high fromKey:GrowlBubblesHighTopColor defaultColor:defaultColor];
	[self loadColorWell:top_emergency fromKey:GrowlBubblesEmergencyTopColor defaultColor:defaultColor];

	// screen number
	int screenNumber = 0;
	READ_GROWL_PREF_INT(GrowlBubblesScreen, GrowlBubblesPrefDomain, &screenNumber);
	[combo_screen setIntValue:screenNumber];
}

- (BOOL) getLimit {
	return limit;
}

- (void) setLimit:(BOOL)value {
	if (limit != value) {
		limit = value;
		WRITE_GROWL_PREF_BOOL(KALimitPref, value, GrowlBubblesPrefDomain);
		UPDATE_GROWL_PREFS();
	}
}

- (float) getOpacity {
	return opacity;
}

- (void) setOpacity:(float)value {
	if (opacity != value) {
		opacity = value;
		WRITE_GROWL_PREF_FLOAT(GrowlBubblesOpacity, value, GrowlBubblesPrefDomain);
		UPDATE_GROWL_PREFS();
	}
}

- (float) getDuration {
	return duration;
}

- (void) setDuration:(float)value {
	if (duration != value) {
		duration = value;
		WRITE_GROWL_PREF_FLOAT(GrowlBubblesDuration, value, GrowlBubblesPrefDomain);
		UPDATE_GROWL_PREFS();
	}
}

- (IBAction) topColorChanged:(id)sender {
	NSColor *color;
	NSString *key;
	switch ([sender tag]) {
		case -2:
			key = GrowlBubblesVeryLowTopColor;
			break;
		case -1:
			key = GrowlBubblesModerateTopColor;
			break;
		case 1:
			key = GrowlBubblesHighTopColor;
			break;
		case 2:
			key = GrowlBubblesEmergencyTopColor;
			break;
		case 0:
		default:
			key = GrowlBubblesNormalTopColor;
			break;
	}

	color = [[sender color] colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
	NSData *theData = [NSArchiver archivedDataWithRootObject:[sender color]];
	WRITE_GROWL_PREF_VALUE(key, theData, GrowlBubblesPrefDomain);

	UPDATE_GROWL_PREFS();
}

- (IBAction) colorChanged:(id)sender {
	NSColor *color;
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
	NSData *theData = [NSArchiver archivedDataWithRootObject:[sender color]];
	WRITE_GROWL_PREF_VALUE(key, theData, GrowlBubblesPrefDomain);

	//NSLog(@"color: %@ array: %@", color, array);

	UPDATE_GROWL_PREFS();
}

- (IBAction) textColorChanged:(id)sender {	
	NSColor *color;
	NSString *key;
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
	NSData *theData = [NSArchiver archivedDataWithRootObject:[sender color]];
	WRITE_GROWL_PREF_VALUE(key, theData, GrowlBubblesPrefDomain);

	//NSLog(@"color: %@ array: %@", color, array);

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
	WRITE_GROWL_PREF_INT(GrowlBubblesScreen, pref, GrowlBubblesPrefDomain);	
	UPDATE_GROWL_PREFS();
}

@end
