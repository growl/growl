//
//  GrowlNanoPrefs.m
//  Display Plugins
//
//  Created by Rudy Richter on 12/12/2005.
//  Copyright 2005Ð2011, The Growl Project. All rights reserved.
//


#import "GrowlNanoPrefs.h"
#import "GrowlDefinesInternal.h"

@implementation GrowlNanoPrefs

- (NSString *) mainNibName {
	return @"GrowlNanoPrefs";
}

- (void) mainViewDidLoad {
	[slider_opacity setAltIncrementValue:5.0];
}

- (NSSet*)bindingKeys {
	static NSSet *keys = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		keys = [NSSet setWithObjects:@"size",
				  @"opacity",	
				  @"duration",
				  @"screen",
				  @"effect",
				  @"backgroundColorVeryLow",
				  @"backgroundColorModerate",	
				  @"backgroundColorNormal",
				  @"backgorundColorHigh",	
				  @"backgroundColorEmergency",
				  @"textColorVeryLow",
				  @"textColorModerate",	
				  @"textColorNormal",
				  @"textColorHigh",	
				  @"textColorEmergency", nil];
	});
	return keys;
}

#pragma mark Accessors

- (CGFloat) duration {
	CGFloat value = GrowlNanoDurationPrefDefault;
	if([self.configuration valueForKey:Nano_DURATION_PREF]){
		value = [[self.configuration valueForKey:Nano_DURATION_PREF] floatValue];
	}
	return value;
}
- (void) setDuration:(CGFloat)value {
	[self setConfigurationValue:[NSNumber numberWithFloat:value] forKey:Nano_DURATION_PREF];
}

- (unsigned) effect {
	int effect = 0;
	if([self.configuration valueForKey:Nano_EFFECT_PREF]){
		effect = [[self.configuration valueForKey:Nano_EFFECT_PREF] unsignedIntValue];
	}
	switch (effect) {
		default:
			effect = Nano_EFFECT_SLIDE;
			
		case Nano_EFFECT_SLIDE:
		case Nano_EFFECT_WIPE:
			;
	}
	return (unsigned)effect;
}
- (void) setEffect:(unsigned)newEffect {
	switch (newEffect) {
		default:
			NSLog(@"(Nano) Invalid effect number %u", newEffect);
			break;
			
		case Nano_EFFECT_SLIDE:
		case Nano_EFFECT_WIPE:
		case Nano_EFFECT_FADE:
			[self setConfigurationValue:[NSNumber numberWithUnsignedInt:newEffect] forKey:Nano_EFFECT_PREF];
	}
}

- (CGFloat) opacity {
	CGFloat value = Nano_DEFAULT_OPACITY;
	if([self.configuration valueForKey:Nano_OPACITY_PREF]){
		value = [[self.configuration valueForKey:Nano_OPACITY_PREF] floatValue];
	}
	return value;
}
- (void) setOpacity:(CGFloat)value {
	[self setConfigurationValue:[NSNumber numberWithFloat:value] forKey:Nano_OPACITY_PREF];
}

- (int) size {
	int value = 0;
	if([self.configuration valueForKey:Nano_SIZE_PREF]){
		value = [[self.configuration valueForKey:Nano_SIZE_PREF] intValue];
	}
	return value;
}
- (void) setSize:(int)value {
	[self setConfigurationValue:[NSNumber numberWithInt:value] forKey:Nano_SIZE_PREF];
}

#pragma mark Combo box support

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
	if([self.configuration valueForKey:Nano_SCREEN_PREF]){
		value = [[self.configuration valueForKey:Nano_SCREEN_PREF] intValue];
	}
	return value;
}
- (void) setScreen:(int)value {
	[self setConfigurationValue:[NSNumber numberWithInt:value] forKey:Nano_SCREEN_PREF];
}

- (NSColor *) textColorVeryLow {
	return [self loadColor:GrowlNanoVeryLowTextColor
				 defaultColor:[NSColor whiteColor]];
}

