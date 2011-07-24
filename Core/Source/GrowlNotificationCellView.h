//
//  GrowlNotificationCellView.h
//  Growl
//
//  Created by Daniel Siemer on 7/8/11.
//  Copyright 2011 The Growl Project. All rights reserved.
//

#import <AppKit/AppKit.h>

@interface GrowlNotificationCellView : NSTableCellView{
    IBOutlet NSTextField *description;
    IBOutlet NSImageView *icon;
    IBOutlet NSButton *deleteButton;
}
@property (assign) IBOutlet NSTextField *description;
@property (assign) IBOutlet NSImageView *icon;
@property (assign) IBOutlet NSButton *deleteButton;

@end
