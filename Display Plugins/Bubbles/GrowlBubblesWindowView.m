//
//  GrowlBubblesWindowView.m
//  Growl
//
//  Created by Nelson Elhage on Wed Jun 09 2004.
//  Name changed from KABubbleWindowView.m by Justin Burns on Fri Nov 05 2004.
//  Copyright (c) 2004 Nelson Elhage. All rights reserved.
//

#import "GrowlBubblesWindowView.h"
#import "GrowlDefines.h"
#import "GrowlBubblesDefines.h"
#import "GrowlStringAdditions.h"
#import <math.h>

static void GrowlBubblesShadeInterpolate( void *info, float const *inData, float *outData )
{
	NSColor *_bgColor = (NSColor *) info;

	float bgRed, bgGreen, bgBlue, bgAlpha;
	[_bgColor getRed:&bgRed
			green:&bgGreen
			blue:&bgBlue
			alpha:&bgAlpha];

	//NSLog(@"data red: %f green: %f blue: %f alpha: %f", bgRed, bgGreen, bgBlue, bgAlpha);
	//static const float bg[4] = { .69412, .83147, .96078, .95 };
	static const float light[4] = { .93725f, .96863f, .99216f, .95f };

	register float a = inData[0];
	register float a_coeff = 1.0f - a;

	outData[0] = a_coeff * bgRed   + a * light[0];
	outData[1] = a_coeff * bgGreen + a * light[1];
	outData[2] = a_coeff * bgBlue  + a * light[2];
	outData[3] = a_coeff * bgAlpha + a * light[3];
}

#pragma mark -

@implementation GrowlBubblesWindowView
- (id) initWithFrame:(NSRect) frame {
	if( (self = [super initWithFrame:frame] ) ) {
		_icon   = nil;
		_title  = nil;
		_text   = nil;
		_textHeight = 0;
		_target = nil;
		_action = NULL;
	}
	return self;
}

- (void) dealloc {
	[_icon release];
	[_title release];
	[_text release];
	[_bgColor release];
	[_textColor release];
	
	_icon = nil;
	_title = nil;
	_text = nil;
	_target = nil;
	_bgColor = nil;
	_textColor = nil;

	[super dealloc];
}

