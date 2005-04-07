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

	// position
	int positionPref = BEZEL_POSITION_DEFAULT;
	READ_GROWL_PREF_INT(BEZEL_POSITION_PREF, BezelPrefDomain, &positionPref);
	switch (positionPref) {
		default:
		case BEZEL_POSITION_DEFAULT:
			[radio_PositionD setState:NSOnState];
			[radio_PositionTR setState:NSOffState];
			[radio_PositionBR setState:NSOffState];
			[radio_PositionBL setState:NSOffState];
			[radio_PositionTL setState:NSOffState];
			break;
		case BEZEL_POSITION_TOPRIGHT:
			[radio_PositionD setState:NSOffState];
			[radio_PositionTR setState:NSOnState];
			[radio_PositionBR setState:NSOffState];
			[radio_PositionBL setState:NSOffState];
			[radio_PositionTL setState:NSOffState];
			break;
		case BEZEL_POSITION_BOTTOMRIGHT:
			[radio_PositionD setState:NSOffState];
			[radio_PositionTR setState:NSOffState];
			[radio_PositionBR setState:NSOnState];
			[radio_PositionBL setState:NSOffState];
			[radio_PositionTL setState:NSOffState];
			break;
		case BEZEL_POSITION_BOTTOMLEFT:
			[radio_PositionD setState:NSOffState];
			[radio_PositionTR setState:NSOffState];
			[radio_PositionBR setState:NSOffState];
			[radio_PositionBL setState:NSOnState];
			[radio_PositionTL setState:NSOffState];
			break;
		case BEZEL_POSITION_TOPLEFT:
			[radio_PositionD setState:NSOffState];
			[radio_PositionTR setState:NSOffState];
			[radio_PositionBR setState:NSOffState];
			[radio_PositionBL setState:NSOffState];
			[radio_PositionTL setState:NSOnState];
			break;
	}
}

- (void) didSelect {
	SYNCHRONIZE_GROWL_PREFS();
}

- (IBAction) positionChanged:(id)sender {
	int positionPref;

	if (sender == radio_PositionD) {
		[radio_PositionTR setState:NSOffState];
		[radio_PositionBR setState:NSOffState];
		[radio_PositionBL setState:NSOffState];
		[radio_PositionTL setState:NSOffState];
		positionPref = BEZEL_POSITION_DEFAULT;
	} else if (sender == radio_PositionTR) {
		[radio_PositionD setState:NSOffState];
		[radio_PositionBR setState:NSOffState];
		[radio_PositionBL setState:NSOffState];
		[radio_PositionTL setState:NSOffState];
		positionPref = BEZEL_POSITION_TOPRIGHT;
	} else if (sender == radio_PositionBR) {
		[radio_PositionD setState:NSOffState];
		[radio_PositionTR setState:NSOffState];
		[radio_PositionBL setState:NSOffState];
		[radio_PositionTL setState:NSOffState];
		positionPref = BEZEL_POSITION_BOTTOMRIGHT;
	} else if (sender == radio_PositionBL) {
		[radio_PositionD setState:NSOffState];
		[radio_PositionTR setState:NSOffState];
		[radio_PositionBR setState:NSOffState];
		[radio_PositionTL setState:NSOffState];
		positionPref = BEZEL_POSITION_BOTTOMLEFT;
	} else if (sender == radio_PositionTL) {
		[radio_PositionD setState:NSOffState];
		[radio_PositionTR setState:NSOffState];
		[radio_PositionBR setState:NSOffState];
		[radio_PositionBL setState:NSOffState];
		positionPref = BEZEL_POSITION_TOPLEFT;
	}

	WRITE_GROWL_PREF_INT(BEZEL_POSITION_PREF, positionPref, BezelPrefDomain);
	UPDATE_GROWL_PREFS();
}

#pragma mark -

- (float) opacity {
	float value = BEZEL_OPACITY_DEFAULT;
	READ_GROWL_PREF_FLOAT(BEZEL_OPACITY_PREF, BezelPrefDomain, &value);
	return value;
}

- (void) setOpacity:(float)value {
	WRITE_GROWL_PREF_FLOAT(BEZEL_OPACITY_PREF, value, BezelPrefDomain);
	UPDATE_GROWL_PREFS();
}

#pragma mark -

- (float) duration {
	float value = 3.0f;
	READ_GROWL_PREF_FLOAT(BEZEL_DURATION_PREF, BezelPrefDomain, &value);
	return value;
}

- (void) setDuration:(float)value {
	WRITE_GROWL_PREF_FLOAT(BEZEL_DURATION_PREF, value, BezelPrefDomain);
	UPDATE_GROWL_PREFS();
}

#pragma mark -

- (int) size {
	int value = 0;
	READ_GROWL_PREF_INT(BEZEL_SIZE_PREF, BezelPrefDomain, &value);
	return value;
}

- (void) setSize:(int)value {
	WRITE_GROWL_PREF_INT(BEZEL_SIZE_PREF, value, BezelPrefDomain);
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
	READ_GROWL_PREF_INT(BEZEL_SCREEN_PREF, BezelPrefDomain, &value);
	return value;
}

- (void) setScreen:(int)value {
	WRITE_GROWL_PREF_INT(BEZEL_SCREEN_PREF, value, BezelPrefDomain);	
	UPDATE_GROWL_PREFS();
}

#pragma mark -

- (int) style {
	int value = 0;
	READ_GROWL_PREF_INT(BEZEL_STYLE_PREF, BezelPrefDomain, &value);
	return value;
}

- (void) setStyle:(int)value {
	WRITE_GROWL_PREF_INT(BEZEL_STYLE_PREF, value, BezelPrefDomain);
	UPDATE_GROWL_PREFS();
}

@end
