//
//  GrowlBezelWindowView.m
//  Display Plugins
//
//  Created by Jorge Salvador Caffarena on 09/09/04.
//  Copyright 2004 Jorge Salvador Caffarena. All rights reserved.
//

#import "GrowlBezelWindowView.h"
#import "GrowlImageAdditions.h"

#define BORDER_RADIUS 20.0
#define ELIPSIS_STRING @"..."

@interface GrowlBezelWindowView (PRIVATE)
- (void)resizeIcon:(NSImage *)theImage toSize:(NSSize)theSize;
@end

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
	
	int opacityPref = 40;
	READ_GROWL_PREF_INT(BEZEL_OPACITY_PREF, @"com.Growl.Bezel", &opacityPref);
	
	[[NSColor colorWithCalibratedRed:0. green:0. blue:0. alpha:((float)opacityPref/100.)] set];
	[bezelPath fill];
	
	int sizePref = 0;
	READ_GROWL_PREF_INT(BEZEL_SIZE_PREF, @"com.Growl.Bezel", &sizePref);
	
	// rects
	NSRect titleRect, textRect;
	NSPoint iconPoint;
	int maxRows;
	int iconOffset = 0;
	NSSize maxIconSize;
	NSSize iconSize = [_icon size];
	if (sizePref == BEZEL_SIZE_NORMAL) {
		titleRect = NSMakeRect(12., 90., 187., 30.);
		textRect =  NSMakeRect(12., 4., 187., 80.);
		maxRows = 4;
		maxIconSize = NSMakeSize(72., 72.);
		iconSize = [_icon adjustSizeToDrawAtSize:maxIconSize];
		if ( iconSize.width < maxIconSize.width ) {
			iconOffset = ceil( (maxIconSize.width - iconSize.width) / 2. );
		}
		iconPoint = NSMakePoint(70. + iconOffset, 120.);
	} else {
		titleRect = NSMakeRect(8., 52., 143., 24.);
		textRect =  NSMakeRect(8., 4., 143., 49.);
		maxRows = 2;
		maxIconSize = NSMakeSize(48., 48.);
		iconSize = [_icon adjustSizeToDrawAtSize:maxIconSize];
		if ( iconSize.width < maxIconSize.width ) {
			iconOffset = ceil( (maxIconSize.width - iconSize.width) / 2. );
		}
		iconPoint = NSMakePoint(57. + iconOffset, 83.);
	}
	
	if ( iconSize.width > maxIconSize.width || iconSize.height > maxIconSize.height ) {
		// scale the image appropiately
		[self resizeIcon:_icon toSize:maxIconSize];
	}
	
	// If we are on Panther or better, pretty shadow
	BOOL pantherOrLater = ( floor( NSAppKitVersionNumber ) > NSAppKitVersionNumber10_2 );
	NSShadow *textShadow = nil;
	Class NSShadowClass = NSClassFromString(@"NSShadow");
	if ( pantherOrLater ) {
        textShadow = [[[NSShadowClass alloc] init] autorelease];
        
		NSSize      shadowSize = NSMakeSize(0., -2.);
        [textShadow setShadowOffset:shadowSize];
        [textShadow setShadowBlurRadius:3.0];
		[textShadow setShadowColor:[NSColor colorWithCalibratedRed:0. green:0. blue:0. alpha: 1.0]];
	}
	
	// Draw the title, resize if text too big
	float titleFontSize = 20.0;
    NSMutableParagraphStyle *parrafo = [[[[NSParagraphStyle defaultParagraphStyle] mutableCopy] 
			setAlignment:NSCenterTextAlignment] autorelease];
	NSMutableDictionary *titleAttributes = [NSMutableDictionary dictionaryWithObjectsAndKeys:
				[NSColor whiteColor], NSForegroundColorAttributeName,
				parrafo, NSParagraphStyleAttributeName,
				[NSFont boldSystemFontOfSize:titleFontSize], NSFontAttributeName, nil];
	if ( pantherOrLater ) {
		[titleAttributes setObject:textShadow forKey:NSShadowAttributeName];
	}
	float accumulator = 0.;
	BOOL minFontSize = NO;
	//[titleAttributes setObject:[NSFont boldSystemFontOfSize:titleFontSize] forKey:NSFontAttributeName];
	NSSize titleSize = [_title sizeWithAttributes:titleAttributes];
	
	while ( titleSize.width > ( NSWidth(titleRect) - ( titleSize.height / 2. ) ) ) {
		minFontSize = ( titleFontSize <= 12. );
		if ( minFontSize ) {
			[self setTitle: [_title substringToIndex:[_title length] - 1]];
		} else {
			titleFontSize -= 1.;
			accumulator += 0.5;
		}
		[titleAttributes setObject:[NSFont boldSystemFontOfSize:titleFontSize] forKey:NSFontAttributeName];
		titleSize = [_title sizeWithAttributes:titleAttributes];
	}
	
	titleRect.origin.y += ceil(accumulator);
	
	if ( minFontSize ) {
		[self setTitle: [NSString stringWithFormat:@"%@%@",[_title substringToIndex:[_title length]-1], ELIPSIS_STRING]];
	}
	
	titleRect.size.height = titleSize.height;
	[_title drawInRect:titleRect withAttributes:titleAttributes];
	
	NSMutableDictionary *textAttributes = [NSMutableDictionary dictionaryWithObjectsAndKeys:
				[NSColor whiteColor], NSForegroundColorAttributeName,
				parrafo, NSParagraphStyleAttributeName,
				[NSFont systemFontOfSize:14.0], NSFontAttributeName, nil];
	if ( pantherOrLater ) {
		[textAttributes setObject:textShadow forKey:NSShadowAttributeName];
	}
	NSAttributedString *_textAttributed;
	NSArray *linesN = [_text componentsSeparatedByString:@"\n"];
	int rowCount = 0;
	if ( [linesN count] > 1 ) {
		NSEnumerator *stringEnum = [linesN objectEnumerator];
		NSString *stringLine;
		while (stringLine = [stringEnum nextObject]) {
			_textAttributed = [[NSAttributedString alloc] initWithString:stringLine attributes:textAttributes];
			rowCount += [self descriptionRowCount:_textAttributed inRect:textRect];
			[_textAttributed release];
			_textHeight = 0;
		}
	} else {
		_textAttributed = [[[NSAttributedString alloc] initWithString:_text attributes:textAttributes] autorelease];
		rowCount = [self descriptionRowCount:_textAttributed inRect:textRect];
	}
	
	if ( rowCount > maxRows ) {
		[textAttributes setObject:[NSFont systemFontOfSize:12.0] forKey:NSFontAttributeName];
	}
	[_text drawInRect:textRect withAttributes:textAttributes];
		
	[_icon compositeToPoint:iconPoint operation:NSCompositeSourceOver fraction:1.];
}

