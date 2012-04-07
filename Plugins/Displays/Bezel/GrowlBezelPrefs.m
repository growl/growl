//
//  GrowlBezelPrefs.m
//  Display Plugins
//
//  Created by Jorge Salvador Caffarena on 14/09/04.
//  Copyright 2004 Jorge Salvador Caffarena. All rights reserved.
//

#import "GrowlBezelPrefs.h"
#import "GrowlDefinesInternal.h"

#define bezelPositionDefault NSLocalizedStringFromTableInBundle(@"Default", @"Localizable", bundle, @"Default position option")
#define bezelPositionTopRight NSLocalizedStringFromTableInBundle(@"Top Right", @"Localizable", bundle, @"Top right position option")
#define bezelPositionBottomRight NSLocalizedStringFromTableInBundle(@"Bottom Right", @"Localizable", bundle, @"Bottom right position option")
#define bezelPositionBottomLeft NSLocalizedStringFromTableInBundle(@"Bottom Left", @"Localizable", bundle, @"Bottom Left position option")
#define bezelPositionTopLeft NSLocalizedStringFromTableInBundle(@"Top Left", @"Localizable", bundle, @"Top left position option")

@implementation GrowlBezelPrefs

@synthesize styleLabel;
@synthesize positionLabel;
@synthesize shrinkLabel;
@synthesize flipLabel;

@synthesize styleDefault;
@synthesize styleCharcoal;

@synthesize positionStrings;

-(id)initWithBundle:(NSBundle *)bundle {
   if((self = [super initWithBundle:bundle])){
      self.styleLabel = NSLocalizedStringFromTableInBundle(@"Style:", @"Localizable", bundle, @"Label for bezel style picker");
      self.positionLabel = NSLocalizedStringFromTableInBundle(@"Position:", @"Localizable", bundle, @"Label for position picker");
      self.shrinkLabel = NSLocalizedStringFromTableInBundle(@"Shrink", @"Localizable", bundle, @"Shrink checkbox label");
      self.flipLabel = NSLocalizedStringFromTableInBundle(@"Flip", @"Localizable", bundle, @"Flip checkbox label");
      
      self.styleDefault = NSLocalizedStringFromTableInBundle(@"Default", @"Localizable", bundle, @"Default style option");
      self.styleCharcoal = NSLocalizedStringFromTableInBundle(@"Charcoal", @"Localizable", bundle, @"Charcoal style option");
      
      self.positionStrings = [NSArray arrayWithObjects:bezelPositionDefault,
                                                       bezelPositionTopRight,
                                                       bezelPositionBottomRight,
                                                       bezelPositionBottomLeft,
                                                       bezelPositionTopLeft, nil];
   }
   return self;
}

- (void)dealloc {
   [styleLabel release];
   [positionLabel release];
   [shrinkLabel release];
   [flipLabel release];
   
   [styleDefault release];
   [styleCharcoal release];
   
   [positionStrings release];
   [super dealloc];
}

- (NSString *) mainNibName {
	return @"GrowlBezelPrefs";
}

- (void) mainViewDidLoad {
	[slider_opacity setAltIncrementValue:5.0];
}

- (NSSet*)bindingKeys {
	static NSSet *keys = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		keys = [[NSSet setWithObjects:@"position",
				  @"size",
				  @"opacity",	
				  @"duration",
				  @"screen",
				  @"style",
				  @"shrink",	
				  @"flip",
				  @"backgroundColorVeryLow",
				  @"backgroundColorModerate",	
				  @"backgroundColorNormal",
				  @"backgorundColorHigh",	
				  @"backgroundColorEmergency",
				  @"textColorVeryLow",
				  @"textColorModerate",	
				  @"textColorNormal",
				  @"textColorHigh",	
				  @"textColorEmergency", nil] retain];
	});
	return keys;
}

#pragma mark -

- (CGFloat) opacity {
	CGFloat value = BEZEL_OPACITY_DEFAULT;
	if([self.configuration valueForKey:BEZEL_OPACITY_PREF]){
		value = [[self.configuration valueForKey:BEZEL_OPACITY_PREF] floatValue];
	}
	return value;
}

- (void) setOpacity:(CGFloat)value {
	[self setConfigurationValue:[NSNumber numberWithFloat:value] forKey:BEZEL_OPACITY_PREF];
}

#pragma mark -

- (CGFloat) duration {
	CGFloat value = 3.0;
	if([self.configuration valueForKey:GrowlBezelDuration]){
		value = [[self.configuration valueForKey:GrowlBezelDuration] floatValue];
	}
	return value;
}

- (void) setDuration:(CGFloat)value {
	[self setConfigurationValue:[NSNumber numberWithFloat:value] forKey:GrowlBezelDuration];
}

#pragma mark -

- (int) size {
	int value = 0;
	if([self.configuration valueForKey:BEZEL_SIZE_PREF]){
		value = [[self.configuration valueForKey:BEZEL_SIZE_PREF] intValue];
	}
	return value;
}

- (void) setSize:(int)value {
	[self setConfigurationValue:[NSNumber numberWithInt:value] forKey:BEZEL_SIZE_PREF];
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
	if([self.configuration valueForKey:BEZEL_SCREEN_PREF]){
		value = [[self.configuration valueForKey:BEZEL_SCREEN_PREF] intValue];
	}
	return value;
}

- (void) setScreen:(int)value {
	[self setConfigurationValue:[NSNumber numberWithInt:value] forKey:BEZEL_SCREEN_PREF];
}

#pragma mark -

- (int) style {
	int value = 0;
	if([self.configuration valueForKey:BEZEL_STYLE_PREF]){
		value = [[self.configuration valueForKey:BEZEL_STYLE_PREF] intValue];
	}
	return value;
}

