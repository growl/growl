//
//  GrowlBubblesController.h
//  Growl
//
//  Created by Nelson Elhage on Wed Jun 09 2004.
//  Name changed from KABubbleController.h by Justin Burns on Fri Nov 05 2004.
//  Copyright (c) 2004 Nelson Elhage. All rights reserved.
//

@class GrowlBubblesPrefsController;

@interface GrowlBubblesController : NSObject <GrowlDisplayPlugin> {
	GrowlBubblesPrefsController *bubblePrefPane;
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
