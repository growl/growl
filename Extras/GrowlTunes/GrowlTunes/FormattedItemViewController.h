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
        
    NSDictionary* _formattedDescription;
	
	NSImage *_icon;
	NSString *_mediaTitle;
	NSString *_details;
}

@property(readwrite, nonatomic, STRONG) NSDictionary* formattedDescription;

@property(nonatomic, STRONG) NSImage* icon;
@property(nonatomic, STRONG) NSString* title;
@property(nonatomic, STRONG) NSString* details;

@end
