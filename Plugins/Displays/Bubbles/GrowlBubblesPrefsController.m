//
//  GrowlBubblesPrefsController.m
//  Growl
//
//  Created by Kevin Ballard on 9/7/04.
//  Copyright 2004 TildeSoft. All rights reserved.
//

#import "GrowlBubblesPrefsController.h"
#import "GrowlBubblesDefines.h"
#import "GrowlDefinesInternal.h"

@implementation GrowlBubblesPrefsController
- (NSString *) mainNibName {
	return @"BubblesPrefs";
}

- (void) mainViewDidLoad {
	[slider_opacity setAltIncrementValue:0.05];
}

-(NSSet*)bindingKeys {
	static NSSet *keys = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		keys = [NSSet setWithObjects:@"opacity",
				  @"duration",
				  @"limit",
				  @"screen",
				  @"size", nil]; 
	});
	return keys;
}

-(void)updateConfigurationValues {
	// priority colour settings
	NSColor *defaultColor = [NSColor colorWithCalibratedRed:0.69412 green:0.83147 blue:0.96078 alpha:1.0];
	[color_veryLow setColor:[self loadColor:GrowlBubblesVeryLowColor defaultColor:defaultColor]];
	[color_moderate setColor:[self loadColor:GrowlBubblesModerateColor defaultColor:defaultColor]];
	[color_normal setColor:[self loadColor:GrowlBubblesNormalColor defaultColor:defaultColor]];
	[color_high setColor:[self loadColor:GrowlBubblesHighColor defaultColor:defaultColor]];
	[color_emergency setColor:[self loadColor:GrowlBubblesEmergencyColor defaultColor:defaultColor]];
	
	defaultColor = [[NSColor controlTextColor] colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
	[text_veryLow setColor:[self loadColor:GrowlBubblesVeryLowTextColor defaultColor:defaultColor]];
	[text_moderate setColor:[self loadColor:GrowlBubblesModerateTextColor defaultColor:defaultColor]];
	[text_normal setColor:[self loadColor:GrowlBubblesNormalTextColor defaultColor:defaultColor]];
	[text_high setColor:[self loadColor:GrowlBubblesHighTextColor defaultColor:defaultColor]];
	[text_emergency setColor:[self loadColor:GrowlBubblesEmergencyTextColor defaultColor:defaultColor]];
	
	defaultColor = [NSColor colorWithCalibratedRed:0.93725 green:0.96863 blue:0.99216 alpha:0.95];
	[top_veryLow setColor:[self loadColor:GrowlBubblesVeryLowTopColor defaultColor:defaultColor]];
	[top_moderate setColor:[self loadColor:GrowlBubblesModerateTopColor defaultColor:defaultColor]];
	[top_normal setColor:[self loadColor:GrowlBubblesNormalTopColor defaultColor:defaultColor]];
	[top_high setColor:[self loadColor:GrowlBubblesHighTopColor defaultColor:defaultColor]];
	[top_emergency setColor:[self loadColor:GrowlBubblesEmergencyTopColor defaultColor:defaultColor]];
	
	[super updateConfigurationValues];
}

#pragma mark -

- (BOOL) isLimit {
	BOOL value = YES;
	if([self.configuration valueForKey:GrowlBubblesLimitPref]){
		value = [[self.configuration valueForKey:GrowlBubblesLimitPref] boolValue];
	}
	return value;
}

- (void) setLimit:(BOOL)value {
	[self setConfigurationValue:[NSNumber numberWithBool:value] forKey:GrowlBubblesLimitPref];
}

#pragma mark -

- (CGFloat) opacity {
	CGFloat value = 95.0;
	if([self.configuration valueForKey:GrowlBubblesLimitPref]){
		value = [[self.configuration valueForKey:GrowlBubblesOpacity] floatValue];
	}
	return value;
}

- (void) setOpacity:(CGFloat)value {
	[self setConfigurationValue:[NSNumber numberWithFloat:value] forKey:GrowlBubblesOpacity];
}

#pragma mark -

- (CGFloat) duration {
	CGFloat value = 4.0;
	if([self.configuration valueForKey:GrowlBubblesDuration]){
		value = [[self.configuration valueForKey:GrowlBubblesDuration] floatValue];
	}
	return value;
}

- (void) setDuration:(CGFloat)value {
	[self setConfigurationValue:[NSNumber numberWithFloat:value] forKey:GrowlBubblesDuration];
}

#pragma mark -

- (IBAction) topColorChanged:(id)sender {
	NSColor *color;
	NSString *key;
	switch ([sender tag]) {
		case -2:
			key = GrowlBubblesVeryLowTopColor;
			break;
		case -1:
			key = GrowlBubblesModerateTopColor;
			break;
		case 1:
			key = GrowlBubblesHighTopColor;
			break;
		case 2:
			key = GrowlBubblesEmergencyTopColor;
			break;
		case 0:
		default:
			key = GrowlBubblesNormalTopColor;
			break;
	}

	color = [[sender color] colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
	NSData *theData = [NSArchiver archivedDataWithRootObject:color];
	[self setConfigurationValue:theData forKey:key];
}

- (IBAction) colorChanged:(id)sender {
	NSColor *color;
	NSString *key;
	switch ([sender tag]) {
		case -2:
			key = GrowlBubblesVeryLowColor;
			break;
		case -1:
			key = GrowlBubblesModerateColor;
			break;
		case 1:
			key = GrowlBubblesHighColor;
			break;
		case 2:
			key = GrowlBubblesEmergencyColor;
			break;
		case 0:
		default:
			key = GrowlBubblesNormalColor;
			break;
	}

	color = [[sender color] colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
	NSData *theData = [NSArchiver archivedDataWithRootObject:color];
	[self setConfigurationValue:theData forKey:key];
}

- (IBAction) textColorChanged:(id)sender {
	NSString *key;
	switch ([sender tag]) {
		case -2:
			key = GrowlBubblesVeryLowTextColor;
			break;
		case -1:
			key = GrowlBubblesModerateTextColor;
			break;
		case 1:
			key = GrowlBubblesHighTextColor;
			break;
		case 2:
			key = GrowlBubblesEmergencyTextColor;
			break;
		case 0:
		default:
			key = GrowlBubblesNormalTextColor;
			break;
	}

	NSData *theData = [NSArchiver archivedDataWithRootObject:[sender color]];
	[self setConfigurationValue:theData forKey:key];
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
	if([self.configuration valueForKey:GrowlBubblesScreen]){
		value = [[self.configuration valueForKey:GrowlBubblesScreen] intValue];
	}
	return value;
}

- (void) setScreen:(int)value {
	[self setConfigurationValue:[NSNumber numberWithInt:value] forKey:GrowlBubblesScreen];
}

- (int) size {
	int value = 0;
	if([self.configuration valueForKey:GrowlBubblesSizePref]){
		value = [[self.configuration valueForKey:GrowlBubblesSizePref] intValue];
	}
	return value;
}

- (void) setSize:(int)value {
	[self setConfigurationValue:[NSNumber numberWithInt:value] forKey:GrowlBubblesSizePref];
}
@end
