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
	NSString *color = nil;
	READ_GROWL_PREF_VALUE(GrowliCalOverallColor, GrowliCalPrefDomain, NSString *, &color);
	if(color)
		[overall_color selectItemWithTitle:color];
	else
	{
		[overall_color selectItemWithTitle:@"Purple"];
		WRITE_GROWL_PREF_VALUE(GrowliCalOverallColor, @"Purple", GrowliCalPrefDomain);
	}
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
	switch([sender indexOfSelectedItem){
	case 1:
		NSString *color = @"Purple";
		break;
	case 2:
		NSString *color = @"Pink";
		break;
	case 3:
		NSString *color = @"Green";
		break;
	case 4:
		NSString *color = @"Blue";
		break;
	case 5:
		NSString *color = @"Orange";
		break;
	case 6:
		NSString *color = @"Red";
	}
	WRITE_GROWL_PREF_VALUE(GrowliCalOverallColor, color, GrowliCalPrefDomain);
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
