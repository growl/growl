//
//  GrowlOnSwitchKnob.m
//  GrowlSlider
//
//  Created by Daniel Siemer on 1/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "GrowlOnSwitchKnob.h"

@implementation GrowlOnSwitchKnob

- (id)initWithFrame:(NSRect)frame
{
    if((self = [super initWithFrame:frame])){
        // Initialization code here.
    }
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
   CGRect inset = CGRectInset([self bounds], 1.0, 1.0);
   NSBezierPath *knobPath = [NSBezierPath bezierPathWithRoundedRect:inset xRadius:6.0 yRadius:6.0];
   NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:[NSColor lightGrayColor] endingColor:[NSColor whiteColor]];
   [[NSColor grayColor] setStroke];
   [gradient drawInBezierPath:knobPath angle:90.0f];
   [knobPath stroke];
   [gradient release];
}

@end
