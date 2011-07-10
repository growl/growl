//
//  GrowlNotificationRowView.m
//  Growl
//
//  Created by Daniel Siemer on 7/8/11.
//  Copyright 2011 The Growl Project. All rights reserved.
//

#import "GrowlNotificationRowView.h"
#import "GrowlNotificationCellView.h"

@implementation GrowlNotificationRowView

@synthesize mouseInside;

- (id)init
{
    self = [super init];
    if (self) {
        mouseInside = NO;
    }
    
    return self;
}

-(void)dealloc
{
    [trackingArea release];
    [super dealloc];
}

- (void)setMouseInside:(BOOL)value {
    if (mouseInside != value) {
        mouseInside = value;
        [self setNeedsDisplay:YES];
    }
}

- (void)ensureTrackingArea {
    if (trackingArea == nil) {
        trackingArea = [[NSTrackingArea alloc] initWithRect:NSZeroRect options:NSTrackingInVisibleRect | NSTrackingActiveAlways | NSTrackingMouseEnteredAndExited owner:self userInfo:nil];
    }
}

- (void)updateTrackingAreas {
    [super updateTrackingAreas];
    [self ensureTrackingArea];
    if (![[self trackingAreas] containsObject:trackingArea]) {
        [self addTrackingArea:trackingArea];
    }
}

- (void)mouseEntered:(NSEvent *)theEvent {
    self.mouseInside = YES;
    [[(GrowlNotificationCellView*)[self viewAtColumn:0] deleteButton] setHidden:NO];
}

- (void)mouseExited:(NSEvent *)theEvent {
    self.mouseInside = NO;
    if(!self.selected)
        [[(GrowlNotificationCellView*)[self viewAtColumn:0] deleteButton] setHidden:YES];
}

// interiorBackgroundStyle is normaly "dark" when the selection is drawn (self.selected == YES) and we are in a key window (self.emphasized == YES). However, we always draw a dark selection, so we override this method to always return a light color.
- (NSBackgroundStyle)interiorBackgroundStyle {
    return NSBackgroundStyleDark;  
}

- (void)drawBackgroundInRect:(NSRect)dirtyRect {
    [super drawBackgroundInRect:dirtyRect];
    // Draw a white/alpha gradient
    if (self.mouseInside) {
        [self drawRoundedRectInRect:self.bounds];
    }
}

// Only called if the 'selected' property is yes.
- (void)drawSelectionInRect:(NSRect)dirtyRect {
    // Check the selectionHighlightStyle, in case it was set to None
    if (self.selectionHighlightStyle != NSTableViewSelectionHighlightStyleNone) {
        [self drawRoundedRectInRect:[self bounds]];
    }
}

-(void)drawRoundedRectInRect:(NSRect)rect {
    // We want a hard-crisp stroke, and stroking 1 pixel will border half on one side and half on another, so we offset by the 0.5 to handle this
    NSRect selectionRect = NSInsetRect(rect, 3.0, 3.0);
    [[NSColor colorWithCalibratedWhite:1.0 alpha:1.0] setStroke];
    NSBezierPath *selectionPath = [NSBezierPath bezierPathWithRoundedRect:selectionRect xRadius:10 yRadius:10];
    [selectionPath setLineWidth:2.0];
    [selectionPath stroke];
}

static NSGradient *gradientWithTargetColor(NSColor *targetColor) {
    NSArray *colors = [NSArray arrayWithObjects:[targetColor colorWithAlphaComponent:0], targetColor, targetColor, [targetColor colorWithAlphaComponent:0], nil];
    const CGFloat locations[4] = { 0.0, 0.35, 0.65, 1.0 };
    return [[[NSGradient alloc] initWithColors:colors atLocations:locations colorSpace:[NSColorSpace sRGBColorSpace]] autorelease];
}

- (NSRect)separatorRect {
    NSRect separatorRect = self.bounds;
    separatorRect.origin.y = NSMaxY(separatorRect)- 1;
    separatorRect.size.height = 1;
    return separatorRect;
}

// Only called if the table is set with a horizontal grid
- (void)drawSeparatorInRect:(NSRect)dirtyRect {
    // Use a common shared method of drawing the separator
    static NSGradient *gradient = nil;
    if (gradient == nil) {
        gradient = [gradientWithTargetColor([NSColor colorWithSRGBRed:.80 green:.80 blue:.80 alpha:1]) retain];
    }
    [gradient drawInRect:[self separatorRect] angle:0];
}

@end

