//
//  GrowlBezelDisplay.h
//  Growl Display Plugins
//
//  Copyright 2004 Jorge Salvador Caffarena. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <GrowlDefines.h>
#import <GrowlDisplayProtocol.h>


@interface GrowlBezelDisplay : NSObject <GrowlDisplayPlugin> {
}

- (void)loadPlugin;
- (NSString *) author;
- (NSString *) name;
- (NSString *) userDescription;
- (NSString *) version;
- (void) unloadPlugin;
- (NSDictionary*) pluginInfo;

- (void)  displayNotificationWithInfo:(NSDictionary *) noteDict;

@end
