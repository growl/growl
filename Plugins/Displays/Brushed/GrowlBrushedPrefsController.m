//
//  GrowlBrushedPrefsController.m
//  Display Plugins
//
//  Created by Ingmar Stein on 12/01/2004.
//  Copyright 2004–2011 The Growl Project. All rights reserved.
//

#import "GrowlBrushedPrefsController.h"
#import "GrowlBrushedDefines.h"
#import "GrowlDefinesInternal.h"

@implementation GrowlBrushedPrefsController

@synthesize useAquaLabel;

- (id)initWithBundle:(NSBundle *)bundle {
   if((self = [super initWithBundle:bundle])){
      self.useAquaLabel = NSLocalizedStringFromTableInBundle(@"Use Aqua instead of brushed metal", @"Localizable", bundle, @"use aqua instead of brushed metal label");
   }
   return self;
}

- (void)dealloc {
   [useAquaLabel release];
   [super dealloc];
}

- (NSSet*)bindingKeys {
	static NSSet *keys = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		keys = [[NSSet setWithObjects:@"limit"		
				  @"floatingIcon",
				  @"duration",
				  @"screen",
				  @"aqua",
				  @"size",
				  @"textColorVeryLow",
				  @"textColorModerate",
				  @"textColorNormal",
				  @"textColorHigh",
				  @"textColorEmergency", nil] retain];
	});
	return keys;
}

- (NSString *) mainNibName {
	return @"BrushedPrefs";
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

#pragma mark -

- (CGFloat) duration {
	CGFloat value = GrowlBrushedDurationPrefDefault;
	if([self.configuration valueForKey:GrowlBrushedDurationPref])
		value = [[self.configuration valueForKey:GrowlBrushedDurationPref] floatValue];
	return value;
}

- (void) setDuration:(CGFloat)value {
	[self setConfigurationValue:[NSNumber numberWithFloat:value] forKey:GrowlBrushedDurationPref];
}

#pragma mark priority color settings

- (NSColor *) textColorVeryLow {
	return [self loadColor:GrowlBrushedVeryLowTextColor
				 defaultColor:[NSColor colorWithCalibratedWhite:0.1 alpha:1.0]];
}

- (void) setTextColorVeryLow:(NSColor *)value {
	NSData *theData = [NSArchiver archivedDataWithRootObject:value];
	[self setConfigurationValue:theData forKey:GrowlBrushedVeryLowTextColor];
}

- (NSColor *) textColorModerate {
	return [self loadColor:GrowlBrushedModerateTextColor
				 defaultColor:[NSColor colorWithCalibratedWhite:0.1 alpha:1.0]];
}

- (void) setTextColorModerate:(NSColor *)value {
	NSData *theData = [NSArchiver archivedDataWithRootObject:value];
	[self setConfigurationValue:theData forKey:GrowlBrushedModerateTextColor];
}

- (NSColor *) textColorNormal {
	return [self loadColor:GrowlBrushedNormalTextColor
				 defaultColor:[NSColor colorWithCalibratedWhite:0.1 alpha:1.0]];
}

- (void) setTextColorNormal:(NSColor *)value {
	NSData *theData = [NSArchiver archivedDataWithRootObject:value];
	[self setConfigurationValue:theData forKey:GrowlBrushedNormalTextColor];
}

- (NSColor *) textColorHigh {
	return [self loadColor:GrowlBrushedHighTextColor
				 defaultColor:[NSColor colorWithCalibratedWhite:0.1 alpha:1.0]];
}

- (void) setTextColorHigh:(NSColor *)value {
	NSData *theData = [NSArchiver archivedDataWithRootObject:value];
	[self setConfigurationValue:theData forKey:GrowlBrushedHighTextColor];
}

- (NSColor *) textColorEmergency {
	return [self loadColor:GrowlBrushedEmergencyTextColor
				 defaultColor:[NSColor colorWithCalibratedWhite:0.1 alpha:1.0]];
}

- (void) setTextColorEmergency:(NSColor *)value {
	NSData *theData = [NSArchiver archivedDataWithRootObject:value];
	[self setConfigurationValue:theData forKey:GrowlBrushedEmergencyTextColor];
}

#pragma mark -

- (int) screen {
	int value = 0;
	if([self.configuration valueForKey:GrowlBrushedScreenPref]){
		value = [[self.configuration valueForKey:GrowlBrushedScreenPref] intValue];
	}
	return value;
}

- (void) setScreen:(int)value {
	[self setConfigurationValue:[NSNumber numberWithInt:value] forKey:GrowlBrushedScreenPref];
}

#pragma mark -

- (BOOL) isFloatingIcon {
	BOOL value = GrowlBrushedFloatIconPrefDefault;
	if([self.configuration valueForKey:GrowlBrushedFloatIconPref]){
		value = [[self.configuration valueForKey:GrowlBrushedFloatIconPref] boolValue];
	}
	return value;
}

- (void) setFloatingIcon:(BOOL)value {
	[self setConfigurationValue:[NSNumber numberWithBool:value] forKey:GrowlBrushedFloatIconPref];
}

#pragma mark -

- (BOOL) isLimit {
	BOOL value = GrowlBrushedLimitPrefDefault;
	if([self.configuration valueForKey:GrowlBrushedLimitPref]){
		value = [[self.configuration valueForKey:GrowlBrushedLimitPref] boolValue];
	}
	return value;
}

- (void) setLimit:(BOOL)value {
	[self setConfigurationValue:[NSNumber numberWithBool:value] forKey:GrowlBrushedLimitPref];
}

#pragma mark -

- (BOOL) isAqua {
	BOOL value = GrowlBrushedAquaPrefDefault;
	if([self.configuration valueForKey:GrowlBrushedAquaPref]){
		value = [[self.configuration valueForKey:GrowlBrushedAquaPref] boolValue];
	}
	return value;
}

- (void) setAqua:(BOOL)value {
	[self setConfigurationValue:[NSNumber numberWithBool:value] forKey:GrowlBrushedAquaPref];
}

- (int) size {
	int value = 0;
	if([self.configuration valueForKey:GrowlBrushedSizePref]){
		value = [[self.configuration valueForKey:GrowlBrushedSizePref] intValue];
	}
	return value;
}

- (void) setSize:(int)value {
	[self setConfigurationValue:[NSNumber numberWithInt:value] forKey:GrowlBrushedSizePref];
}

@end