- (void) drawRect:(NSRect) rect {

	NSRect bounds = [self bounds];

	[[NSColor clearColor] set];
	NSRectFill( [self frame] );

	float lineWidth = 4.f;
	NSBezierPath *path = [NSBezierPath bezierPath];
	[path setLineWidth:lineWidth];

	float radius = 9.f;
	float inset = radius + lineWidth;
	NSRect irect = NSInsetRect( bounds, inset, inset );
	float minX = NSMinX( irect );
	float minY = NSMinY( irect );
	float maxX = NSMaxX( irect );
	float maxY = NSMaxY( irect );
	[path appendBezierPathWithArcWithCenter:NSMakePoint( minX, minY )
									 radius:radius 
								 startAngle:180.f
								   endAngle:270.f];
	
	[path appendBezierPathWithArcWithCenter:NSMakePoint( maxX, minY ) 
									 radius:radius 
								 startAngle:270.f
								   endAngle:360.f];
	
	[path appendBezierPathWithArcWithCenter:NSMakePoint( maxX, maxY )
									 radius:radius 
								 startAngle:0.f
								   endAngle:90.f];
	
	[path appendBezierPathWithArcWithCenter:NSMakePoint( minX, maxY )
									 radius:radius 
								 startAngle:90.f
								   endAngle:180.f];

	[path closePath];

	[[NSGraphicsContext currentContext] saveGraphicsState];

	[path setClip];

	// Create a callback function to generate the 
    // fill clipped graphics context with our gradient
	struct CGFunctionCallbacks callbacks = { 0, GrowlBubblesShadeInterpolate, NULL };
	CGFunctionRef function = CGFunctionCreate( (void *) _bgColor, 1, NULL, 4, NULL, &callbacks );
	CGColorSpaceRef cspace = CGColorSpaceCreateDeviceRGB();

	float srcX = NSMinX( bounds ), srcY = NSMinY( bounds );
	float dstX = NSMinX( bounds ), dstY = NSMaxY( bounds );
	CGShadingRef shading = CGShadingCreateAxial( cspace, 
												 CGPointMake( srcX, srcY ), 
												 CGPointMake( dstX, dstY ), 
												 function, false, false );	

	CGContextDrawShading( [[NSGraphicsContext currentContext] graphicsPort], shading );

	CGShadingRelease( shading );
	CGColorSpaceRelease( cspace );
	CGFunctionRelease( function );

	[[NSGraphicsContext currentContext] restoreGraphicsState];

	[[NSColor colorWithCalibratedRed:0.f green:0.f blue:0.f alpha:.5f] set];
	[path stroke];

	// Top of the drawing area. The eye candy takes up 10 pixels on 
	// the top, so we've reserved some space for it.
	int heightOffset = [self frame].size.height - 10;

	[_title drawWithEllipsisInRect:NSMakeRect( 55.f, heightOffset - 15.f, 200.0f, 15.0f ) withAttributes:
		[NSDictionary dictionaryWithObjectsAndKeys:
			[NSFont boldSystemFontOfSize:13.f], NSFontAttributeName,
			_textColor, NSForegroundColorAttributeName,
			nil]];
	[_text drawInRect:NSMakeRect( 55.f, 10.f, 200.f, heightOffset - 25.f ) withAttributes:
		[NSDictionary dictionaryWithObjectsAndKeys:
			[NSFont messageFontOfSize:11.f], NSFontAttributeName,
			_textColor, NSForegroundColorAttributeName,
			nil]];
	
	NSSize iconSize = [_icon size];
	if( iconSize.width > 32.f || iconSize.height > 32.f ) {

		// scale the image appropriately
		float newWidth, newHeight, newX, newY;
		if( iconSize.width > iconSize.height ) {
			newWidth = 32.f;
			newHeight = 32.f / iconSize.width * iconSize.height;
		} else if( iconSize.width < iconSize.height ) {
			newWidth = 32.f / iconSize.height * iconSize.width;
			newHeight = 32.f;
		} else {
			newWidth = 32.f;
			newHeight = 32.f;
		}
		
		newX = floorf((32 - newWidth) * 0.5f);
		newY = floorf((32 - newHeight) * 0.5f);
		
		NSRect newBounds = { { newX, newY }, { newWidth, newHeight } };
		NSImageRep *sourceImageRep = [_icon bestRepresentationForDevice:nil];
		[_icon autorelease];
		_icon = [[NSImage alloc] initWithSize:NSMakeSize(32.f, 32.f)];
		[_icon lockFocus];
		[[NSGraphicsContext currentContext] setImageInterpolation: NSImageInterpolationHigh];
		[sourceImageRep drawInRect:newBounds];
		[_icon unlockFocus];
	}

	[_icon compositeToPoint:NSMakePoint( 15.f, heightOffset - 35.f ) operation:NSCompositeSourceAtop fraction:1.f];

	[[self window] invalidateShadow];
}

#pragma mark -

- (void)setPriority:(int)priority {
    NSString* key;
    NSString* textKey;
    switch (priority) {
        case -2:
            key = GrowlBubblesVeryLowColor;
			textKey = GrowlBubblesVeryLowTextColor;
            break;
        case -1:
            key = GrowlBubblesModerateColor;
			textKey = GrowlBubblesModerateTextColor;
            break;
        case 1:
            key = GrowlBubblesHighColor;
			textKey = GrowlBubblesHighTextColor;
            break;
        case 2:
            key = GrowlBubblesEmergencyColor;
			textKey = GrowlBubblesEmergencyTextColor;
            break;
        case 0:
        default:
            key = GrowlBubblesNormalColor;
			textKey = GrowlBubblesNormalTextColor;
            break;
    }
    NSArray *array;
	
//	float backgroundAlpha = GrowlSmokeAlphaPrefDefault;
//	READ_GROWL_PREF_FLOAT(GrowlSmokeAlphaPref, GrowlSmokePrefDomain, &backgroundAlpha);

	_bgColor = [NSColor colorWithCalibratedRed:.69412f
									  green:.83147f
									   blue:.96078f
									  alpha:.95f];

	READ_GROWL_PREF_VALUE(key, GrowlBubblesPrefDomain, CFArrayRef, (CFArrayRef*)&array);
    if (array && [array isKindOfClass:[NSArray class]]) {
        _bgColor = [NSColor colorWithCalibratedRed:[[array objectAtIndex:0] floatValue]
                                             green:[[array objectAtIndex:1] floatValue]
                                              blue:[[array objectAtIndex:2] floatValue]
                                             alpha:.95f];
        [array release];
    }
    [_bgColor retain];

	_textColor = [NSColor controlTextColor];
	READ_GROWL_PREF_VALUE(textKey, GrowlBubblesPrefDomain, CFArrayRef, (CFArrayRef*)&array);
    if (array && [array isKindOfClass:[NSArray class]]) {
        _textColor = [NSColor colorWithCalibratedRed:[[array objectAtIndex:0] floatValue]
                                             green:[[array objectAtIndex:1] floatValue]
                                              blue:[[array objectAtIndex:2] floatValue]
                                             alpha:1.0f];
        [array release];
    }
    [_textColor retain];
}

