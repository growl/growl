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

-(void)displayBridge:(GrowlDisplayWindowController*)window reposition:(BOOL)reposition;
-(void)takeDownDisplay:(GrowlDisplayWindowController*)window;

@end
