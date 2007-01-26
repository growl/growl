//
//  GrowlPositionPicker.h
//  Growl
//
//  Created by Jamie Kirkpatrick on 01.05.06.
//  Copyright 2005-2006 The Growl Project. All rights reserved.
//

#import "GrowlPositionPicker.h"

#define GrowlPositionPickerHotCornerInset       3.0f
#define GrowlPositionPickerHotCornerDiameter    15.f

static NSImage *backgroundImage = nil;
static NSColor *unselectedColor = nil;
static NSColor *selectedColor = nil;
static NSColor *rolloverColor = nil;
static NSRect imageBounds;

NSString *GrowlPositionPickerChangedSelectionNotification = @"GrowlPositionPickerChangedSelectionNotification";

@interface GrowlPositionPicker(Private)
- (void) generateHotCornerPaths;
- (void) resetTrackingRect;
- (void) drawHotCorner:(NSBezierPath *)cornerPath position:(enum GrowlPositionOrigin)position;
@end

#pragma mark -

@implementation GrowlPositionPicker

+ (void) initialize {
    if (self != [GrowlPositionPicker class])
        return;
    
    backgroundImage = [[NSImage imageNamed:@"PositionPickerBackground"] retain];
    imageBounds = NSMakeRect(0.0f,0.0f,[backgroundImage size].width,[backgroundImage size].height);
    unselectedColor = [[NSColor colorWithDeviceWhite:1.0f alpha:0.7f] retain];
    rolloverColor = [[NSColor grayColor] retain];
    selectedColor = [[NSColor whiteColor] retain];
	
	[NSObject exposeBinding:@"selectedPosition"];
}

- (id) initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self generateHotCornerPaths];
        selectedPosition = GrowlTopRightCorner;
        rolloverPosition = GrowlNoOrigin;
    }
    return self;
}

- (void) dealloc {
    [self removeTrackingRect:trackingRectTag];
    [topLeftHotCorner release];
    [topRightHotCorner release];
    [bottomRightHotCorner release];
    [bottomRightHotCorner release];
    [super dealloc];
}

#pragma mark -
#pragma mark NSView overrides

- (void) drawRect:(NSRect)rect {
#pragma unused(rect)
    // make sure that the view is big enough...
    NSRect bounds = [self bounds];
    if ((bounds.size.width < GrowlPositionPickerMinWidth)||(bounds.size.height < GrowlPositionPickerMinHeight))
    {
        NSLog (@"The view dimensions fall below the minimum requirement: %f by %f",GrowlPositionPickerMinWidth,GrowlPositionPickerMinHeight);
        return;
    }
    
    // draw the background image...
    [backgroundImage drawInRect:bounds fromRect:imageBounds operation:NSCompositeSourceOver fraction:1.0f];
	
	// select the appropriate hotcorner before drawing
	//[self setSelectedPosition:[associatedController selectedPosition]];
    
    // draw the hotcorners...
    [self drawHotCorner:topLeftHotCorner position:GrowlTopLeftCorner];
    [self drawHotCorner:topRightHotCorner position:GrowlTopRightCorner];
    [self drawHotCorner:bottomRightHotCorner position:GrowlBottomRightCorner];
    [self drawHotCorner:bottomLeftHotCorner position:GrowlBottomLeftCorner];
}

- (void) viewDidMoveToWindow {
    // make sure that the window accepts mouse moved events for the rollovers...
    NSWindow *window = [self window];
    if (window) {
        [self resetTrackingRect];
    }
}

#pragma mark -
#pragma mark NSResponder overrides

- (BOOL) acceptsFirstResponder {
    return YES;
}

- (void) mouseEntered:(NSEvent *)theEvent {
#pragma unused(theEvent)
    // turn on mouse moved tracking on the window...
    NSWindow *window = [self window];
    windowWatchesMouseMovedEvents = [window acceptsMouseMovedEvents];
    [window setAcceptsMouseMovedEvents:YES];
    mouseOverView = YES;
}

- (void) mouseExited:(NSEvent *)theEvent {
#pragma unused(theEvent)
    // revert the window to its previous setting...
    if (!windowWatchesMouseMovedEvents) {
        [[self window] setAcceptsMouseMovedEvents:NO];
    }
    mouseOverView = NO;
    [self setNeedsDisplay:YES];
}

- (void) mouseMoved:(NSEvent *)theEvent {
    if ( !mouseOverView )
        return;
    
    // did the mouse hit any of the hotcorners...?
    enum GrowlPositionOrigin lastHit = rolloverPosition;
    NSPoint mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    if ([topLeftHotCorner containsPoint:mouseLoc]) {
        rolloverPosition = GrowlTopLeftCorner;
    } else if ([topRightHotCorner containsPoint:mouseLoc]) {
        rolloverPosition = GrowlTopRightCorner;
    } else if ([bottomRightHotCorner containsPoint:mouseLoc]) {
        rolloverPosition = GrowlBottomRightCorner;
    } else if ([bottomLeftHotCorner containsPoint:mouseLoc]) {
        rolloverPosition = GrowlBottomLeftCorner;
    } else {
        rolloverPosition = GrowlNoOrigin;
    }
    
    // do we need to redisplay...?
    if (lastHit != rolloverPosition )
        [self setNeedsDisplay:YES];
}

