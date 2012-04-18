//
//  FormattedItemViewController.h
//  GrowlTunes
//
//  Created by Travis Tilley on 12/12/11.
//  Copyright (c) 2011 The Growl Project. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "macros.h"

@interface FormattedItemViewController : NSViewController {
    @private
    
    NSImageView* _artworkView;
    NSTextField* _titleField;
    NSTextField* _detailsField;
    
    NSDictionary* _formattedDescription;
}

@property(readwrite, nonatomic, STRONG) IBOutlet NSDictionary* formattedDescription;

@property(readonly, nonatomic, STRONG) IBOutlet NSImage* icon;
@property(readonly, nonatomic, STRONG) IBOutlet NSString* title;
@property(readonly, nonatomic, STRONG) IBOutlet NSString* details;

@end
