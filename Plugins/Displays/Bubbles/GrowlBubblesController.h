//
//  GrowlBubblesController.h
//  Growl
//
//  Created by Nelson Elhage on Wed Jun 09 2004.
//  Name changed from KABubbleController.h by Justin Burns on Fri Nov 05 2004.
//  Copyright (c) 2004 Nelson Elhage. All rights reserved.
//

#import "GrowlDisplayPlugin.h"

@class NSPreferencePane;

@interface GrowlBubblesController : GrowlDisplayPlugin {
}

- (void) displayNotification:(GrowlApplicationNotification *)notification;

@end
