//
//  GroupCountBubble.m
//  Growl
//
//  Created by Daniel Siemer on 8/13/11.
//  Copyright 2011 The Growl Project. All rights reserved.
//

#import "GroupCountBubble.h"

@implementation GroupCountBubble

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    CGFloat radius = (self.bounds.size.height / 2.0);
    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:self.bounds xRadius:radius yRadius:radius];
    [[NSColor colorWithCalibratedWhite:.25 alpha:.5] setFill];
    [[NSColor colorWithCalibratedWhite:.15 alpha:.6] setStroke];
    [path setLineWidth:.5];
    [path fill];
    [path stroke];
}

@end
