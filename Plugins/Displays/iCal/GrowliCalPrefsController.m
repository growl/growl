//
//  GrowliCalPrefsController.m
//  Growl
//
//  Created by Kevin Ballard on 9/7/04.
//	Adapted for iCal by Takumi Murayama on Thu Aug 17 2006.
//  Copyright 2004 TildeSoft. All rights reserved.
//

#import "GrowliCalPrefsController.h"
#import "GrowliCalDefines.h"
#import "GrowlDefinesInternal.h"

@implementation GrowliCalPrefsController
- (NSString *) mainNibName {
	return @"iCalPrefs";
}

+ (void) loadColorWell:(NSColorWell *)colorWell fromKey:(NSString *)key defaultColor:(NSColor *)defaultColor {
	NSData *data = nil;
	NSColor *color;
	READ_GROWL_PREF_VALUE(key, GrowliCalPrefDomain, NSData *, &data);
	if (data && [data isKindOfClass:[NSData class]]) {
		color = [NSUnarchiver unarchiveObjectWithData:data];
	} else {
		color = defaultColor;
	}
	[colorWell setColor:color];
	[data release];
}

- (void) mainViewDidLoad {
	float backgroundAlpha = 0.95f;
	[slider_opacity setAltIncrementValue:0.05];

	// priority colour settings
	NSColor *defaultColor = [NSColor colorWithCalibratedRed:0.7804f green:0.1098f blue:0.7725f alpha:backgroundAlpha];
	[GrowliCalPrefsController loadColorWell:color_veryLow fromKey:GrowliCalVeryLowColor defaultColor:defaultColor];
	defaultColor = [NSColor colorWithCalibratedRed:0.1490f green:0.7333f blue:0.0000f alpha:backgroundAlpha];
	[GrowliCalPrefsController loadColorWell:color_moderate fromKey:GrowliCalModerateColor defaultColor:defaultColor];
	defaultColor = [NSColor colorWithCalibratedRed:0.1255f green:0.3765f blue:0.9529f alpha:backgroundAlpha];
	[GrowliCalPrefsController loadColorWell:color_normal fromKey:GrowliCalNormalColor defaultColor:defaultColor];
	defaultColor = [NSColor colorWithCalibratedRed:1.0000f green:0.4510f blue:0.0000f alpha:backgroundAlpha];
	[GrowliCalPrefsController loadColorWell:color_high fromKey:GrowliCalHighColor defaultColor:defaultColor];
	defaultColor = [NSColor colorWithCalibratedRed:1.0000f green:0.0000f blue:0.0000f alpha:backgroundAlpha];
	[GrowliCalPrefsController loadColorWell:color_emergency fromKey:GrowliCalEmergencyColor defaultColor:defaultColor];

	defaultColor = [[NSColor whiteColor] colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
	[GrowliCalPrefsController loadColorWell:text_veryLow fromKey:GrowliCalVeryLowTextColor defaultColor:defaultColor];
	[GrowliCalPrefsController loadColorWell:text_moderate fromKey:GrowliCalModerateTextColor defaultColor:defaultColor];
	[GrowliCalPrefsController loadColorWell:text_normal fromKey:GrowliCalNormalTextColor defaultColor:defaultColor];
	[GrowliCalPrefsController loadColorWell:text_high fromKey:GrowliCalHighTextColor defaultColor:defaultColor];
	[GrowliCalPrefsController loadColorWell:text_emergency fromKey:GrowliCalEmergencyTextColor defaultColor:defaultColor];

	defaultColor = [NSColor colorWithCalibratedRed:0.8157f green:0.2471f blue:0.8078f alpha:backgroundAlpha];
	[GrowliCalPrefsController loadColorWell:top_veryLow fromKey:GrowliCalVeryLowTopColor defaultColor:defaultColor];
	defaultColor = [NSColor colorWithCalibratedRed:0.3765f green:0.8039f blue:0.2549f alpha:backgroundAlpha];
	[GrowliCalPrefsController loadColorWell:top_moderate fromKey:GrowliCalModerateTopColor defaultColor:defaultColor];
	defaultColor = [NSColor colorWithCalibratedRed:0.3529f green:0.5647f blue:1.0000f alpha:backgroundAlpha];
	[GrowliCalPrefsController loadColorWell:top_normal fromKey:GrowliCalNormalTopColor defaultColor:defaultColor];
	defaultColor = [NSColor colorWithCalibratedRed:1.0000f green:0.6235f blue:0.0941f alpha:backgroundAlpha];
	[GrowliCalPrefsController loadColorWell:top_high fromKey:GrowliCalHighTopColor defaultColor:defaultColor];
	defaultColor = [NSColor colorWithCalibratedRed:1.0000f green:0.2902f blue:0.3098f alpha:backgroundAlpha];
	[GrowliCalPrefsController loadColorWell:top_emergency fromKey:GrowliCalEmergencyTopColor defaultColor:defaultColor];

	defaultColor = [NSColor colorWithCalibratedRed:0.8157f green:0.2471f blue:0.8078f alpha:backgroundAlpha];
	[GrowliCalPrefsController loadColorWell:border_veryLow fromKey:GrowliCalVeryLowBorderColor defaultColor:defaultColor];
	defaultColor = [NSColor colorWithCalibratedRed:0.3765f green:0.8039f blue:0.2549f alpha:backgroundAlpha];
	[GrowliCalPrefsController loadColorWell:border_moderate fromKey:GrowliCalModerateBorderColor defaultColor:defaultColor];
	defaultColor = [NSColor colorWithCalibratedRed:0.1255f green:0.3765f blue:0.9529f alpha:backgroundAlpha];
	[GrowliCalPrefsController loadColorWell:border_normal fromKey:GrowliCalNormalBorderColor defaultColor:defaultColor];
	defaultColor = [NSColor colorWithCalibratedRed:1.0000f green:0.6235f blue:0.0941f alpha:backgroundAlpha];
	[GrowliCalPrefsController loadColorWell:border_high fromKey:GrowliCalHighBorderColor defaultColor:defaultColor];
	defaultColor = [NSColor colorWithCalibratedRed:1.0000f green:0.2902f blue:0.3098f alpha:backgroundAlpha];
	[GrowliCalPrefsController loadColorWell:border_emergency fromKey:GrowliCalEmergencyBorderColor defaultColor:defaultColor];
}

#pragma mark -

- (BOOL) isLimit {
	BOOL value = YES;
	READ_GROWL_PREF_BOOL(GrowliCalLimitPref, GrowliCalPrefDomain, &value);
	return value;
}

- (void) setLimit:(BOOL)value {
	WRITE_GROWL_PREF_BOOL(GrowliCalLimitPref, value, GrowliCalPrefDomain);
	UPDATE_GROWL_PREFS();
}

#pragma mark -

- (float) opacity {
	float value = 95.0f;
	READ_GROWL_PREF_FLOAT(GrowliCalOpacity, GrowliCalPrefDomain, &value);
	return value;
}

- (void) setOpacity:(float)value {
	WRITE_GROWL_PREF_FLOAT(GrowliCalOpacity, value, GrowliCalPrefDomain);
	UPDATE_GROWL_PREFS();
}

#pragma mark -

- (float) duration {
	float value = 4.0f;
	READ_GROWL_PREF_FLOAT(GrowliCalDuration, GrowliCalPrefDomain, &value);
	return value;
}

- (void) setDuration:(float)value {
	WRITE_GROWL_PREF_FLOAT(GrowliCalDuration, value, GrowliCalPrefDomain);
	UPDATE_GROWL_PREFS();
}

#pragma mark -

- (IBAction) topColorChanged:(id)sender {
	NSColor *color;
	NSString *key;
	switch ([sender tag]) {
		case -2:
			key = GrowliCalVeryLowTopColor;
			break;
		case -1:
			key = GrowliCalModerateTopColor;
			break;
		case 1:
			key = GrowliCalHighTopColor;
			break;
		case 2:
			key = GrowliCalEmergencyTopColor;
			break;
		case 0:
		default:
			key = GrowliCalNormalTopColor;
			break;
	}

	color = [[sender color] colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
	NSData *theData = [NSArchiver archivedDataWithRootObject:color];
	WRITE_GROWL_PREF_VALUE(key, theData, GrowliCalPrefDomain);
	UPDATE_GROWL_PREFS();
}

- (IBAction) colorChanged:(id)sender {
	NSColor *color;
	NSString *key;
	switch ([sender tag]) {
		case -2:
			key = GrowliCalVeryLowColor;
			break;
		case -1:
			key = GrowliCalModerateColor;
			break;
		case 1:
			key = GrowliCalHighColor;
			break;
		case 2:
			key = GrowliCalEmergencyColor;
			break;
		case 0:
		default:
			key = GrowliCalNormalColor;
			break;
	}

	color = [[sender color] colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
	NSData *theData = [NSArchiver archivedDataWithRootObject:color];
	WRITE_GROWL_PREF_VALUE(key, theData, GrowliCalPrefDomain);
	UPDATE_GROWL_PREFS();
}

- (IBAction) textColorChanged:(id)sender {
	NSString *key;
	switch ([sender tag]) {
		case -2:
			key = GrowliCalVeryLowTextColor;
			break;
		case -1:
			key = GrowliCalModerateTextColor;
			break;
		case 1:
			key = GrowliCalHighTextColor;
			break;
		case 2:
			key = GrowliCalEmergencyTextColor;
			break;
		case 0:
		default:
			key = GrowliCalNormalTextColor;
			break;
	}

	NSData *theData = [NSArchiver archivedDataWithRootObject:[sender color]];
	WRITE_GROWL_PREF_VALUE(key, theData, GrowliCalPrefDomain);
	UPDATE_GROWL_PREFS();
}

- (IBAction) borderColorChanged:(id)sender {
	NSColor *color;
	NSString *key;
	switch ([sender tag]) {
		case -2:
			key = GrowliCalVeryLowBorderColor;
			break;
		case -1:
			key = GrowliCalModerateBorderColor;
			break;
		case 1:
			key = GrowliCalHighBorderColor;
			break;
		case 2:
			key = GrowliCalEmergencyBorderColor;
			break;
		case 0:
		default:
			key = GrowliCalNormalBorderColor;
			break;
	}
	
	color = [[sender color] colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
	NSData *theData = [NSArchiver archivedDataWithRootObject:color];
	WRITE_GROWL_PREF_VALUE(key, theData, GrowliCalPrefDomain);
	UPDATE_GROWL_PREFS();
}

#pragma mark -

- (int) numberOfItemsInComboBox:(NSComboBox *)aComboBox {
#pragma unused(aComboBox)
	return [[NSScreen screens] count];
}

- (id) comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(int)idx {
#pragma unused(aComboBox)
	return [NSNumber numberWithInt:idx];
}

- (int) screen {
	int value = 0;
	READ_GROWL_PREF_INT(GrowliCalScreen, GrowliCalPrefDomain, &value);
	return value;
}

- (void) setScreen:(int)value {
	WRITE_GROWL_PREF_INT(GrowliCalScreen, value, GrowliCalPrefDomain);
	UPDATE_GROWL_PREFS();
}

- (int) size {
	int value = 0;
	READ_GROWL_PREF_INT(GrowliCalSizePref, GrowliCalPrefDomain, &value);
	return value;
}

- (void) setSize:(int)value {
	WRITE_GROWL_PREF_INT(GrowliCalSizePref, value, GrowliCalPrefDomain);
	UPDATE_GROWL_PREFS();
}
@end
