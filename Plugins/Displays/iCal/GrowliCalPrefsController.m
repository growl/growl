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

//make sure we set up our settings prior to the PrefPane view actually loading, or we risk not having our controls display correctly
- (void) willSelect {
	[slider_opacity setAltIncrementValue:0.05];
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

- (CGFloat) opacity {
	CGFloat value = 95.0;
	READ_GROWL_PREF_FLOAT(GrowliCalOpacity, GrowliCalPrefDomain, &value);
	return value;
}

- (void) setOpacity:(CGFloat)value {
	WRITE_GROWL_PREF_FLOAT(GrowliCalOpacity, value, GrowliCalPrefDomain);
	UPDATE_GROWL_PREFS();
}

#pragma mark -

- (CGFloat) duration {
	CGFloat value = 4.0;
	READ_GROWL_PREF_FLOAT(GrowliCalDuration, GrowliCalPrefDomain, &value);
	return value;
}

- (void) setDuration:(CGFloat)value {
	WRITE_GROWL_PREF_FLOAT(GrowliCalDuration, value, GrowliCalPrefDomain);
	UPDATE_GROWL_PREFS();
}

#pragma mark -
- (GrowliCalColorType)color
{
	GrowliCalColorType color = GrowliCalPurple;
	READ_GROWL_PREF_INT(GrowliCalColor, GrowliCalPrefDomain, &color);
	return color;
}
- (void)setColor:(GrowliCalColorType)color
{
	WRITE_GROWL_PREF_INT(GrowliCalColor, color, GrowliCalPrefDomain);
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
