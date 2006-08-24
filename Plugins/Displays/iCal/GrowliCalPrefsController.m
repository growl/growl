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

- (void) mainViewDidLoad {
	NSData *data = nil;
	READ_GROWL_PREF_VALUE(GrowliCalOverallColor, GrowliCalPrefDomain, NSData *, &data);
	[overall_color selectItemWithTitle:[NSUnarchiver unarchiveObjectWithData:data]];
	[slider_opacity setAltIncrementValue:0.05];
	[data release];
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

- (IBAction) colorChanged:(id)sender {
	NSString *color = [sender titleOfSelectedItem];
	NSData *theData = [NSArchiver archivedDataWithRootObject:color];
	WRITE_GROWL_PREF_VALUE(GrowliCalOverallColor, theData, GrowliCalPrefDomain);
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
