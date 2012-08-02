//
//  GrowlMusicVideoPrefs.m
//  Display Plugins
//
//  Created by Jorge Salvador Caffarena on 14/09/04.
//  Copyright 2004 Jorge Salvador Caffarena. All rights reserved.
//

#import "GrowlMusicVideoPrefs.h"
#import "GrowlDefinesInternal.h"

@interface GrowlMusicVideoPrefs ()

@property (nonatomic, retain) NSString *justificationLabel;
@property (nonatomic, retain) NSString *leftJustification;
@property (nonatomic, retain) NSString *rightJustification;

@end

@implementation GrowlMusicVideoPrefs

@synthesize textAlignment;

@synthesize justificationLabel;
@synthesize leftJustification;
@synthesize rightJustification;

-(id)initWithBundle:(NSBundle *)bundle {
	if((self = [super initWithBundle:bundle])){
		self.justificationLabel = NSLocalizedStringFromTableInBundle(@"Justification:", @"Localizable", bundle, @"MusicVideo justification pop up label");
		self.leftJustification = NSLocalizedStringFromTableInBundle(@"Left", @"Localizable", bundle, @"MusicVideo left aligned");
		self.rightJustification = NSLocalizedStringFromTableInBundle(@"Right", @"Localizable", bundle, @"MusicVideo right alligned");
	}
	return self;
}

-(void)dealloc {
	self.justificationLabel = nil;
	self.leftJustification = nil;
	self.rightJustification = nil;
	[super dealloc];
}

- (NSString *) mainNibName {
	return @"GrowlMusicVideoPrefs";
}

- (void) mainViewDidLoad {
	[slider_opacity setAltIncrementValue:5.0];
}

- (NSSet*)bindingKeys {
	static NSSet *keys = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		keys = [[NSSet setWithObjects:@"size",
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
				  @"textColorEmergency", nil] retain];
	});
	return keys;
}

+ (NSSet*)configurationKeyPaths {
	return [NSSet setWithObjects:MUSICVIDEO_SCREEN_PREF,
			  MUSICVIDEO_OPACITY_PREF,
			  MUSICVIDEO_DURATION_PREF,
			  MUSICVIDEO_SIZE_PREF,
			  MUSICVIDEO_EFFECT_PREF,
			  GrowlMusicVideoVeryLowBackgroundColor,
			  GrowlMusicVideoModerateBackgroundColor,
			  GrowlMusicVideoNormalBackgroundColor,
			  GrowlMusicVideoHighBackgroundColor,
			  GrowlMusicVideoEmergencyBackgroundColor,
			  GrowlMusicVideoVeryLowTextColor,
			  GrowlMusicVideoModerateTextColor,
			  GrowlMusicVideoNormalTextColor,
			  GrowlMusicVideoHighTextColor,
			  GrowlMusicVideoEmergencyTextColor, nil];
}

#pragma mark Accessors

- (CGFloat) duration {
	CGFloat value = GrowlMusicVideoDurationPrefDefault;
	if([self.configuration valueForKey:MUSICVIDEO_DURATION_PREF]){
		value = [[self.configuration valueForKey:MUSICVIDEO_DURATION_PREF] floatValue];
	}
	return value;
}
- (void) setDuration:(CGFloat)value {
	[self setConfigurationValue:[NSNumber numberWithFloat:value] forKey:MUSICVIDEO_DURATION_PREF];
}

- (unsigned) effect {
	int effect = 0;
	if([self.configuration valueForKey:MUSICVIDEO_EFFECT_PREF]){
		effect = [[self.configuration valueForKey:MUSICVIDEO_EFFECT_PREF] intValue];
	}
	switch (effect) {
		case MUSICVIDEO_EFFECT_WIPE:
		default:
			effect = MUSICVIDEO_EFFECT_SLIDE;
			
		case MUSICVIDEO_EFFECT_SLIDE:
		case MUSICVIDEO_EFFECT_FADING:
			;
		
	}
	return (unsigned)effect;
}
- (void) setEffect:(unsigned)newEffect {
	switch (newEffect) {
		default:
			NSLog(@"(Music Video) Invalid effect number %u (slide is %u; wipe is %u)", newEffect, MUSICVIDEO_EFFECT_SLIDE, MUSICVIDEO_EFFECT_WIPE);
			break;

		case MUSICVIDEO_EFFECT_WIPE:
			NSLog(@"Wipe not supported");
			newEffect = MUSICVIDEO_EFFECT_SLIDE;
		case MUSICVIDEO_EFFECT_SLIDE:
		case MUSICVIDEO_EFFECT_FADING:
			[self setConfigurationValue:[NSNumber numberWithUnsignedInt:newEffect] forKey:MUSICVIDEO_EFFECT_PREF];
	}
}

- (CGFloat) opacity {
	CGFloat value = MUSICVIDEO_DEFAULT_OPACITY;
	if([self.configuration valueForKey:MUSICVIDEO_OPACITY_PREF]){
		value = [[self.configuration valueForKey:MUSICVIDEO_OPACITY_PREF] floatValue];
	}
	return value;
}
- (void) setOpacity:(CGFloat)value {
	[self setConfigurationValue:[NSNumber numberWithFloat:value] forKey:MUSICVIDEO_OPACITY_PREF];
}

