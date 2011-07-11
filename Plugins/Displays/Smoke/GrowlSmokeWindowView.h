//
//  GrowlSmokeWindowView.h
//  Display Plugins
//
//  Created by Matthew Walton on 11/09/2004.
//  Copyright 2004-2006 The Growl Project. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GrowlNotificationView.h"

@interface GrowlSmokeWindowView : GrowlNotificationView

- (void) setIcon:(NSImage *)icon;
- (void) setTitle:(NSString *)title;
- (void) setText:(NSString *)text;

- (void) setPriority:(int)priority;
- (void) setProgress:(NSNumber *)value;

- (void) sizeToFit;
- (CGFloat) titleHeight;
- (CGFloat) descriptionHeight;
- (NSInteger) descriptionRowCount;
@end
