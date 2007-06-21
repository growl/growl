//
//  GrowlNanoPrefs.m
//  Display Plugins
//
//  Created by Rudy Richter on 12/12/2005.
//  Copyright 2005-2006, The Growl Project. All rights reserved.
//


#import "GrowlNanoPrefs.h"
#import "GrowlDefinesInternal.h"

@implementation GrowlNanoPrefs

- (NSString *) mainNibName {
	return @"GrowlNanoPrefs";
}

- (void) mainViewDidLoad {
	[slider_opacity setAltIncrementValue:5.0];
}

- (void) didSelect {
	SYNCHRONIZE_GROWL_PREFS();
}

#pragma mark -

+ (NSColor *) loadColor:(NSString *)key defaultColor:(NSColor *)defaultColor {
	NSData *data = nil;
	NSColor *color;
	READ_GROWL_PREF_VALUE(key, GrowlNanoPrefDomain, NSData *, &data);
	if (data && [data isKindOfClass:[NSData class]]) {
		color = [NSUnarchiver unarchiveObjectWithData:data];
	} else {
		color = defaultColor;
	}
	[data release];

	return color;
}

#pragma mark Accessors

- (float) duration {
	float value = GrowlNanoDurationPrefDefault;
	READ_GROWL_PREF_FLOAT(Nano_DURATION_PREF, GrowlNanoPrefDomain, &value);
	return value;
}
- (void) setDuration:(float)value {
	WRITE_GROWL_PREF_FLOAT(Nano_DURATION_PREF, value, GrowlNanoPrefDomain);
	UPDATE_GROWL_PREFS();
}

- (unsigned) effect {
	int effect = 0;
	READ_GROWL_PREF_INT(Nano_EFFECT_PREF, GrowlNanoPrefDomain, &effect);
	switch (effect) {
		default:
			effect = Nano_EFFECT_SLIDE;

		case Nano_EFFECT_SLIDE:
		case Nano_EFFECT_WIPE:
			;
	}
	return (unsigned)effect;
}
- (void) setEffect:(unsigned)newEffect {
	switch (newEffect) {
		default:
			NSLog(@"(Nano) Invalid effect number %u", newEffect);
			break;

		case Nano_EFFECT_SLIDE:
		case Nano_EFFECT_WIPE:
		case Nano_EFFECT_FADE:
			WRITE_GROWL_PREF_INT(Nano_EFFECT_PREF, newEffect, GrowlNanoPrefDomain);
			UPDATE_GROWL_PREFS();
	}
}

- (float) opacity {
	float value = Nano_DEFAULT_OPACITY;
	READ_GROWL_PREF_FLOAT(Nano_OPACITY_PREF, GrowlNanoPrefDomain, &value);
	return value;
}
- (void) setOpacity:(float)value {
	WRITE_GROWL_PREF_FLOAT(Nano_OPACITY_PREF, value, GrowlNanoPrefDomain);
	UPDATE_GROWL_PREFS();
}

- (int) size {
	int value = 0;
	READ_GROWL_PREF_INT(Nano_SIZE_PREF, GrowlNanoPrefDomain, &value);
	return value;
}
- (void) setSize:(int)value {
	WRITE_GROWL_PREF_INT(Nano_SIZE_PREF, value, GrowlNanoPrefDomain);
	UPDATE_GROWL_PREFS();
}

#pragma mark Combo box support

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
	READ_GROWL_PREF_INT(Nano_SCREEN_PREF, GrowlNanoPrefDomain, &value);
	return value;
}
- (void) setScreen:(int)value {
	WRITE_GROWL_PREF_INT(Nano_SCREEN_PREF, value, GrowlNanoPrefDomain);
	UPDATE_GROWL_PREFS();
}

- (NSColor *) textColorVeryLow {
	return [GrowlNanoPrefs loadColor:GrowlNanoVeryLowTextColor
							  defaultColor:[NSColor whiteColor]];
}

- (void) setTextColorVeryLow:(NSColor *)value {
	NSData *theData = [NSArchiver archivedDataWithRootObject:value];
    WRITE_GROWL_PREF_VALUE(GrowlNanoVeryLowTextColor, theData, GrowlNanoPrefDomain);
    UPDATE_GROWL_PREFS();
}

- (NSColor *) textColorModerate {
	return [GrowlNanoPrefs loadColor:GrowlNanoModerateTextColor
							  defaultColor:[NSColor whiteColor]];
}