- (int) size {
	int value = 0;
	if([self.configuration valueForKey:MUSICVIDEO_SIZE_PREF]){
		value = [[self.configuration valueForKey:MUSICVIDEO_SIZE_PREF] intValue];
	}
	return value;
}
- (void) setSize:(int)value {
	[self setConfigurationValue:[NSNumber numberWithInt:value] forKey:MUSICVIDEO_SIZE_PREF];
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
	if([self.configuration valueForKey:MUSICVIDEO_SCREEN_PREF]){
		value = [[self.configuration valueForKey:MUSICVIDEO_SCREEN_PREF] intValue];
	}
	return value;
}
- (void) setScreen:(int)value {
	[self setConfigurationValue:[NSNumber numberWithInt:value] forKey:MUSICVIDEO_SCREEN_PREF];
}

- (NSInteger)textAlignment {
	NSTextAlignment align = NSLeftTextAlignment;
	if([self.configuration valueForKey:MUSICVIDEO_TEXT_ALIGN_PREF])
		align = [[self.configuration valueForKey:MUSICVIDEO_TEXT_ALIGN_PREF] integerValue];
	NSInteger value;
	switch (align) {
		case NSLeftTextAlignment:
			value = 0;
			break;
		case NSRightTextAlignment:
			value = 1;
			break;
		default:
			value = 0;
			break;
	}
	return value;
}

- (void)setTextAlignment:(NSInteger)align {
	NSTextAlignment value;
	switch (align) {
		case 0:
			value = NSLeftTextAlignment;
			break;
		case 1:
			value = NSRightTextAlignment;
			break;
		default:
			value = NSLeftTextAlignment;
			break;
	}
	[self setConfigurationValue:[NSNumber numberWithUnsignedLong:value] forKey:MUSICVIDEO_TEXT_ALIGN_PREF];
}

- (NSColor *) textColorVeryLow {
	return [self loadColor:GrowlMusicVideoVeryLowTextColor
							  defaultColor:[NSColor whiteColor]];
}

- (void) setTextColorVeryLow:(NSColor *)value {
	NSData *theData = [NSArchiver archivedDataWithRootObject:value];
	[self setConfigurationValue:theData forKey:GrowlMusicVideoVeryLowTextColor];
}

- (NSColor *) textColorModerate {
	return [self loadColor:GrowlMusicVideoModerateTextColor
							  defaultColor:[NSColor whiteColor]];
}

- (void) setTextColorModerate:(NSColor *)value {
	NSData *theData = [NSArchiver archivedDataWithRootObject:value];
	[self setConfigurationValue:theData forKey:GrowlMusicVideoModerateTextColor];
}

- (NSColor *) textColorNormal {
	return [self loadColor:GrowlMusicVideoNormalTextColor
							  defaultColor:[NSColor whiteColor]];
}

- (void) setTextColorNormal:(NSColor *)value {
	NSData *theData = [NSArchiver archivedDataWithRootObject:value];
	[self setConfigurationValue:theData forKey:GrowlMusicVideoNormalTextColor];
}

- (NSColor *) textColorHigh {
	return [self loadColor:GrowlMusicVideoHighTextColor
							  defaultColor:[NSColor whiteColor]];
}

- (void) setTextColorHigh:(NSColor *)value {
	NSData *theData = [NSArchiver archivedDataWithRootObject:value];
	[self setConfigurationValue:theData forKey:GrowlMusicVideoHighTextColor];
}

- (NSColor *) textColorEmergency {
	return [self loadColor:GrowlMusicVideoEmergencyTextColor
							  defaultColor:[NSColor whiteColor]];
}

- (void) setTextColorEmergency:(NSColor *)value {
	NSData *theData = [NSArchiver archivedDataWithRootObject:value];
	[self setConfigurationValue:theData forKey:GrowlMusicVideoEmergencyTextColor];
}

- (NSColor *) backgroundColorVeryLow {
	return [self loadColor:GrowlMusicVideoVeryLowBackgroundColor
							  defaultColor:[NSColor blackColor]];
}

- (void) setBackgroundColorVeryLow:(NSColor *)value {
	NSData *theData = [NSArchiver archivedDataWithRootObject:value];
	[self setConfigurationValue:theData forKey:GrowlMusicVideoVeryLowBackgroundColor];
}

- (NSColor *) backgroundColorModerate {
	return [self loadColor:GrowlMusicVideoModerateBackgroundColor
							  defaultColor:[NSColor blackColor]];
}

- (void) setBackgroundColorModerate:(NSColor *)value {
	NSData *theData = [NSArchiver archivedDataWithRootObject:value];
	[self setConfigurationValue:theData forKey:GrowlMusicVideoModerateBackgroundColor];
}

- (NSColor *) backgroundColorNormal {
	return [self loadColor:GrowlMusicVideoNormalBackgroundColor
						 defaultColor:[NSColor blackColor]];
}

- (void) setBackgroundColorNormal:(NSColor *)value {
	NSData *theData = [NSArchiver archivedDataWithRootObject:value];
	[self setConfigurationValue:theData forKey:GrowlMusicVideoNormalBackgroundColor];
}

- (NSColor *) backgroundColorHigh {
	return [self loadColor:GrowlMusicVideoHighBackgroundColor
							  defaultColor:[NSColor blackColor]];
}

- (void) setBackgroundColorHigh:(NSColor *)value {
	NSData *theData = [NSArchiver archivedDataWithRootObject:value];
	[self setConfigurationValue:theData forKey:GrowlMusicVideoHighBackgroundColor];
}

- (NSColor *) backgroundColorEmergency {
	return [self loadColor:GrowlMusicVideoEmergencyBackgroundColor
							  defaultColor:[NSColor blackColor]];
}

- (void) setBackgroundColorEmergency:(NSColor *)value {
	NSData *theData = [NSArchiver archivedDataWithRootObject:value];
	[self setConfigurationValue:theData forKey:GrowlMusicVideoEmergencyBackgroundColor];
}
@end
