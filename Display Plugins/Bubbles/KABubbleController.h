//
//  KABubbleController.h
//  Growl
//
//  Created by Nelson Elhage on Wed Jun 09 2004.
//  Copyright (c) 2004 Nelson Elhage. All rights reserved.
//

@class BubblePrefs;

@interface KABubbleController : NSObject <GrowlDisplayPlugin> {
	BubblePrefs *bubblePrefPane;
}

#pragma mark Growl Gets Satisfaction

- (void) loadPlugin;
- (NSString *) author;
- (NSString *) name;
- (NSString *) userDescription;
- (NSString *) version;
- (void) unloadPlugin;
- (NSDictionary*) pluginInfo;

- (void)  displayNotificationWithInfo:(NSDictionary *) noteDict;

@end
