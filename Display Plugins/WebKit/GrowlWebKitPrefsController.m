//
//  GrowlWebKitPrefsController.m
//  Growl
//
//  Created by Kevin Ballard on 9/7/04.
//  Copyright 2004 TildeSoft. All rights reserved.
//

#import "GrowlWebKitPrefsController.h"
#import "GrowlWebKitDefines.h"
#import "GrowlDefinesInternal.h"

@implementation GrowlWebKitPrefsController
- (NSString *) mainNibName {
	return @"WebKitPrefs";
}

+ (void) loadColorWell:(NSColorWell *)colorWell fromKey:(NSString *)key defaultColor:(NSColor *)defaultColor {
	NSData *data = nil;
	NSColor *color;
	READ_GROWL_PREF_VALUE(key, GrowlWebKitPrefDomain, NSData *, &data);
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

	// priority colour settings
	NSColor *defaultColor = [NSColor colorWithCalibratedRed:0.69412f green:0.83147f blue:0.96078f alpha:1.0f];

	[GrowlWebKitPrefsController loadColorWell:color_veryLow fromKey:GrowlWebKitVeryLowColor defaultColor:defaultColor];
	[GrowlWebKitPrefsController loadColorWell:color_moderate fromKey:GrowlWebKitModerateColor defaultColor:defaultColor];
	[GrowlWebKitPrefsController loadColorWell:color_normal fromKey:GrowlWebKitNormalColor defaultColor:defaultColor];
	[GrowlWebKitPrefsController loadColorWell:color_high fromKey:GrowlWebKitHighColor defaultColor:defaultColor];
	[GrowlWebKitPrefsController loadColorWell:color_emergency fromKey:GrowlWebKitEmergencyColor defaultColor:defaultColor];

	defaultColor = [[NSColor controlTextColor] colorUsingColorSpaceName:NSCalibratedRGBColorSpace];

	[GrowlWebKitPrefsController loadColorWell:text_veryLow fromKey:GrowlWebKitVeryLowTextColor defaultColor:defaultColor];
	[GrowlWebKitPrefsController loadColorWell:text_moderate fromKey:GrowlWebKitModerateTextColor defaultColor:defaultColor];
	[GrowlWebKitPrefsController loadColorWell:text_normal fromKey:GrowlWebKitNormalTextColor defaultColor:defaultColor];
	[GrowlWebKitPrefsController loadColorWell:text_high fromKey:GrowlWebKitHighTextColor defaultColor:defaultColor];
	[GrowlWebKitPrefsController loadColorWell:text_emergency fromKey:GrowlWebKitEmergencyTextColor defaultColor:defaultColor];

	defaultColor = [NSColor colorWithCalibratedRed:0.93725f green:0.96863f blue:0.99216f alpha:0.95f];

	[GrowlWebKitPrefsController loadColorWell:top_veryLow fromKey:GrowlWebKitVeryLowTopColor defaultColor:defaultColor];
	[GrowlWebKitPrefsController loadColorWell:top_moderate fromKey:GrowlWebKitModerateTopColor defaultColor:defaultColor];
	[GrowlWebKitPrefsController loadColorWell:top_normal fromKey:GrowlWebKitNormalTopColor defaultColor:defaultColor];
	[GrowlWebKitPrefsController loadColorWell:top_high fromKey:GrowlWebKitHighTopColor defaultColor:defaultColor];
	[GrowlWebKitPrefsController loadColorWell:top_emergency fromKey:GrowlWebKitEmergencyTopColor defaultColor:defaultColor];
}

#pragma mark -

- (BOOL) isLimit {
	BOOL value = YES;
	READ_GROWL_PREF_BOOL(KALimitPref, GrowlWebKitPrefDomain, &value);
	return value;
}

- (void) setLimit:(BOOL)value {
	WRITE_GROWL_PREF_BOOL(KALimitPref, value, GrowlWebKitPrefDomain);
	UPDATE_GROWL_PREFS();
}

#pragma mark -

- (float) opacity {
	float value = 95.0f;
	READ_GROWL_PREF_FLOAT(GrowlWebKitOpacity, GrowlWebKitPrefDomain, &value);
	return value;
}

