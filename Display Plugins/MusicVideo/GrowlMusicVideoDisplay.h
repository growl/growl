//
//  GrowlMusicVideoDisplay.h
//  Growl Display Plugins
//
//  Copyright 2004 Jorge Salvador Caffarena. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <GrowlDefinesInternal.h>
#import <GrowlDisplayProtocol.h>

@class GrowlMusicVideoPrefs;

@interface GrowlMusicVideoDisplay : NSObject <GrowlDisplayPlugin> {
	NSMutableArray			*notificationQueue;
	GrowlMusicVideoPrefs	*musicVideoPrefPane;
}

- (void) loadPlugin;
- (NSString *) author;
- (NSString *) name;
- (NSString *) userDescription;
- (NSString *) version;
- (void) unloadPlugin;
- (NSDictionary*) pluginInfo;

- (void) displayNotificationWithInfo:(NSDictionary *) noteDict;

@end
