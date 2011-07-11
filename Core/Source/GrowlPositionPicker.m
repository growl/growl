//
//  GrowlPositionPicker.h
//  Growl
//
//  Created by Jamie Kirkpatrick on 01.05.06.
//  Copyright 2005-2006 The Growl Project. All rights reserved.
//

#import "GrowlPositionPicker.h"

#define GrowlPositionPickerHotCornerInset	   3.0
#define GrowlPositionPickerHotCornerDiameter	15.f
#define GrowlPositionPickerHotCornerUnselectedAlpha   0.7
#define GrowlPositionPickerHotCornerSelectedAlpha     0.9
#define GrowlPositionPickerHotCornerSelectionDotAlpha 0.7

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
@synthesize selectedPosition;

+ (void) initialize {
	if (self != [GrowlPositionPicker class])
		return;
	
	backgroundImage = [self imageForCurrentOS];
	imageBounds = NSMakeRect(0.0,0.0,[backgroundImage size].width,[backgroundImage size].height);
	unselectedColor = [[NSColor colorWithDeviceWhite:1.0 alpha:GrowlPositionPickerHotCornerUnselectedAlpha] retain];
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
		
		[self addObserver:self forKeyPath:@"selectedPosition" options:NSKeyValueObservingOptionNew context:self];
	}
	return self;
}

- (void) dealloc {
	
	[self removeObserver:self forKeyPath:@"selectePosition"];
	
	[self removeTrackingRect:trackingRectTag];
	[topLeftHotCorner release];
	[topRightHotCorner release];
	[bottomRightHotCorner release];
	[bottomRightHotCorner release];
	[super dealloc];
}

+ (NSImage*)imageForCurrentOS {
    NSImage *result = nil;
    
    if(floor(NSAppKitVersionNumber) <= 1138)
        result = [[NSImage alloc] initByReferencingFile:@"/Library/Desktop Pictures/Andromeda Galaxy.jpg"];
    else if(floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_6)
        result = [[NSImage alloc] initByReferencingFile:@"/Library/Desktop Pictures/Nature/Aurora.jpg"];
    else
        result = [[NSImage alloc] initByReferencingFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"PositionPickerBackground" ofType:@"jpg"]];
    
    return result;
}
#pragma mark -
#pragma mark NSView overrides

- (void) drawRect:(NSRect)rect {
	// make sure that the view is big enough...
	NSRect bounds = [self bounds];
	if ((bounds.size.width < GrowlPositionPickerMinWidth)||(bounds.size.height < GrowlPositionPickerMinHeight))
	{
		NSLog (@"The view dimensions fall below the minimum requirement: %f by %f",GrowlPositionPickerMinWidth,GrowlPositionPickerMinHeight);
		return;
	}
	
	// draw the background image...
	[backgroundImage drawInRect:bounds fromRect:imageBounds operation:NSCompositeSourceOver fraction:1.0];
	
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
	// turn on mouse moved tracking on the window...
	NSWindow *window = [self window];
	windowWatchesMouseMovedEvents = [window acceptsMouseMovedEvents];
	[window setAcceptsMouseMovedEvents:YES];
	mouseOverView = YES;
}

- (void) mouseExited:(NSEvent *)theEvent {
	// revert the window to its previous setting...
	if (!windowWatchesMouseMovedEvents) {
		[[self window] setAcceptsMouseMovedEvents:NO];
	}
	mouseOverView = NO;
	rolloverPosition = GrowlNoOrigin;
	[self setNeedsDisplay:YES];
}

- (void) mouseMoved:(NSEvent *)theEvent {
	if ( !mouseOverView )
		return;
	
	// did the mouse hit any of the hotcorners...?
	NSUInteger lastHit = rolloverPosition;
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
	NSUInteger lastHit = selectedPosition;
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
#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if ([keyPath isEqualToString:@"selectedPosition"] && context == self) {
		if(selectedPosition != lastPosition)
			[[NSNotificationCenter defaultCenter] postNotificationName:GrowlPositionPickerChangedSelectionNotification
																object:self];			
		lastPosition = selectedPosition;
	}
}

#pragma mark KVC

//When the table view of applications is empty, Cocoa Bindings tries to set the selected position of the per-application position picker to nil. With the stock KVC behavior, that raises an assertion failure. This implementation accepts nil for that key, preventing that assertion failure.
- (void)setNilValueForKey:(NSString *)key
{
	if ([key isEqualToString:@"selectedPosition"])
		[self setSelectedPosition:GrowlNoOrigin];
	else
		return [super setNilValueForKey:key];
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
	[(selected
	 ? [[NSColor whiteColor] colorWithAlphaComponent:GrowlPositionPickerHotCornerSelectedAlpha]
	 : (mouseOver
	   ? rolloverColor
	   : unselectedColor
	   )
	 ) set];
	[cornerPath fill];
	
	// stroke the selected corner...
	if (selected)
	{
		//… and put a black dot in it to make it really obvious that it's selected.
		[[[NSColor blackColor] colorWithAlphaComponent:GrowlPositionPickerHotCornerSelectionDotAlpha] set];
		NSBezierPath *dot = [NSBezierPath bezierPath];
		NSRect cornerPathBounds = [cornerPath bounds];
		NSPoint centerPoint = NSMakePoint(NSMidX(cornerPathBounds),
		                                  NSMidY(cornerPathBounds));
		//Center our dot within the correct quadrant of the corner path's bounding rectangle, by adding or subtracting one-eighth of its bounds on each axis.
		CGFloat xOffset = NSWidth(cornerPathBounds)  * (1.0 / 6.0);
		CGFloat yOffset = NSHeight(cornerPathBounds) * (1.0 / 6.0);
		switch (position) {
		case GrowlTopLeftCorner:
			xOffset *= -1.0;
			break;
		case GrowlTopRightCorner:
			break;
		case GrowlBottomRightCorner:
			yOffset *= -1.0;
			break;
		case GrowlBottomLeftCorner:
			xOffset *= -1.0;
			yOffset *= -1.0;
			break;
		case GrowlNoOrigin:
			break;
		}
		centerPoint.x += xOffset;
		centerPoint.y += yOffset;

		//Draw the dot.
		[dot moveToPoint:centerPoint];
		[dot appendBezierPathWithArcWithCenter:centerPoint
		                                radius:2.0
		                            startAngle:0.0
		                              endAngle:360.0];
		[dot closePath];
		[dot fill];
	}

	[NSGraphicsContext restoreGraphicsState];
}

@end