- (void) setOpacity:(float)value {
	WRITE_GROWL_PREF_FLOAT(GrowlWebKitOpacity, value, GrowlWebKitPrefDomain);
	UPDATE_GROWL_PREFS();
}

#pragma mark -

- (float) duration {
	float value = 4.0f;
	READ_GROWL_PREF_FLOAT(GrowlWebKitDuration, GrowlWebKitPrefDomain, &value);
	return value;
}

- (void) setDuration:(float)value {
	WRITE_GROWL_PREF_FLOAT(GrowlWebKitDuration, value, GrowlWebKitPrefDomain);
	UPDATE_GROWL_PREFS();
}

#pragma mark -

- (IBAction) topColorChanged:(id)sender {
	NSColor *color;
	NSString *key;
	switch ([sender tag]) {
		case -2:
			key = GrowlWebKitVeryLowTopColor;
			break;
		case -1:
			key = GrowlWebKitModerateTopColor;
			break;
		case 1:
			key = GrowlWebKitHighTopColor;
			break;
		case 2:
			key = GrowlWebKitEmergencyTopColor;
			break;
		case 0:
		default:
			key = GrowlWebKitNormalTopColor;
			break;
	}

	color = [[sender color] colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
	NSData *theData = [NSArchiver archivedDataWithRootObject:color];
	WRITE_GROWL_PREF_VALUE(key, theData, GrowlWebKitPrefDomain);
	UPDATE_GROWL_PREFS();
}

- (IBAction) colorChanged:(id)sender {
	NSColor *color;
	NSString *key;
	switch ([sender tag]) {
		case -2:
			key = GrowlWebKitVeryLowColor;
			break;
		case -1:
			key = GrowlWebKitModerateColor;
			break;
		case 1:
			key = GrowlWebKitHighColor;
			break;
		case 2:
			key = GrowlWebKitEmergencyColor;
			break;
		case 0:
		default:
			key = GrowlWebKitNormalColor;
			break;
	}

	color = [[sender color] colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
	NSData *theData = [NSArchiver archivedDataWithRootObject:color];
	WRITE_GROWL_PREF_VALUE(key, theData, GrowlWebKitPrefDomain);
	UPDATE_GROWL_PREFS();
}

- (IBAction) textColorChanged:(id)sender {	
	NSString *key;
	switch ([sender tag]) {
		case -2:
			key = GrowlWebKitVeryLowTextColor;
			break;
		case -1:
			key = GrowlWebKitModerateTextColor;
			break;
		case 1:
			key = GrowlWebKitHighTextColor;
			break;
		case 2:
			key = GrowlWebKitEmergencyTextColor;
			break;
		case 0:
		default:
			key = GrowlWebKitNormalTextColor;
			break;
	}

	NSData *theData = [NSArchiver archivedDataWithRootObject:[sender color]];
	WRITE_GROWL_PREF_VALUE(key, theData, GrowlWebKitPrefDomain);
	UPDATE_GROWL_PREFS();
}

#pragma mark -

- (int) numberOfItemsInComboBox:(NSComboBox *)aComboBox {
	return [[NSScreen screens] count];
}

- (id) comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(int)idx {
	return [NSNumber numberWithInt:idx];
}

- (int) screen {
	int value = 0;
	READ_GROWL_PREF_INT(GrowlWebKitScreen, GrowlWebKitPrefDomain, &value);
	return value;
}

- (void) setScreen:(int)value {
	WRITE_GROWL_PREF_INT(GrowlWebKitScreen, value, GrowlWebKitPrefDomain);	
	UPDATE_GROWL_PREFS();
}

- (int) size {
	int value = 0;
	READ_GROWL_PREF_INT(GrowlWebKitSizePref, GrowlWebKitPrefDomain, &value);
	return value;
}

- (void) setSize:(int)value {
	WRITE_GROWL_PREF_INT(GrowlWebKitSizePref, value, GrowlWebKitPrefDomain);	
	UPDATE_GROWL_PREFS();
}
@end
