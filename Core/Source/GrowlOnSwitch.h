//
//  GrowlOnSwitch.h
//  GrowlSlider
//
//  Created by Daniel Siemer on 1/10/12.
//  Copyright (c) 2012 The Growl Project, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

#define knobInset 1.0f
#define knobDoubleInset (2.0f * knobInset)
#define onSwitchRadius 6.0f

@class GrowlOnSwitchKnob;

@interface GrowlOnSwitch : NSControl

@property (nonatomic, retain) GrowlOnSwitchKnob *knob;
@property (nonatomic, retain) NSTextField *onLabel;
@property (nonatomic, retain) NSTextField *offLabel;

@property (nonatomic) BOOL state;
@property (nonatomic) CGPoint mouseLoc;

-(void)updatePosition;
-(void)silentSetState:(BOOL)newState;

@end