- (void) setIcon:(NSImage *) icon {
	[_icon autorelease];
	_icon = [icon retain];
	[self setNeedsDisplay:YES];
}

- (void) setTitle:(NSString *) title {
	[_title autorelease];
	_title = [title copy];
	[self setNeedsDisplay:YES];
}

- (void) setText:(NSString *) text {
	[_text autorelease];
	_text = [text copy];
	_textHeight = 0;
	[self setNeedsDisplay:YES];
	[self sizeToFit];
}

- (void) sizeToFit {
    NSRect rect = [self frame];
	rect.size.height = 10 + 10 + 15 + [self descriptionHeight];
	[self setFrame:rect];
}

- (float) descriptionHeight {
	
	if (_textHeight == 0) {
		NSAttributedString *attributedText = [[NSAttributedString alloc] initWithString:_text attributes:
			[NSDictionary dictionaryWithObjectsAndKeys:
				[NSFont messageFontOfSize:11.f], NSFontAttributeName,
				_textColor, NSForegroundColorAttributeName,
				nil]];
		NSTextStorage* textStorage = [[NSTextStorage alloc] initWithAttributedString:attributedText];
		NSTextContainer* textContainer = [[[NSTextContainer alloc]
			initWithContainerSize:NSMakeSize ( 200.f, FLT_MAX )] autorelease];
		NSLayoutManager* layoutManager = [[[NSLayoutManager alloc] init] autorelease];

		[layoutManager addTextContainer:textContainer];
		[textStorage addLayoutManager:layoutManager];
		[layoutManager glyphRangeForTextContainer:textContainer];

		_textHeight = [layoutManager usedRectForTextContainer:textContainer].size.height;
		[attributedText release];

		// for some reason, this code is using a 13-point line height for calculations, but the font 
		// in fact renders in 14 points of space. Do some adjustments.
		int _rowCount = _textHeight / 13;
		BOOL limitPref = YES;
		READ_GROWL_PREF_BOOL(KALimitPref, GrowlBubblesPrefDomain, &limitPref);
		if (limitPref) {
			_textHeight = MIN(_rowCount, 5) * 14;
		} else {
			_textHeight = _rowCount * 14;
		}
	}
	return MAX (_textHeight, 30);
}

- (int) descriptionRowCount {
	float height = [self descriptionHeight];
	NSAttributedString *attributedText = [[NSAttributedString alloc] initWithString:_text attributes:
		[NSDictionary dictionaryWithObjectsAndKeys:
			[NSFont messageFontOfSize:11.f], NSFontAttributeName,
			_textColor, NSForegroundColorAttributeName,
			nil]];
	float lineHeight = [attributedText size].height;
	[attributedText release];
	BOOL limitPref = YES;
	READ_GROWL_PREF_BOOL(KALimitPref, GrowlBubblesPrefDomain, &limitPref);
	if (limitPref) {
		return MIN((int) (height / lineHeight), 5);
	} else {
		return (int) (height / lineHeight);
	}
}

#pragma mark -

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

- (BOOL) acceptsFirstMouse:(NSEvent *) event {
	return YES;
}

 - (void) mouseDown:(NSEvent *) event {
	if( _target && _action && [_target respondsToSelector:_action] )
		[_target performSelector:_action withObject:self];
}
@end
