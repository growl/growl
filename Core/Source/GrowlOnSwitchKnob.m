//
//  GrowlOnSwitchKnob.m
//  GrowlSlider
//
//  Created by Daniel Siemer on 1/10/12.
//  Copyright (c) 2012 The Growl Project, LLC. All rights reserved.
//

#import "GrowlOnSwitchKnob.h"
#import "GrowlOnSwitch.h"

@implementation GrowlOnSwitchKnob

@synthesize pressed;

- (id)initWithFrame:(NSRect)frame
{
    if((self = [super initWithFrame:frame])){
        // Initialization code here.
       pressed = NO;
    }
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
   CGRect inset = CGRectInset([self bounds], 1.0, 1.0);
   NSBezierPath *knobPath = [NSBezierPath bezierPathWithRoundedRect:inset xRadius:onSwitchRadius yRadius:onSwitchRadius];
   NSGradient *gradient = nil;
   if(!pressed)
      gradient = [[NSGradient alloc] initWithStartingColor:[NSColor controlHighlightColor] endingColor:[NSColor whiteColor]];
   else
      gradient = [[NSGradient alloc] initWithStartingColor:[NSColor whiteColor] endingColor:[NSColor controlHighlightColor]];
   [[NSColor colorWithDeviceWhite:.2f alpha:1.0f] setStroke];
   [knobPath setLineWidth:.75f];
   [gradient drawInBezierPath:knobPath angle:90.0f];
   [knobPath stroke];
   [gradient release];
}

@end
