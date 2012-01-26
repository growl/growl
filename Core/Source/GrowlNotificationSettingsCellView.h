//
//  GrowlNotificationSettingsCellView.h
//  Growl
//
//  Created by Daniel Siemer on 1/18/12.
//  Copyright (c) 2012 The Growl Project. All rights reserved.
//

#import <AppKit/AppKit.h>

@interface GrowlNotificationSettingsCellView : NSTableCellView

@property (nonatomic, assign) IBOutlet NSButton *enableCheckBox;

-(IBAction)toggleEnabled:(id)sender;

@end
