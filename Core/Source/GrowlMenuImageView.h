//
//  GrowlMenuImageView.h
//  Growl
//
//  Created by Daniel Siemer on 10/10/11.
//  Copyright 2011 The Growl Project. All rights reserved.
//

#import <AppKit/AppKit.h>

@class GrowlMenu;

@interface GrowlMenuImageView : NSView {
   GrowlMenu *menuItem;
   
    NSInteger mode;
    NSInteger previousMode;
    CALayer *mainLayer;
    NSImage *mainImage;
    NSImage *alternateImage;
    NSImage *squelchImage;
    
    BOOL mouseDown;
}

@property (nonatomic, assign) NSInteger mode;
@property (nonatomic, assign) GrowlMenu* menuItem;
@property (nonatomic, retain) CALayer *mainLayer;
@property (nonatomic, assign) BOOL mouseDown;
@property (nonatomic, retain) NSImage *mainImage;
@property (nonatomic, retain) NSImage *alternateImage;
@property (nonatomic, retain) NSImage *squelchImage;


- (void)startAnimation;
- (void)stopAnimation;
@end
