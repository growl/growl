//
//  GrowlDisplayBridgeController.h
//  Growl
//
//  Created by Daniel Siemer on 3/29/12.
//  Copyright (c) 2012 The Growl Project. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GrowlDisplayWindowController;

@interface GrowlDisplayBridgeController : NSObject

+(GrowlDisplayBridgeController*)sharedController;

/* These two methods are used by WebKit displays to hold on to the window while the view generates */
-(void)addPendingWindow:(GrowlDisplayWindowController*)window;
-(void)windowReadyToStart:(GrowlDisplayWindowController*)window;

/* Used for displaying, or repositioning a display */
-(void)displayBridge:(GrowlDisplayWindowController*)window reposition:(BOOL)reposition;

/* Called by didFinishTransitionsAfterDisplay in GrowlDisplayWindowController to finish out the cycle */
-(void)takeDownDisplay:(GrowlDisplayWindowController*)window;

@end
