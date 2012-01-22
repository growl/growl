//
//  GrowlNotificationSettingsScrollView.h
//  Growl
//
//  Created by Daniel Siemer on 1/18/12.
//  Copyright (c) 2012 The Growl Project. All rights reserved.
//

#import <AppKit/AppKit.h>

@interface GrowlNotificationTableFadeView : NSView 
@property (nonatomic, retain) NSGradient *gradient;
@property (nonatomic) CGFloat angle;
@end

@interface GrowlNotificationSettingsScrollView : NSScrollView
@property (nonatomic, retain) GrowlNotificationTableFadeView *top;
@property (nonatomic, retain) GrowlNotificationTableFadeView *bottom;
@end
