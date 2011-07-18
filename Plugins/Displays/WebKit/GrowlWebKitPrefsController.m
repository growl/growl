//
//  GrowlWebKitPrefsController.m
//  Growl
//
//  Created by Ingmar Stein on Thu Apr 14 2005.
//  Copyright 2005-2006 The Growl Project. All rights reserved.
//

#import "GrowlWebKitPrefsController.h"
#import "GrowlWebKitDefines.h"
#import "GrowlDefinesInternal.h"
#import "GrowlPluginController.h"

@implementation GrowlWebKitPrefsController
- (id) initWithStyle:(NSString *)styleName {
	if ((self = [self initWithBundle:[NSBundle bundleWithIdentifier:GROWL_HELPERAPP_BUNDLE_IDENTIFIER]])) {
		style = [styleName retain];
		prefDomain = [[NSString alloc] initWithFormat:@"%@.%@", GrowlWebKitPrefDomain, style];
	}
	return self;
}

- (void) dealloc {
	[style      release];
	[prefDomain release];
	[super dealloc];
}

- (NSString *) mainNibName {
	return @"WebKitPrefs";
}

- (void) mainViewDidLoad {
	[slider_opacity setAltIncrementValue:0.05];
}

#pragma mark -

- (BOOL) isLimit {
	BOOL value = YES;
	READ_GROWL_PREF_BOOL(GrowlWebKitLimitPref, prefDomain, &value);
	return value;
}

- (void) setLimit:(BOOL)value {
	WRITE_GROWL_PREF_BOOL(GrowlWebKitLimitPref, value, prefDomain);
	UPDATE_GROWL_PREFS();
}

#pragma mark -

- (CGFloat) opacity {
	CGFloat value = 95.0;
	READ_GROWL_PREF_FLOAT(GrowlWebKitOpacityPref, prefDomain, &value);
	return value;
}

- (void) setOpacity:(CGFloat)value {
	WRITE_GROWL_PREF_FLOAT(GrowlWebKitOpacityPref, value, prefDomain);
	UPDATE_GROWL_PREFS();
}

#pragma mark -

- (CGFloat) duration {
	CGFloat value = 4.0;
	READ_GROWL_PREF_FLOAT(GrowlWebKitDurationPref, prefDomain, &value);
	return value;
}

- (void) setDuration:(CGFloat)value {
	WRITE_GROWL_PREF_FLOAT(GrowlWebKitDurationPref, value, prefDomain);
	UPDATE_GROWL_PREFS();
}

#pragma mark -

- (NSInteger) numberOfItemsInComboBox:(NSComboBox *)aComboBox {
	return [[NSScreen screens] count];
}

- (id) comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(NSInteger)idx {
#ifdef __LP64__
	return [NSNumber numberWithInteger:idx];
#else
	return [NSNumber numberWithInt:idx];
#endif
}

- (int) screen {
	int value = 0;
	READ_GROWL_PREF_INT(GrowlWebKitScreenPref, prefDomain, &value);
	return value;
}

- (void) setScreen:(int)value {
	WRITE_GROWL_PREF_INT(GrowlWebKitScreenPref, value, prefDomain);
	UPDATE_GROWL_PREFS();
}
@end
