//
//  GrowlBezelWindowView.m
//  Display Plugins
//
//  Created by Jorge Salvador Caffarena on 09/09/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "GrowlBezelWindowView.h"

#define BORDER_RADIUS 20.0
#define ELIPSIS_STRING @"..."

@implementation GrowlBezelWindowView

- (id)initWithFrame:(NSRect)frame {
	if ( self = [super initWithFrame:frame] ) {
		_icon = nil;
		_title = nil;
		_text = nil;
		_textHeight = 0;
		_target = nil;
		_action = nil;
	}
	return self;
}

- (void)dealloc {
	[_icon release];
	[_title release];
	[_text release];
	
	_icon = nil;
	_title = nil;
	_text = nil;
	_target = nil;
	
	[super dealloc];
}

- (void)drawRect:(NSRect)rect {
	NSRect bounds = [self bounds];
	NSBezierPath *bezelPath = [NSBezierPath bezierPath];
	NSPoint topLeft = NSMakePoint(bounds.origin.x, bounds.origin.y);
	NSPoint topRight = NSMakePoint(bounds.origin.x + bounds.size.width, bounds.origin.y);
	NSPoint bottomLeft = NSMakePoint(bounds.origin.x, bounds.origin.y + bounds.size.height);
	NSPoint bottomRight = NSMakePoint(bounds.origin.x + bounds.size.width, bounds.origin.y + bounds.size.height);
	[[NSColor clearColor] set];
	NSRectFill( [self frame] );

	[bezelPath appendBezierPathWithArcWithCenter:NSMakePoint(topLeft.x + BORDER_RADIUS, topLeft.y + BORDER_RADIUS)
			radius:BORDER_RADIUS
			startAngle:180
			endAngle:270
			clockwise:NO];
	[bezelPath lineToPoint:NSMakePoint(topRight.x - BORDER_RADIUS, topRight.y)];
	
	[bezelPath appendBezierPathWithArcWithCenter:NSMakePoint(topRight.x - BORDER_RADIUS, topRight.y + BORDER_RADIUS)
			radius:BORDER_RADIUS
			startAngle:270
			endAngle:0
			clockwise:NO];
	[bezelPath lineToPoint:NSMakePoint(bottomRight.x, bottomRight.y - BORDER_RADIUS)];
	
	[bezelPath appendBezierPathWithArcWithCenter:NSMakePoint(bottomRight.x - BORDER_RADIUS, bottomRight.y - BORDER_RADIUS)
			radius:BORDER_RADIUS
			startAngle:0
			endAngle:90
			clockwise:NO];
	[bezelPath lineToPoint:NSMakePoint(bottomLeft.x + BORDER_RADIUS, bottomLeft.y)];
	
	[bezelPath appendBezierPathWithArcWithCenter:NSMakePoint(bottomLeft.x + BORDER_RADIUS, bottomLeft.y - BORDER_RADIUS)
			radius:BORDER_RADIUS
			startAngle:90
			endAngle:180
			clockwise:NO];
	[bezelPath lineToPoint:NSMakePoint(topLeft.x, topLeft.y + BORDER_RADIUS)];
	
	[[NSColor colorWithCalibratedRed:0. green:0. blue:0. alpha:.5] set];
	[bezelPath fill];
	
	// Draw the title, resize if text too big
    NSMutableParagraphStyle *parrafo = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] 
			setAlignment:NSCenterTextAlignment];
	NSMutableDictionary *titleAttributes = [[NSMutableDictionary dictionaryWithObjectsAndKeys:
				[NSColor whiteColor], NSForegroundColorAttributeName,
				parrafo, NSParagraphStyleAttributeName, nil] retain];
	NSRect titleRect = NSMakeRect(8.,52.,143.,24.);
	float titleFontSize = 20.0;
	float accumulator = 0.;
	BOOL minFontSize = NO;
	[titleAttributes setObject:[[NSFontManager sharedFontManager] 
        convertFont:[NSFont systemFontOfSize:titleFontSize] toHaveTrait: NSBoldFontMask]
		forKey:NSFontAttributeName];
	NSSize titleSize = [_title sizeWithAttributes:titleAttributes];
	
	while ( titleSize.width > ( 143. - ( titleSize.height / 2. ) ) ) {
		minFontSize = ( titleFontSize <= 12. );
		if ( minFontSize ) {
			[self setTitle: [_title substringToIndex:[_title length] - 1]];
		} else {
			titleFontSize -= 1.;
			accumulator += 0.5;
		}
		[titleAttributes setObject:[[NSFontManager sharedFontManager] 
			convertFont:[NSFont systemFontOfSize:titleFontSize] toHaveTrait: NSBoldFontMask] forKey:NSFontAttributeName];
		titleSize = [_title sizeWithAttributes:titleAttributes];
	}
	
	titleRect.origin.y += ceil(accumulator);
	
	if ( minFontSize ) {
		[self setTitle: [NSString stringWithFormat:@"%@%@",[_title substringToIndex:[_title length]-1], ELIPSIS_STRING]];
	}
	
	titleRect.size.height = titleSize.height;
	[_title drawInRect:titleRect withAttributes:titleAttributes];
	[_text drawInRect:NSMakeRect(8.0,19.0,143.0,34)];
	
	NSSize iconSize = [_icon size];
	if ( iconSize.width > 48. || iconSize.height > 48. ) {
		// scale the image appropiately
		float newWidth, newHeight, newX, newY;
		if ( iconSize.width > iconSize.height ) {
			newWidth = 48.;
			newHeight = 48. / iconSize.width * iconSize.height;
		} else if( iconSize.width < iconSize.height ) {
			newWidth = 48. / iconSize.height * iconSize.width;
			newHeight = 48.;
		} else {
			newWidth = 48.;
			newHeight = 48.;
		}
		
		newX = floorf((48 - newWidth) / 2.);
		newY = floorf((48 - newHeight) / 2.);
		
		NSRect newBounds = { { newX, newY }, { newWidth, newHeight } };
		NSImageRep *sourceImageRep = [_icon bestRepresentationForDevice:nil];
		[_icon autorelease];
		_icon = [[NSImage alloc] initWithSize:NSMakeSize(48., 48.)];
		[_icon lockFocus];
		[[NSGraphicsContext currentContext] setImageInterpolation: NSImageInterpolationHigh];
		[sourceImageRep drawInRect:newBounds];
		[_icon unlockFocus];
	}
	
	[_icon compositeToPoint:NSMakePoint( 57., 83. ) operation:NSCompositeSourceOver fraction:1.];
}