- (void) setTextColorVeryLow:(NSColor *)value {
	NSData *theData = [NSArchiver archivedDataWithRootObject:value];
	[self setConfigurationValue:theData forKey:GrowlNanoVeryLowTextColor];
}

- (NSColor *) textColorModerate {
	return [self loadColor:GrowlNanoModerateTextColor
				 defaultColor:[NSColor whiteColor]];
}

- (void) setTextColorModerate:(NSColor *)value {
	NSData *theData = [NSArchiver archivedDataWithRootObject:value];
	[self setConfigurationValue:theData forKey:GrowlNanoModerateTextColor];
}

- (NSColor *) textColorNormal {
	return [self loadColor:GrowlNanoNormalTextColor
				 defaultColor:[NSColor whiteColor]];
}

- (void) setTextColorNormal:(NSColor *)value {
	NSData *theData = [NSArchiver archivedDataWithRootObject:value];
	[self setConfigurationValue:theData forKey:GrowlNanoNormalTextColor];
}

- (NSColor *) textColorHigh {
	return [self loadColor:GrowlNanoHighTextColor
				 defaultColor:[NSColor whiteColor]];
}

- (void) setTextColorHigh:(NSColor *)value {
	NSData *theData = [NSArchiver archivedDataWithRootObject:value];
	[self setConfigurationValue:theData forKey:GrowlNanoHighTextColor];
}

- (NSColor *) textColorEmergency {
	return [self loadColor:GrowlNanoEmergencyTextColor
				 defaultColor:[NSColor whiteColor]];
}

- (void) setTextColorEmergency:(NSColor *)value {
	NSData *theData = [NSArchiver archivedDataWithRootObject:value];
	[self setConfigurationValue:theData forKey:GrowlNanoEmergencyTextColor];
}

- (NSColor *) backgroundColorVeryLow {
	return [self loadColor:GrowlNanoVeryLowBackgroundColor
				 defaultColor:[NSColor blackColor]];
}

- (void) setBackgroundColorVeryLow:(NSColor *)value {
	NSData *theData = [NSArchiver archivedDataWithRootObject:value];
	[self setConfigurationValue:theData forKey:GrowlNanoVeryLowBackgroundColor];
}

- (NSColor *) backgroundColorModerate {
	return [self loadColor:GrowlNanoModerateBackgroundColor
				 defaultColor:[NSColor blackColor]];
}

- (void) setBackgroundColorModerate:(NSColor *)value {
	NSData *theData = [NSArchiver archivedDataWithRootObject:value];
	[self setConfigurationValue:theData forKey:GrowlNanoModerateBackgroundColor];
}

- (NSColor *) backgroundColorNormal {
	return [self loadColor:GrowlNanoNormalBackgroundColor
				 defaultColor:[NSColor blackColor]];
}

- (void) setBackgroundColorNormal:(NSColor *)value {
	NSData *theData = [NSArchiver archivedDataWithRootObject:value];
	[self setConfigurationValue:theData forKey:GrowlNanoNormalBackgroundColor];
}

- (NSColor *) backgroundColorHigh {
	return [self loadColor:GrowlNanoHighBackgroundColor
				 defaultColor:[NSColor blackColor]];
}

- (void) setBackgroundColorHigh:(NSColor *)value {
	NSData *theData = [NSArchiver archivedDataWithRootObject:value];
	[self setConfigurationValue:theData forKey:GrowlNanoHighBackgroundColor];
}

- (NSColor *) backgroundColorEmergency {
	return [self loadColor:GrowlNanoEmergencyBackgroundColor
				 defaultColor:[NSColor blackColor]];
}

- (void) setBackgroundColorEmergency:(NSColor *)value {
	NSData *theData = [NSArchiver archivedDataWithRootObject:value];
	[self setConfigurationValue:theData forKey:GrowlNanoEmergencyBackgroundColor];
}
@end
