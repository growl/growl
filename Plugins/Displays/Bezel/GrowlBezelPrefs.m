//
//  GrowlBezelPrefs.m
//  Display Plugins
//
//  Created by Jorge Salvador Caffarena on 14/09/04.
//  Copyright 2004 Jorge Salvador Caffarena. All rights reserved.
//

#import "GrowlBezelPrefs.h"
#import "GrowlDefinesInternal.h"

@implementation GrowlBezelPrefs

- (NSString *) mainNibName {
	return @"GrowlBezelPrefs";
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
	READ_GROWL_PREF_VALUE(key, GrowlBezelPrefDomain, NSData *, &data);
	if(data)
		CFMakeCollectable(data);		
	if (data && [data isKindOfClass:[NSData class]]) {
			color = [NSUnarchiver unarchiveObjectWithData:data];
	} else {
		color = defaultColor;
	}
	[data release];
	data = nil;
	
	return color;
}

#pragma mark -

- (CGFloat) opacity {
	CGFloat value = BEZEL_OPACITY_DEFAULT;
	READ_GROWL_PREF_FLOAT(BEZEL_OPACITY_PREF, GrowlBezelPrefDomain, &value);
	return value;
}

- (void) setOpacity:(CGFloat)value {
	WRITE_GROWL_PREF_FLOAT(BEZEL_OPACITY_PREF, value, GrowlBezelPrefDomain);
	UPDATE_GROWL_PREFS();
}

#pragma mark -

- (CGFloat) duration {
	CGFloat value = 3.0;
	READ_GROWL_PREF_FLOAT(GrowlBezelDuration, GrowlBezelPrefDomain, &value);
	return value;
}

- (void) setDuration:(CGFloat)value {
	WRITE_GROWL_PREF_FLOAT(GrowlBezelDuration, value, GrowlBezelPrefDomain);
	UPDATE_GROWL_PREFS();
}

#pragma mark -

- (int) size {
	int value = 0;
	READ_GROWL_PREF_INT(BEZEL_SIZE_PREF, GrowlBezelPrefDomain, &value);
	return value;
}

- (void) setSize:(int)value {
	WRITE_GROWL_PREF_INT(BEZEL_SIZE_PREF, value, GrowlBezelPrefDomain);
	UPDATE_GROWL_PREFS();
}

#pragma mark -

- (NSInteger) numberOfItemsInComboBox:(NSComboBox *)aComboBox {
#pragma unused(aComboBox)
	return [[NSScreen screens] count];
}

- (id) comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(NSInteger)idx {
#pragma unused(aComboBox)
#ifdef __LP64__
	return [NSNumber numberWithInteger:idx];
#else
	return [NSNumber numberWithInt:idx];
#endif
}

- (int) screen {
	int value = 0;
	READ_GROWL_PREF_INT(BEZEL_SCREEN_PREF, GrowlBezelPrefDomain, &value);
	return value;
}

- (void) setScreen:(int)value {
	WRITE_GROWL_PREF_INT(BEZEL_SCREEN_PREF, value, GrowlBezelPrefDomain);
	UPDATE_GROWL_PREFS();
}

#pragma mark -

- (int) style {
	int value = 0;
	READ_GROWL_PREF_INT(BEZEL_STYLE_PREF, GrowlBezelPrefDomain, &value);
	return value;
}

- (void) setStyle:(int)value {
	WRITE_GROWL_PREF_INT(BEZEL_STYLE_PREF, value, GrowlBezelPrefDomain);
	UPDATE_GROWL_PREFS();
}

#pragma mark -

- (int) position {
	int value = BEZEL_POSITION_DEFAULT;
	READ_GROWL_PREF_INT(BEZEL_POSITION_PREF, GrowlBezelPrefDomain, &value);
	return value;
}

- (void) setPosition:(int)value {
	WRITE_GROWL_PREF_INT(BEZEL_POSITION_PREF, value, GrowlBezelPrefDomain);
	UPDATE_GROWL_PREFS();
}

#pragma mark -

- (BOOL) shrink {
	BOOL shrink = YES;
	READ_GROWL_PREF_BOOL(BEZEL_SHRINK_PREF, GrowlBezelPrefDomain, &shrink);
	return shrink;
}

- (void) setShrink:(BOOL)flag {
	WRITE_GROWL_PREF_BOOL(BEZEL_SHRINK_PREF, flag, GrowlBezelPrefDomain);
	UPDATE_GROWL_PREFS();
}

#pragma mark -

- (BOOL) flip {
	BOOL flip = YES;
	READ_GROWL_PREF_BOOL(BEZEL_FLIP_PREF, GrowlBezelPrefDomain, &flip);
	return flip;
}

- (void) setFlip:(BOOL)flag {
	WRITE_GROWL_PREF_BOOL(BEZEL_FLIP_PREF, flag, GrowlBezelPrefDomain);
	UPDATE_GROWL_PREFS();
}

#pragma mark -

- (NSColor *) textColorVeryLow {
	return [GrowlBezelPrefs loadColor:GrowlBezelVeryLowTextColor
						 defaultColor:[NSColor whiteColor]];
}

