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

#define GrowliCalColorPurple NSLocalizedString(@"Purple", nil)
#define GrowliCalColorPink NSLocalizedString(@"Pink", nil)
#define GrowliCalColorGreen NSLocalizedString(@"Green", nil)
#define GrowliCalColorBlue NSLocalizedString(@"Blue", nil)
#define GrowliCalColorOrange NSLocalizedString(@"Orange", nil)
#define GrowliCalColorRed NSLocalizedString(@"Red", nil)

@implementation GrowliCalPrefsController

@synthesize colorLabel;
@synthesize colorNames;

-(id)initWithBundle:(NSBundle *)bundle {
   if((self = [super initWithBundle:bundle])){
      self.colorLabel = NSLocalizedString(@"Color:", @"Label for pop up button to choose color");
      self.colorNames = [NSArray arrayWithObjects:GrowliCalColorPurple, 
                                                  GrowliCalColorPink, 
                                                  GrowliCalColorGreen, 
                                                  GrowliCalColorBlue, 
                                                  GrowliCalColorOrange, 
                                                  GrowliCalColorRed, nil];
   }
   return self;
}

- (void)dealloc {
   [colorLabel release];
   [colorNames release];
   [super dealloc];
}

- (NSString *) mainNibName {
	return @"iCalPrefs";
}

+ (NSSet*)bindingKeys {
	static NSSet *keys = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		keys = [NSSet setWithObjects:@"color",
				  @"opacity",
				  @"duration",
				  @"limit",
				  @"screen",
				  @"size", nil];
	});
	return keys;
}

//make sure we set up our settings prior to the PrefPane view actually loading, or we risk not having our controls display correctly
- (void) willSelect {
	[slider_opacity setAltIncrementValue:0.05];
}

#pragma mark -

- (BOOL) isLimit {
	BOOL value = YES;
	if([self.configuration valueForKey:GrowliCalLimitPref]){
		value = [[self.configuration valueForKey:GrowliCalLimitPref] boolValue];
	}
	return value;
}

- (void) setLimit:(BOOL)value {
	[self setConfigurationValue:[NSNumber numberWithBool:value] forKey:GrowliCalLimitPref];
}

#pragma mark -

- (CGFloat) opacity {
	CGFloat value = 95.0;
	if([self.configuration valueForKey:GrowliCalOpacity]){
		value = [[self.configuration valueForKey:GrowliCalOpacity] floatValue];
	}
	return value;
}

- (void) setOpacity:(CGFloat)value {
	[self setConfigurationValue:[NSNumber numberWithFloat:value] forKey:GrowliCalOpacity];
}

#pragma mark -

- (CGFloat) duration {
	CGFloat value = 4.0;
	if([self.configuration valueForKey:GrowliCalDuration]){
		value = [[self.configuration valueForKey:GrowliCalDuration] floatValue];
	}
	return value;
}

- (void) setDuration:(CGFloat)value {
	[self setConfigurationValue:[NSNumber numberWithFloat:value] forKey:GrowliCalDuration];
}

#pragma mark -
- (GrowliCalColorType)color
{
	GrowliCalColorType color = GrowliCalPurple;
	if([self.configuration valueForKey:GrowliCalColor]){
		color = [[self.configuration valueForKey:GrowliCalColor] intValue];
	}
	return color;
}
- (void)setColor:(GrowliCalColorType)color
{
	[self setConfigurationValue:[NSNumber numberWithInt:color] forKey:GrowliCalColor];
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
	if([self.configuration valueForKey:GrowliCalScreen]){
		value = [[self.configuration valueForKey:GrowliCalScreen] intValue];
	}
	return value;
}

- (void) setScreen:(int)value {
	[self setConfigurationValue:[NSNumber numberWithInt:value] forKey:GrowliCalScreen];
}

- (int) size {
	int value = 0;
	if([self.configuration valueForKey:GrowliCalSizePref]){
		value = [[self.configuration valueForKey:GrowliCalSizePref] intValue];
	}
	return value;
}

- (void) setSize:(int)value {
	[self setConfigurationValue:[NSNumber numberWithInt:value] forKey:GrowliCalSizePref];
}
@end
