//
//  GrowlWebKitPrefsController.m
//  Growl
//
//  Created by Ingmar Stein on Thu Apr 14 2005.
//  Copyright 2005–2011 The Growl Project. All rights reserved.
//

#import "GrowlWebKitPrefsController.h"
#import "GrowlWebKitDefines.h"
#import "GrowlDefinesInternal.h"
#import "GrowlPluginController.h"

@implementation GrowlWebKitPrefsController

- (id) initWithStyle:(NSString *)styleName {
	if ((self = [self initWithBundle:[NSBundle bundleWithIdentifier:GROWL_HELPERAPP_BUNDLE_IDENTIFIER]])) {
		style = [styleName retain];
		prefDomain = [[NSString alloc] initWithFormat:@"%@.%@", GrowlWebKitPrefDomain, style];
   }
	return self;
}

- (void) dealloc {
	[style      release];
	[prefDomain release];
	[super dealloc];
}

- (NSString *) mainNibName {
	return @"WebKitPrefs";
}

- (void) mainViewDidLoad {
	[slider_opacity setAltIncrementValue:0.05];
}

- (NSSet*)bindingKeys {
	static NSSet *keys = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		keys = [NSSet setWithObjects:@"limit",
				  @"opacity",	
				  @"duration",
				  @"screen", nil];
	});
	return keys;
}

#pragma mark -

- (BOOL) isLimit {
	BOOL value = YES;
	if([self.configuration valueForKey:GrowlWebKitLimitPref]){
		value = [[self.configuration valueForKey:GrowlWebKitLimitPref] boolValue];
	}
	return value;
}

- (void) setLimit:(BOOL)value {
	[self setConfigurationValue:[NSNumber numberWithBool:value] forKey:GrowlWebKitLimitPref];
}

#pragma mark -

- (CGFloat) opacity {
	CGFloat value = 95.0;
	if([self.configuration valueForKey:GrowlWebKitOpacityPref]){
		value = [[self.configuration valueForKey:GrowlWebKitOpacityPref] floatValue];
	}
	return value;
}

- (void) setOpacity:(CGFloat)value {
	[self setConfigurationValue:[NSNumber numberWithFloat:value] forKey:GrowlWebKitOpacityPref];
}

#pragma mark -

- (CGFloat) duration {
	CGFloat value = 4.0;
	if([self.configuration valueForKey:GrowlWebKitDurationPref]){
		value = [[self.configuration valueForKey:GrowlWebKitDurationPref] floatValue];
	}
	return value;
}

- (void) setDuration:(CGFloat)value {
	[self setConfigurationValue:[NSNumber numberWithFloat:value] forKey:GrowlWebKitDurationPref];
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
	if([self.configuration valueForKey:GrowlWebKitScreenPref]){
		value = [[self.configuration valueForKey:GrowlWebKitScreenPref] intValue];
	}
	return value;
}

- (void) setScreen:(int)value {
	[self setConfigurationValue:[NSNumber numberWithInt:value] forKey:GrowlWebKitScreenPref];
}
@end