- (void)setIcon:(NSImage *)icon {
	[_icon autorelease];
	_icon = [icon retain];
	[self setNeedsDisplay:YES];
}

- (void)setTitle:(NSString *)title {
	[_title autorelease];
	_title = [title copy];
	[self setNeedsDisplay:YES];
}

- (void)setAttributedText:(NSAttributedString *)text {
	[_text autorelease];
	_text = [text copy];
	_textHeight = 0;
	[self setNeedsDisplay:YES];
}

- (void)setText:(NSString *)text {
	[_text autorelease];
    NSMutableParagraphStyle    *parrafo = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] 
			setAlignment:NSCenterTextAlignment];
	_text = [[NSAttributedString alloc] initWithString:text attributes:
			[NSMutableDictionary dictionaryWithObjectsAndKeys:
				[NSColor whiteColor], NSForegroundColorAttributeName,
				parrafo, NSParagraphStyleAttributeName,
				[NSFont systemFontOfSize:14.0], NSFontAttributeName, nil]];
	_textHeight = 0;
	[self setNeedsDisplay:YES];
}

- (float) descriptionHeight {
	
	if (_textHeight == 0)
	{
		NSTextStorage* textStorage = [[NSTextStorage alloc] initWithAttributedString:_text];
		NSTextContainer* textContainer = [[[NSTextContainer alloc]
			initWithContainerSize:NSMakeSize ( 200., FLT_MAX )] autorelease];
		NSLayoutManager* layoutManager = [[[NSLayoutManager alloc] init] autorelease];

		[layoutManager addTextContainer:textContainer];
		[textStorage addLayoutManager:layoutManager];
		(void)[layoutManager glyphRangeForTextContainer:textContainer];
	
		_textHeight = [layoutManager usedRectForTextContainer:textContainer].size.height;
	
		_textHeight = _textHeight / 13 * 14;
	}
	return MAX (_textHeight, 30);
}

- (int) descriptionRowCount {
	float height = [self descriptionHeight];
	float lineHeight = [_text size].height;
	return (int) (height / lineHeight);
}

- (id) target {
	return _target;
}

- (void) setTarget:(id) object {
	_target = object;
}

#pragma mark -

- (SEL) action {
	return _action;
}

- (void) setAction:(SEL) selector {
	_action = selector;
}

#pragma mark -

 - (void) mouseUp:(NSEvent *) event {
	if( _target && _action && [_target respondsToSelector:_action] )
		[_target performSelector:_action withObject:self];
}

@end