- (void) setTextColorModerate:(NSColor *)value {
	NSData *theData = [NSArchiver archivedDataWithRootObject:value];
    WRITE_GROWL_PREF_VALUE(GrowlNanoModerateTextColor, theData, GrowlNanoPrefDomain);
    UPDATE_GROWL_PREFS();
}

- (NSColor *) textColorNormal {
	return [GrowlNanoPrefs loadColor:GrowlNanoNormalTextColor
							  defaultColor:[NSColor whiteColor]];
}

- (void) setTextColorNormal:(NSColor *)value {
	NSData *theData = [NSArchiver archivedDataWithRootObject:value];
    WRITE_GROWL_PREF_VALUE(GrowlNanoNormalTextColor, theData, GrowlNanoPrefDomain);
    UPDATE_GROWL_PREFS();
}

- (NSColor *) textColorHigh {
	return [GrowlNanoPrefs loadColor:GrowlNanoHighTextColor
							  defaultColor:[NSColor whiteColor]];
}

- (void) setTextColorHigh:(NSColor *)value {
	NSData *theData = [NSArchiver archivedDataWithRootObject:value];
    WRITE_GROWL_PREF_VALUE(GrowlNanoHighTextColor, theData, GrowlNanoPrefDomain);
    UPDATE_GROWL_PREFS();
}

- (NSColor *) textColorEmergency {
	return [GrowlNanoPrefs loadColor:GrowlNanoEmergencyTextColor
							  defaultColor:[NSColor whiteColor]];
}

- (void) setTextColorEmergency:(NSColor *)value {
	NSData *theData = [NSArchiver archivedDataWithRootObject:value];
    WRITE_GROWL_PREF_VALUE(GrowlNanoEmergencyTextColor, theData, GrowlNanoPrefDomain);
    UPDATE_GROWL_PREFS();
}

- (NSColor *) backgroundColorVeryLow {
	return [GrowlNanoPrefs loadColor:GrowlNanoVeryLowBackgroundColor
							  defaultColor:[NSColor blackColor]];
}

- (void) setBackgroundColorVeryLow:(NSColor *)value {
	NSData *theData = [NSArchiver archivedDataWithRootObject:value];
    WRITE_GROWL_PREF_VALUE(GrowlNanoVeryLowBackgroundColor, theData, GrowlNanoPrefDomain);
    UPDATE_GROWL_PREFS();
}

- (NSColor *) backgroundColorModerate {
	return [GrowlNanoPrefs loadColor:GrowlNanoModerateBackgroundColor
							  defaultColor:[NSColor blackColor]];
}

- (void) setBackgroundColorModerate:(NSColor *)value {
	NSData *theData = [NSArchiver archivedDataWithRootObject:value];
    WRITE_GROWL_PREF_VALUE(GrowlNanoModerateBackgroundColor, theData, GrowlNanoPrefDomain);
    UPDATE_GROWL_PREFS();
}

- (NSColor *) backgroundColorNormal {
	return [GrowlNanoPrefs loadColor:GrowlNanoNormalBackgroundColor
						 defaultColor:[NSColor blackColor]];
}

- (void) setBackgroundColorNormal:(NSColor *)value {
	NSData *theData = [NSArchiver archivedDataWithRootObject:value];
    WRITE_GROWL_PREF_VALUE(GrowlNanoNormalBackgroundColor, theData, GrowlNanoPrefDomain);
    UPDATE_GROWL_PREFS();
}

- (NSColor *) backgroundColorHigh {
	return [GrowlNanoPrefs loadColor:GrowlNanoHighBackgroundColor
							  defaultColor:[NSColor blackColor]];
}

- (void) setBackgroundColorHigh:(NSColor *)value {
	NSData *theData = [NSArchiver archivedDataWithRootObject:value];
    WRITE_GROWL_PREF_VALUE(GrowlNanoHighBackgroundColor, theData, GrowlNanoPrefDomain);
    UPDATE_GROWL_PREFS();
}

- (NSColor *) backgroundColorEmergency {
	return [GrowlNanoPrefs loadColor:GrowlNanoEmergencyBackgroundColor
							  defaultColor:[NSColor blackColor]];
}

- (void) setBackgroundColorEmergency:(NSColor *)value {
	NSData *theData = [NSArchiver archivedDataWithRootObject:value];
    WRITE_GROWL_PREF_VALUE(GrowlNanoEmergencyBackgroundColor, theData, GrowlNanoPrefDomain);
    UPDATE_GROWL_PREFS();
}
@end
