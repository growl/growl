//
//  GrowlMailMeDisplay.h
//  Growl Display Plugins
//
//  Copyright 2004 Mac-arena the Bored Zo. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NSPreferencePane;

@interface GrowlMailMeDisplay: NSObject <GrowlDisplayPlugin>
{
	NSString			*destAddress;
	NSPreferencePane	*prefPane;
}

- (void) loadPlugin;
- (void) unloadPlugin;

- (NSString *) author;
- (NSString *) name;
- (NSString *) userDescription;
- (NSString *) version;
- (NSDictionary *) pluginInfo;

- (void) displayNotificationWithInfo:(NSDictionary *) noteDict;

@end
