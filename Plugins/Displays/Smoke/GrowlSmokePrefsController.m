//
//  GrowlSmokePrefsController.m
//  Display Plugins
//
//  Created by Matthew Walton on 11/09/2004.
//  Copyright 2004–2011 The Growl Project. All rights reserved.
//

#import "GrowlSmokePrefsController.h"
#import "GrowlSmokeDefines.h"
#import "GrowlDefinesInternal.h"

@implementation GrowlSmokePrefsController

- (NSString *) mainNibName {
	return @"SmokePrefs";
}

- (void) mainViewDidLoad {
	[slider_opacity setAltIncrementValue:0.05];

}

-(NSSet*)bindingKeys {
	static NSSet *keys = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		keys = [[NSSet setWithObjects:@"opacity",
				  @"duration",
				  @"floatingIcon",
				  @"limit",
				  @"screen",
				  @"size", nil] retain]; 
	});
	return keys;
}

-(void)updateConfigurationValues {
	// priority colour settings
	NSColor *defaultColor = [NSColor colorWithCalibratedWhite:0.1 alpha:1.0];
	[color_veryLow setColor:[self loadColor:GrowlSmokeVeryLowColor defaultColor:defaultColor]];
	[color_moderate setColor:[self loadColor:GrowlSmokeModerateColor defaultColor:defaultColor]];
	[color_normal setColor:[self loadColor:GrowlSmokeNormalColor defaultColor:defaultColor]];
	[color_high setColor:[self loadColor:GrowlSmokeHighColor defaultColor:defaultColor]];
	[color_emergency setColor:[self loadColor:GrowlSmokeEmergencyColor defaultColor:defaultColor]];
	
	defaultColor = [NSColor whiteColor];
	[text_veryLow setColor:[self loadColor:GrowlSmokeVeryLowTextColor defaultColor:defaultColor]];
	[text_moderate setColor:[self loadColor:GrowlSmokeModerateTextColor defaultColor:defaultColor]];
	[text_normal setColor:[self loadColor:GrowlSmokeNormalTextColor defaultColor:defaultColor]];
	[text_high setColor:[self loadColor:GrowlSmokeHighTextColor defaultColor:defaultColor]];
	[text_emergency setColor:[self loadColor:GrowlSmokeEmergencyTextColor defaultColor:defaultColor]];
	
	[super updateConfigurationValues];
}

- (CGFloat) opacity {
	CGFloat value = GrowlSmokeAlphaPrefDefault;
	if([self.configuration valueForKey:GrowlSmokeAlphaPref]){
		value = [[self.configuration valueForKey:GrowlSmokeAlphaPref] floatValue];
	}
	return value;
}

- (void) setOpacity:(CGFloat)value {
	[self setConfigurationValue:[NSNumber numberWithFloat:value] forKey:GrowlSmokeAlphaPref];
}

- (CGFloat) duration {
	CGFloat value = GrowlSmokeDurationPrefDefault;
	if([self.configuration valueForKey:GrowlSmokeDurationPref]){
		value = [[self.configuration valueForKey:GrowlSmokeDurationPref] floatValue];
	}
	return value;
}

- (void) setDuration:(CGFloat)value {
	[self setConfigurationValue:[NSNumber numberWithFloat:value] forKey:GrowlSmokeDurationPref];
}

- (IBAction) colorChanged:(id)sender {
	NSString *key;
	switch ([sender tag]) {
		case -2:
			key = GrowlSmokeVeryLowColor;
			break;
		case -1:
			key = GrowlSmokeModerateColor;
			break;
		case 1:
			key = GrowlSmokeHighColor;
			break;
		case 2:
			key = GrowlSmokeEmergencyColor;
			break;
		case 0:
		default:
			key = GrowlSmokeNormalColor;
			break;
	}

	NSData *theData = [NSArchiver archivedDataWithRootObject:[sender color]];
	[self setConfigurationValue:theData forKey:key];
}

- (IBAction) textColorChanged:(id)sender {
	NSString *key;
	switch ([sender tag]) {
		case -2:
			key = GrowlSmokeVeryLowTextColor;
			break;
		case -1:
			key = GrowlSmokeModerateTextColor;
			break;
		case 1:
			key = GrowlSmokeHighTextColor;
			break;
		case 2:
			key = GrowlSmokeEmergencyTextColor;
			break;
		case 0:
		default:
			key = GrowlSmokeNormalTextColor;
			break;
	}

	NSData *theData = [NSArchiver archivedDataWithRootObject:[sender color]];
	[self setConfigurationValue:theData forKey:key];
}

- (BOOL) isFloatingIcon {
	BOOL value = GrowlSmokeFloatIconPrefDefault;
	if([self.configuration valueForKey:GrowlSmokeFloatIconPref]){
		value = [[self.configuration valueForKey:GrowlSmokeFloatIconPref] boolValue];
	}
	return value;
}

- (void) setFloatingIcon:(BOOL)value {
	[self setConfigurationValue:[NSNumber numberWithBool:value] forKey:GrowlSmokeFloatIconPref];
}

- (BOOL) isLimit {
	BOOL value = GrowlSmokeLimitPrefDefault;
	if([self.configuration valueForKey:GrowlSmokeLimitPref]){
		value = [[self.configuration valueForKey:GrowlSmokeLimitPref] boolValue];
	}
	return value;
}

- (void) setLimit:(BOOL)value {
	[self setConfigurationValue:[NSNumber numberWithBool:value] forKey:GrowlSmokeLimitPref];
}

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
	if([self.configuration valueForKey:GrowlSmokeScreenPref]){
		value = [[self.configuration valueForKey:GrowlSmokeScreenPref] intValue];
	}
	return value;
}

- (void) setScreen:(int)value {
	[self setConfigurationValue:[NSNumber numberWithInt:value] forKey:GrowlSmokeScreenPref];
}

- (int) size {
	int value = 0;
	if([self.configuration valueForKey:GrowlSmokeSizePref]){
		value = [[self.configuration valueForKey:GrowlSmokeSizePref] intValue];
	}
	return value;
}

- (void) setSize:(int)value {
	[self setConfigurationValue:[NSNumber numberWithInt:value] forKey:GrowlSmokeSizePref];
}

@end
