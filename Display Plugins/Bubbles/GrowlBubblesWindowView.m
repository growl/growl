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
#import "GrowlImageAdditions.h"
#import "GrowlBezierPathAdditions.h"
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
		_textHeight = 0.0f;
		_titleHeight = 0.0f;
		_target = nil;
		_action = NULL;
		_borderColor = [NSColor colorWithCalibratedRed:0.f green:0.f blue:0.f alpha:.5f];
	}
	return self;
}

- (void) dealloc {
	[_icon release];
	[_title release];
	[_text release];
	[_bgColor release];
	[_textColor release];

	[super dealloc];
}

- (float)titleHeight {
	if( !_titleHeight ) {
		NSLayoutManager *lm = [[NSLayoutManager alloc] init];
		_titleHeight = [lm defaultLineHeightForFont:[NSFont boldSystemFontOfSize:13.f]];
		[lm release];
	}

	return _titleHeight;
}

- (void) drawRect:(NSRect) rect {

	NSRect bounds = [self bounds];

	[[NSColor clearColor] set];
	NSRectFill( [self frame] );

	NSBezierPath *path = [NSBezierPath roundedRectPath:bounds radius:9.f lineWidth:4.f];

	NSGraphicsContext *graphicsContext = [NSGraphicsContext currentContext];
	[graphicsContext saveGraphicsState];

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

	CGContextDrawShading( [graphicsContext graphicsPort], shading );

	CGShadingRelease( shading );
	CGColorSpaceRelease( cspace );
	CGFunctionRelease( function );

	[graphicsContext restoreGraphicsState];

	[_borderColor set];
	[path stroke];

	// Top of the drawing area. The eye candy takes up 10 pixels on 
	// the top, so we've reserved some space for it.
	float contentHeight = [self frame].size.height - 10.0f;
	float titleYPosition = contentHeight - [self titleHeight];
	NSRect drawRect;
	drawRect.origin.x = 55.f;
	drawRect.origin.y = titleYPosition;
	drawRect.size.width = 200.f;
	drawRect.size.height = [self titleHeight];

	[_title drawWithEllipsisInRect:drawRect withAttributes:
		[NSDictionary dictionaryWithObjectsAndKeys:
			[NSFont boldSystemFontOfSize:13.f], NSFontAttributeName,
			_textColor, NSForegroundColorAttributeName,
			nil]];

	drawRect.origin.y = 10.f;
	drawRect.size.height = titleYPosition - 10.f;

	[_text drawInRect:drawRect withAttributes:
		[NSDictionary dictionaryWithObjectsAndKeys:
			[NSFont messageFontOfSize:11.f], NSFontAttributeName,
			_textColor, NSForegroundColorAttributeName,
			nil]];
	
	drawRect.origin.x = 15.f;
	drawRect.origin.y = contentHeight - 35.f;
	drawRect.size.width = 32.f;
	drawRect.size.height = 32.f;
	
	// we do this because we are always working with a copy
	[_icon drawScaledInRect:drawRect
				  operation:NSCompositeSourceAtop
				   fraction:1.f];

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
	if( _target && _action && [_target respondsToSelector:_action] ) {
		[_target performSelector:_action withObject:self];
	}
}
@end
