//
//  GrowlWebKitController.h
//  Growl
//
//  Created by Ingmar Stein on Thu Apr 14 2005.
//  Copyright 2005 The Growl Project. All rights reserved.
//

#import "GrowlDisplayPlugin.h"

@interface GrowlWebKitController : GrowlDisplayPlugin {
	NSString			*style;
}

- (id) initWithStyle:(NSString *)styleName;
- (void) displayNotification:(GrowlApplicationNotification *)notification;

@end
