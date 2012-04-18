//
//  GrowlRollupGroupCellView.h
//  Growl
//
//  Created by Daniel Siemer on 8/13/11.
//  Copyright 2011 The Growl Project. All rights reserved.
//

#import <AppKit/AppKit.h>

@interface GrowlRollupGroupCellView : NSTableCellView

@property (nonatomic, assign) IBOutlet NSButton *deleteButton;
@property (nonatomic, assign) IBOutlet NSButton *revealButton;
@property (nonatomic, assign) IBOutlet NSTextField *countLabel;
@property (nonatomic, assign) IBOutlet NSView *countBubble;

@end
