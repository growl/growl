//
//  GrowlOnSwitch.h
//  GrowlSlider
//
//  Created by Daniel Siemer on 1/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GrowlOnSwitch : NSView

@property (nonatomic, retain) NSView *knob;
@property (nonatomic, retain) NSTextField *onLabel;
@property (nonatomic, retain) NSTextField *offLabel;

@property (nonatomic) BOOL state;
@property (nonatomic) CGPoint mouseLoc;

-(void)updatePosition;
-(void)silentSetState:(BOOL)newState;

@end
