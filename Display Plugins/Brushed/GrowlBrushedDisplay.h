//
//  GrowlBrushedDisplay.h
//  Display Plugins
//
//  Created by Ingmar Stein on 12/01/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <GrowlDefines.h>
#import <GrowlDisplayProtocol.h>

@class GrowlBrushedPrefsController;

@interface GrowlBrushedDisplay : NSObject <GrowlDisplayPlugin> {
  GrowlBrushedPrefsController *preferencePane;
}

- (void) loadPlugin;
- (NSString *) name;
- (NSString *) userDescription;
- (NSString *) author;
- (NSString *) version;
- (void) unloadPlugin;
- (NSDictionary *) pluginInfo;

- (void) displayNotificationWithInfo:(NSDictionary *)noteDict;
- (void) _brushedGone:(NSNotification *)note;

@end
