//
//  GrowlMenuImageView.h
//  Growl
//
//  Created by Daniel Siemer on 10/10/11.
//  Copyright 2011 The Growl Project. All rights reserved.
//

#import <AppKit/AppKit.h>

@class GrowlMenu;

@interface GrowlMenuImageView : NSImageView {
   GrowlMenu *menuItem;
   
   NSImage *mainImage;
   NSImage *alternateImage;
   
   BOOL mouseDown;
}
@property (nonatomic, assign) GrowlMenu* menuItem;
@property (nonatomic, retain) NSImage *mainImage;
@property (nonatomic, retain) NSImage *alternateImage;

@end
