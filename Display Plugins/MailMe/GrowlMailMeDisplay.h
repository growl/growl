//
//  GrowlMailMeDisplay.h
//  Growl Display Plugins
//
//  Copyright 2004 Mac-arena the Bored Zo. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Message/NSMailDelivery.h>
#import <GrowlDefinesInternal.h>
#import <GrowlDisplayProtocol.h>

@class GrowlMailMePrefs;

@interface GrowlMailMeDisplay: NSObject <GrowlDisplayPlugin>
{
	NSString			*destAddress;
	GrowlMailMePrefs	*prefPane;
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
