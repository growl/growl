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

- (void) mainViewDidLoad {	
	[slider_opacity setAltIncrementValue:0.05];
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