- (void)resizeIcon:(NSImage *)theImage toSize:(NSSize)theSize {
	float newWidth, newHeight, newX, newY;
	NSSize iconSize = [theImage size];
	if ( iconSize.width > iconSize.height ) {
		newWidth = theSize.width;
		newHeight = theSize.height / iconSize.width * iconSize.height;
	} else if( iconSize.width < iconSize.height ) {
		newWidth = theSize.width / iconSize.height * iconSize.width;
		newHeight = theSize.height;
	} else {
		newWidth = theSize.width;
		newHeight = theSize.height;
	}
	
	newX = floorf((theSize.width - newWidth) / 2.);
	newY = floorf((theSize.width - newHeight) / 2.);
	
	NSRect newBounds = { { newX, newY }, { newWidth, newHeight } };
	NSImageRep *sourceImageRep = [_icon bestRepresentationForDevice:nil];
	[_icon autorelease];
	_icon = [[NSImage alloc] initWithSize:theSize];
	[_icon lockFocus];
	[[NSGraphicsContext currentContext] setImageInterpolation: NSImageInterpolationHigh];
	[sourceImageRep drawInRect:newBounds];
	[_icon unlockFocus];
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

- (void)setText:(NSString *)text {
	[_text autorelease];
	_text = [text copy];
	_textHeight = 0;
	[self setNeedsDisplay:YES];
}

- (float)descriptionHeight:(NSAttributedString *)text inRect:(NSRect)theRect {
	
	if (_textHeight == 0)
	{
		NSTextStorage* textStorage = [[NSTextStorage alloc] initWithAttributedString:text];
		NSTextContainer* textContainer = [[[NSTextContainer alloc]
			initWithContainerSize:NSMakeSize(NSWidth(theRect),NSHeight(theRect)+1000.)] autorelease];
		NSLayoutManager* layoutManager = [[[NSLayoutManager alloc] init] autorelease];

		[layoutManager addTextContainer:textContainer];
		[textStorage addLayoutManager:layoutManager];
		(void)[layoutManager glyphRangeForTextContainer:textContainer];
	
		_textHeight = [layoutManager usedRectForTextContainer:textContainer].size.height;
		_textHeight = _textHeight / 13 * 14;
	}
	return MAX (_textHeight, 30);
}

- (int)descriptionRowCount:(NSAttributedString *)text inRect:(NSRect)theRect{
	float height = [self descriptionHeight:text inRect:theRect];
	float lineHeight = [text size].height;
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
