//
//  GrowlWebKitPrefsController.m
//  Growl
//
//  Created by Ingmar Stein on Thu Apr 14 2005.
//  Copyright 2005 The Growl Project. All rights reserved.
//

#import "GrowlWebKitPrefsController.h"
#import "GrowlWebKitDefines.h"
#import "GrowlDefinesInternal.h"
#import "GrowlPluginController.h"

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
	READ_GROWL_PREF_BOOL(GrowlWebKitLimitPref, GrowlWebKitPrefDomain, &value);
	return value;
}

- (void) setLimit:(BOOL)value {
	WRITE_GROWL_PREF_BOOL(GrowlWebKitLimitPref, value, GrowlWebKitPrefDomain);
	UPDATE_GROWL_PREFS();
}

#pragma mark -

- (float) opacity {
	float value = 95.0f;
	READ_GROWL_PREF_FLOAT(GrowlWebKitOpacityPref, GrowlWebKitPrefDomain, &value);
	return value;
}

- (void) setOpacity:(float)value {
	WRITE_GROWL_PREF_FLOAT(GrowlWebKitOpacityPref, value, GrowlWebKitPrefDomain);
	UPDATE_GROWL_PREFS();
}

#pragma mark -

- (float) duration {
	float value = 4.0f;
	READ_GROWL_PREF_FLOAT(GrowlWebKitDurationPref, GrowlWebKitPrefDomain, &value);
	return value;
}

- (void) setDuration:(float)value {
	WRITE_GROWL_PREF_FLOAT(GrowlWebKitDurationPref, value, GrowlWebKitPrefDomain);
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
	READ_GROWL_PREF_INT(GrowlWebKitScreenPref, GrowlWebKitPrefDomain, &value);
	return value;
}

- (void) setScreen:(int)value {
	WRITE_GROWL_PREF_INT(GrowlWebKitScreenPref, value, GrowlWebKitPrefDomain);	
	UPDATE_GROWL_PREFS();
}

- (NSArray *) styles {
	return [[GrowlPluginController controller] allStyles];
}

- (NSString *) style {
	NSString *value = @"Default";
	READ_GROWL_PREF_VALUE(GrowlWebKitStylePref, GrowlWebKitPrefDomain, NSString *, &value);
	return value;
}

- (void) setStyle:(NSString *)value {
	WRITE_GROWL_PREF_VALUE(GrowlWebKitStylePref, value, GrowlWebKitPrefDomain);	
	UPDATE_GROWL_PREFS();
}
@end