- (void) setStyle:(int)value {
	[self setConfigurationValue:[NSNumber numberWithInt:value] forKey:BEZEL_STYLE_PREF];
}

#pragma mark -

- (int) position {
	int value = BEZEL_POSITION_DEFAULT;
	if([self.configuration valueForKey:BEZEL_POSITION_PREF]){
		value = [[self.configuration valueForKey:BEZEL_POSITION_PREF] intValue];
	}
	return value;
}

- (void) setPosition:(int)value {
	[self setConfigurationValue:[NSNumber numberWithInt:value] forKey:BEZEL_POSITION_PREF];
}

#pragma mark -

- (BOOL) shrink {
	BOOL shrink = BEZEL_FLIP_DEFAULT;
	if([self.configuration valueForKey:BEZEL_SHRINK_PREF]){
		shrink = [[self.configuration valueForKey:BEZEL_SHRINK_PREF] boolValue];
	}
	return shrink;
}

- (void) setShrink:(BOOL)flag {
	[self setConfigurationValue:[NSNumber numberWithBool:flag] forKey:BEZEL_SHRINK_PREF];
}

#pragma mark -

- (BOOL) flip {
	BOOL flip = BEZEL_FLIP_DEFAULT;
	if([self.configuration valueForKey:BEZEL_FLIP_PREF]){
		flip = [[self.configuration valueForKey:BEZEL_FLIP_PREF] boolValue];
	}
	return flip;
}

- (void) setFlip:(BOOL)flag {
	[self setConfigurationValue:[NSNumber numberWithBool:flag] forKey:BEZEL_FLIP_PREF];
}

#pragma mark -

- (NSColor *) textColorVeryLow {
	return [self loadColor:GrowlBezelVeryLowTextColor
				 defaultColor:[NSColor whiteColor]];
}

- (void) setTextColorVeryLow:(NSColor *)value {
	NSData *theData = [NSArchiver archivedDataWithRootObject:value];
	[self setValue:theData forKey:GrowlBezelVeryLowTextColor];
}

- (NSColor *) textColorModerate {
	return [self loadColor:GrowlBezelModerateTextColor
				 defaultColor:[NSColor whiteColor]];
}

- (void) setTextColorModerate:(NSColor *)value {
	NSData *theData = [NSArchiver archivedDataWithRootObject:value];
	[self setValue:theData forKey:GrowlBezelModerateTextColor];
}

- (NSColor *) textColorNormal {
	return [self loadColor:GrowlBezelNormalTextColor
				 defaultColor:[NSColor whiteColor]];
}

- (void) setTextColorNormal:(NSColor *)value {
	NSData *theData = [NSArchiver archivedDataWithRootObject:value];
	[self setValue:theData forKey:GrowlBezelNormalTextColor];
}

- (NSColor *) textColorHigh {
	return [self loadColor:GrowlBezelHighTextColor
				 defaultColor:[NSColor whiteColor]];
}

- (void) setTextColorHigh:(NSColor *)value {
	NSData *theData = [NSArchiver archivedDataWithRootObject:value];
	[self setValue:theData forKey:GrowlBezelHighTextColor];
}

- (NSColor *) textColorEmergency {
	return [self loadColor:GrowlBezelEmergencyTextColor
				 defaultColor:[NSColor whiteColor]];
}

- (void) setTextColorEmergency:(NSColor *)value {
	NSData *theData = [NSArchiver archivedDataWithRootObject:value];
	[self setValue:theData forKey:GrowlBezelEmergencyTextColor];
}

#pragma mark -

- (NSColor *) backgroundColorVeryLow {
	return [self loadColor:GrowlBezelVeryLowBackgroundColor
				 defaultColor:[NSColor blackColor]];
}

- (void) setBackgroundColorVeryLow:(NSColor *)value {
	NSData *theData = [NSArchiver archivedDataWithRootObject:value];
	[self setValue:theData forKey:GrowlBezelVeryLowBackgroundColor];
}

- (NSColor *) backgroundColorModerate {
	return [self loadColor:GrowlBezelModerateBackgroundColor
				 defaultColor:[NSColor blackColor]];
}

- (void) setBackgroundColorModerate:(NSColor *)value {
	NSData *theData = [NSArchiver archivedDataWithRootObject:value];
	[self setValue:theData forKey:GrowlBezelModerateBackgroundColor];
}

- (NSColor *) backgroundColorNormal {
	return [self loadColor:GrowlBezelNormalBackgroundColor
				 defaultColor:[NSColor blackColor]];
}

- (void) setBackgroundColorNormal:(NSColor *)value {
	NSData *theData = [NSArchiver archivedDataWithRootObject:value];
	[self setValue:theData forKey:GrowlBezelNormalBackgroundColor];
}

- (NSColor *) backgroundColorHigh {
	return [self loadColor:GrowlBezelHighBackgroundColor
				 defaultColor:[NSColor blackColor]];
}

- (void) setBackgroundColorHigh:(NSColor *)value {
	NSData *theData = [NSArchiver archivedDataWithRootObject:value];
	[self setValue:theData forKey:GrowlBezelHighBackgroundColor];
}

- (NSColor *) backgroundColorEmergency {
	return [self loadColor:GrowlBezelEmergencyBackgroundColor
				 defaultColor:[NSColor blackColor]];
}

- (void) setBackgroundColorEmergency:(NSColor *)value {
	NSData *theData = [NSArchiver archivedDataWithRootObject:value];
	[self setValue:theData forKey:GrowlBezelEmergencyBackgroundColor];
}
@end
