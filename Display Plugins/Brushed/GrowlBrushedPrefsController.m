//
//  GrowlBrushedPrefsController.m
//  Display Plugins
//
//  Created by Ingmar Stein on 12/01/2004.
//  Copyright 2004-2005 The Growl Project. All rights reserved.
//

#import "GrowlBrushedPrefsController.h"
#import "GrowlBrushedDefines.h"
#import "GrowlDefinesInternal.h"


@implementation GrowlBrushedPrefsController

- (NSString *) mainNibName {
	return @"BrushedPrefs";
}

- (void) loadColorWell:(NSColorWell *)colorWell fromKey:(NSString *)key defaultColor:(NSColor *)defaultColor {
	NSData *data = nil;
	NSColor *color;
	READ_GROWL_PREF_VALUE(key, GrowlBrushedPrefDomain, NSData *, &data);
	if (data && [data isKindOfClass:[NSData class]]) {
		color = [NSUnarchiver unarchiveObjectWithData:data];
	} else {
		color = defaultColor;
	}
	[colorWell setColor:color];
	[data release];
}

- (void) mainViewDidLoad {
	// duration
	duration = GrowlBrushedDurationPrefDefault;
	READ_GROWL_PREF_FLOAT(GrowlBrushedDurationPref, GrowlBrushedPrefDomain, &duration);
	[self setDuration:duration];

	// float icon checkbox
	floatingIcon = GrowlBrushedFloatIconPrefDefault;
	READ_GROWL_PREF_BOOL(GrowlBrushedFloatIconPref, GrowlBrushedPrefDomain, &floatingIcon);
	[self setFloatingIcon:floatingIcon];

	// limit
	limit = GrowlBrushedLimitPrefDefault;
	READ_GROWL_PREF_BOOL(GrowlBrushedLimitPref, GrowlBrushedPrefDomain, &limit);
	[self setLimit:limit];

	// aqua
	aqua = GrowlBrushedAquaPrefDefault;
	READ_GROWL_PREF_BOOL(GrowlBrushedAquaPref, GrowlBrushedPrefDomain, &aqua);
	[self setAqua:aqua];
	
	// priority colour settings
	NSColor *defaultColor = [NSColor colorWithCalibratedWhite:0.1f alpha:1.0f];

	[self loadColorWell:text_veryLow fromKey:GrowlBrushedVeryLowTextColor defaultColor:defaultColor];
	[self loadColorWell:text_moderate fromKey:GrowlBrushedModerateTextColor defaultColor:defaultColor];
	[self loadColorWell:text_normal fromKey:GrowlBrushedNormalTextColor defaultColor:defaultColor];
	[self loadColorWell:text_high fromKey:GrowlBrushedHighTextColor defaultColor:defaultColor];
	[self loadColorWell:text_emergency fromKey:GrowlBrushedEmergencyTextColor defaultColor:defaultColor];

	// screen number
	int screenNumber = 0;
	READ_GROWL_PREF_INT(GrowlBrushedScreenPref, GrowlBrushedPrefDomain, &screenNumber);
	[combo_screen setIntValue:screenNumber];
}

#pragma mark -

- (int) numberOfItemsInComboBox:(NSComboBox *)aComboBox {
	return [[NSScreen screens] count];
}

- (id) comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(int)idx {
	return [NSNumber numberWithInt:idx];
}

- (IBAction) setScreen:(id)sender {
	int pref = [sender intValue];
	WRITE_GROWL_PREF_INT(GrowlBrushedScreenPref, pref, GrowlBrushedPrefDomain);	
	UPDATE_GROWL_PREFS();
}

#pragma mark -

- (float) getDuration {
	return duration;
}

- (void) setDuration:(float)value {
	if (duration != value) {
		WRITE_GROWL_PREF_FLOAT(GrowlBrushedDurationPref, value, GrowlBrushedPrefDomain);
		UPDATE_GROWL_PREFS();
	}
	duration = value;
}

#pragma mark -

- (IBAction) textColorChanged:(id)sender {
    NSString *key;
    switch ([sender tag]) {
        case -2:
            key = GrowlBrushedVeryLowTextColor;
            break;
        case -1:
            key = GrowlBrushedModerateTextColor;
            break;
        case 1:
            key = GrowlBrushedHighTextColor;
            break;
        case 2:
            key = GrowlBrushedEmergencyTextColor;
            break;
        case 0:
        default:
            key = GrowlBrushedNormalTextColor;
            break;
    }

	NSData *theData = [NSArchiver archivedDataWithRootObject:[sender color]];
    WRITE_GROWL_PREF_VALUE(key, theData, GrowlBrushedPrefDomain);
    UPDATE_GROWL_PREFS();
}

#pragma mark -

- (BOOL) isFloatingIcon {
	return floatingIcon;
}

- (void) setFloatingIcon:(BOOL)value {
	if (floatingIcon != value) {
		floatingIcon = value;
		WRITE_GROWL_PREF_BOOL(GrowlBrushedFloatIconPref, value, GrowlBrushedPrefDomain);
		UPDATE_GROWL_PREFS();
	}
}

#pragma mark -

- (BOOL) isLimit {
	return limit;
}

- (void) setLimit:(BOOL)value {
	if (limit != value) {
		limit = value;
		WRITE_GROWL_PREF_BOOL(GrowlBrushedLimitPref, value, GrowlBrushedPrefDomain);
		UPDATE_GROWL_PREFS();
	}
}

#pragma mark -

- (BOOL) isAqua {
	return aqua;
}

- (void) setAqua:(BOOL)value {
	if (aqua != value) {
		aqua = value;
		WRITE_GROWL_PREF_BOOL(GrowlBrushedAquaPref, value, GrowlBrushedPrefDomain);
		UPDATE_GROWL_PREFS();
	}
}

@end
