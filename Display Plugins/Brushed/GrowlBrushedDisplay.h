//
//  GrowlBrushedDisplay.h
//  Display Plugins
//
//  Created by Ingmar Stein on 12/01/2004.
//  Copyright 2004-2005 The Growl Project. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GrowlDisplayProtocol.h>

@class NSPreferencePane;

@interface GrowlBrushedDisplay : NSObject <GrowlDisplayPlugin> {
  NSPreferencePane *preferencePane;
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
