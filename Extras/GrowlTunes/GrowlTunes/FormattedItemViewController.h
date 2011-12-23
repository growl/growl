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

@property(readwrite, nonatomic, retain) IBOutlet NSDictionary* formattedDescription;

@property(readonly, nonatomic, retain) IBOutlet NSImage* icon;
@property(readonly, nonatomic, retain) IBOutlet NSString* title;
@property(readonly, nonatomic, retain) IBOutlet NSString* details;

@end
