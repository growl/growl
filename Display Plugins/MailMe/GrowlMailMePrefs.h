//
//  GrowlMailMePrefs.h
//  Display Plugins
//
//  Copyright 2004 Mac-arena the Bored Zo. All rights reserved.
//

#import <PreferencePanes/PreferencePanes.h>

@interface GrowlMailMePrefs: NSPreferencePane
{
	NSMutableString *destAddress;
}

- (NSString *) getDestAddress;
- (void) setDestAddress:(NSString *)value;

@end