- (void) setTextColorVeryLow:(NSColor *)value {
	NSData *theData = [NSArchiver archivedDataWithRootObject:value];
    WRITE_GROWL_PREF_VALUE(GrowlBezelVeryLowTextColor, theData, GrowlBezelPrefDomain);
    UPDATE_GROWL_PREFS();
}

- (NSColor *) textColorModerate {
	return [GrowlBezelPrefs loadColor:GrowlBezelModerateTextColor
						 defaultColor:[NSColor whiteColor]];
}

- (void) setTextColorModerate:(NSColor *)value {
	NSData *theData = [NSArchiver archivedDataWithRootObject:value];
    WRITE_GROWL_PREF_VALUE(GrowlBezelModerateTextColor, theData, GrowlBezelPrefDomain);
    UPDATE_GROWL_PREFS();
}

- (NSColor *) textColorNormal {
	return [GrowlBezelPrefs loadColor:GrowlBezelNormalTextColor
						 defaultColor:[NSColor whiteColor]];
}

- (void) setTextColorNormal:(NSColor *)value {
	NSData *theData = [NSArchiver archivedDataWithRootObject:value];
    WRITE_GROWL_PREF_VALUE(GrowlBezelNormalTextColor, theData, GrowlBezelPrefDomain);
    UPDATE_GROWL_PREFS();
}

- (NSColor *) textColorHigh {
	return [GrowlBezelPrefs loadColor:GrowlBezelHighTextColor
						 defaultColor:[NSColor whiteColor]];
}

- (void) setTextColorHigh:(NSColor *)value {
	NSData *theData = [NSArchiver archivedDataWithRootObject:value];
    WRITE_GROWL_PREF_VALUE(GrowlBezelHighTextColor, theData, GrowlBezelPrefDomain);
    UPDATE_GROWL_PREFS();
}

- (NSColor *) textColorEmergency {
	return [GrowlBezelPrefs loadColor:GrowlBezelEmergencyTextColor
						 defaultColor:[NSColor whiteColor]];
}

- (void) setTextColorEmergency:(NSColor *)value {
	NSData *theData = [NSArchiver archivedDataWithRootObject:value];
    WRITE_GROWL_PREF_VALUE(GrowlBezelEmergencyTextColor, theData, GrowlBezelPrefDomain);
    UPDATE_GROWL_PREFS();
}

#pragma mark -

- (NSColor *) backgroundColorVeryLow {
	return [GrowlBezelPrefs loadColor:GrowlBezelVeryLowBackgroundColor
						 defaultColor:[NSColor blackColor]];
}

- (void) setBackgroundColorVeryLow:(NSColor *)value {
	NSData *theData = [NSArchiver archivedDataWithRootObject:value];
    WRITE_GROWL_PREF_VALUE(GrowlBezelVeryLowBackgroundColor, theData, GrowlBezelPrefDomain);
    UPDATE_GROWL_PREFS();
}

- (NSColor *) backgroundColorModerate {
	return [GrowlBezelPrefs loadColor:GrowlBezelModerateBackgroundColor
						 defaultColor:[NSColor blackColor]];
}

- (void) setBackgroundColorModerate:(NSColor *)value {
	NSData *theData = [NSArchiver archivedDataWithRootObject:value];
    WRITE_GROWL_PREF_VALUE(GrowlBezelModerateBackgroundColor, theData, GrowlBezelPrefDomain);
    UPDATE_GROWL_PREFS();
}

- (NSColor *) backgroundColorNormal {
	return [GrowlBezelPrefs loadColor:GrowlBezelNormalBackgroundColor
						 defaultColor:[NSColor blackColor]];
}

- (void) setBackgroundColorNormal:(NSColor *)value {
	NSData *theData = [NSArchiver archivedDataWithRootObject:value];
    WRITE_GROWL_PREF_VALUE(GrowlBezelNormalBackgroundColor, theData, GrowlBezelPrefDomain);
    UPDATE_GROWL_PREFS();
}

- (NSColor *) backgroundColorHigh {
	return [GrowlBezelPrefs loadColor:GrowlBezelHighBackgroundColor
						 defaultColor:[NSColor blackColor]];
}

- (void) setBackgroundColorHigh:(NSColor *)value {
	NSData *theData = [NSArchiver archivedDataWithRootObject:value];
    WRITE_GROWL_PREF_VALUE(GrowlBezelHighBackgroundColor, theData, GrowlBezelPrefDomain);
    UPDATE_GROWL_PREFS();
}

- (NSColor *) backgroundColorEmergency {
	return [GrowlBezelPrefs loadColor:GrowlBezelEmergencyBackgroundColor
						 defaultColor:[NSColor blackColor]];
}

- (void) setBackgroundColorEmergency:(NSColor *)value {
	NSData *theData = [NSArchiver archivedDataWithRootObject:value];
    WRITE_GROWL_PREF_VALUE(GrowlBezelEmergencyBackgroundColor, theData, GrowlBezelPrefDomain);
    UPDATE_GROWL_PREFS();
}
@end
