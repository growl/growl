//
//  GrowlNotificationSettingsCellView.m
//  Growl
//
//  Created by Daniel Siemer on 1/18/12.
//  Copyright (c) 2012 The Growl Project. All rights reserved.
//

#import "GrowlNotificationSettingsCellView.h"

@implementation GrowlNotificationSettingsCellView

@synthesize enableCheckBox;

-(IBAction)toggleEnabled:(id)sender {
   [[self superview] setNeedsDisplay:YES];
}

@end
