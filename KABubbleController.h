//
//  KABubbleController.h
//  Growl
//
//  Created by Nelson Elhage on Wed Jun 09 2004.
//  Copyright (c) 2004 Nelson Elhage. All rights reserved.
//

@class BubblePrefsController;

@interface KABubbleController : NSObject <GrowlDisplayPlugin> {
	BubblePrefsController *prefsController;
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