- (void)mouseDown:(NSEvent *)theEvent {
    // did the mouse hit any of the hotcorners...?
    enum GrowlPositionOrigin lastHit = selectedPosition;
    NSPoint mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    if ([topLeftHotCorner containsPoint:mouseLoc]) {
        [self setSelectedPosition:GrowlTopLeftCorner];
    } else if ([topRightHotCorner containsPoint:mouseLoc]) {
        [self setSelectedPosition:GrowlTopRightCorner];
    } else if ([bottomRightHotCorner containsPoint:mouseLoc]) {
        [self setSelectedPosition:GrowlBottomRightCorner];
    } else if ([bottomLeftHotCorner containsPoint:mouseLoc]) {
        [self setSelectedPosition:GrowlBottomLeftCorner];
    }
    
    // do we need to redisplay...?
    if (lastHit != selectedPosition )
        [self setNeedsDisplay:YES];
}

#pragma mark -
#pragma mark accessors

- (enum GrowlPositionOrigin) selectedPosition
{
    return selectedPosition;
}

- (void) setSelectedPosition: (enum GrowlPositionOrigin) theSelectedPosition
{
    enum GrowlPositionOrigin lastValue = selectedPosition;
    selectedPosition = theSelectedPosition;
    
    // notify of the change...?
    if (selectedPosition != lastValue) {
        [[NSNotificationCenter defaultCenter] postNotificationName:GrowlPositionPickerChangedSelectionNotification
                                                            object:self];
    }
}

@end

#pragma mark -

@implementation GrowlPositionPicker(Private)

- (void) generateHotCornerPaths {
    NSRect rectToUse = NSInsetRect([self bounds],
                                   GrowlPositionPickerHotCornerInset,
                                   GrowlPositionPickerHotCornerInset);
    
    // top left corner...
    topLeftHotCorner = [[NSBezierPath alloc] init];
    [topLeftHotCorner moveToPoint:NSMakePoint(NSMinX(rectToUse),
                                              NSMaxY(rectToUse))];
    [topLeftHotCorner lineToPoint:NSMakePoint(NSMinX(rectToUse) + GrowlPositionPickerHotCornerDiameter,
                                              NSMaxY(rectToUse))];
    [topLeftHotCorner lineToPoint:NSMakePoint(NSMinX(rectToUse),
                                              NSMaxY(rectToUse) - GrowlPositionPickerHotCornerDiameter)];
    [topLeftHotCorner closePath];
    
    // top right corner...
    topRightHotCorner = [[NSBezierPath alloc] init];
    [topRightHotCorner moveToPoint:NSMakePoint(NSMaxX(rectToUse),
                                               NSMaxY(rectToUse))];
    [topRightHotCorner lineToPoint:NSMakePoint(NSMaxX(rectToUse) - GrowlPositionPickerHotCornerDiameter,
                                               NSMaxY(rectToUse))];
    [topRightHotCorner lineToPoint:NSMakePoint(NSMaxX(rectToUse),
                                               NSMaxY(rectToUse) - GrowlPositionPickerHotCornerDiameter)];
    [topRightHotCorner closePath];
    
    // bottom right corner...
    bottomRightHotCorner = [[NSBezierPath alloc] init];
    [bottomRightHotCorner moveToPoint:NSMakePoint(NSMaxX(rectToUse),
                                                  NSMinY(rectToUse))];
    [bottomRightHotCorner lineToPoint:NSMakePoint(NSMaxX(rectToUse) - GrowlPositionPickerHotCornerDiameter,
                                                  NSMinY(rectToUse))];
    [bottomRightHotCorner lineToPoint:NSMakePoint(NSMaxX(rectToUse),
                                                  NSMinY(rectToUse) + GrowlPositionPickerHotCornerDiameter)];
    [bottomRightHotCorner closePath];
    
    // bottom left corner...
    bottomLeftHotCorner = [[NSBezierPath alloc] init];
    [bottomLeftHotCorner moveToPoint:NSMakePoint(NSMinX(rectToUse),
                                                 NSMinY(rectToUse))];
    [bottomLeftHotCorner lineToPoint:NSMakePoint(NSMinX(rectToUse) + GrowlPositionPickerHotCornerDiameter,
                                                 NSMinY(rectToUse))];
    [bottomLeftHotCorner lineToPoint:NSMakePoint(NSMinX(rectToUse),
                                                 NSMinY(rectToUse) + GrowlPositionPickerHotCornerDiameter)];
    [bottomLeftHotCorner closePath];
}

- (void) resetTrackingRect {
    if ( trackingRectTag ) {
        [self removeTrackingRect:trackingRectTag];
        trackingRectTag = 0;
    }
    if ( [self window] ) {
        [self addTrackingRect:imageBounds owner:self userData:NULL assumeInside:NO];
    }
}

- (void) drawHotCorner:(NSBezierPath *)cornerPath position:(enum GrowlPositionOrigin)position {
    [NSGraphicsContext saveGraphicsState];
    
    BOOL mouseOver = ((rolloverPosition == position));
    BOOL selected  = ((selectedPosition == position));
    
    // fill the path...
    [(selected ? selectedColor : (mouseOver ? rolloverColor : unselectedColor)) set];
    [cornerPath fill];
    
    // stroke the selected corner...
    if (selected)
    {
        [[[NSColor blackColor] colorWithAlphaComponent:0.7f] set];
        [cornerPath setLineWidth:2.0f];
        [cornerPath setLineJoinStyle:NSMiterLineJoinStyle];
        [cornerPath stroke];
    }
    
    [NSGraphicsContext restoreGraphicsState];
}

@end
