//
//  GrowlSmokeDisplay.h
//  Display Plugins
//
//  Created by Matthew Walton on 09/09/2004.
//  Copyright 2004 The Growl Project. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <GrowlDefines.h>
#import <GrowlDisplayProtocol.h>

@class GrowlSmokePrefsController;

@interface GrowlSmokeDisplay : NSObject <GrowlDisplayPlugin> {
  GrowlSmokePrefsController *preferencePane;
}

- (void) loadPlugin;
- (NSString *) name;
- (NSString *) userDescription;
- (NSString *) author;
- (NSString *) version;
- (void) unloadPlugin;
- (NSDictionary *) pluginInfo;

- (void) displayNotificationWithInfo:(NSDictionary *)noteDict;
- (void) _smokeGone:(NSNotification *)note;

@end
