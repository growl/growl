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
	NSColor *bgColor = (NSColor *) info;

	float bgRed, bgGreen, bgBlue, bgAlpha;
	[bgColor getRed:&bgRed
			  green:&bgGreen
			   blue:&bgBlue
			  alpha:&bgAlpha];

	//NSLog(@"data red: %f green: %f blue: %f alpha: %f", bgRed, bgGreen, bgBlue, bgAlpha);
	//static const float bg[4] = { 0.69412f, 0.83147f, 0.96078f, 0.95f };
	static const float light[4] = { 0.93725f, 0.96863f, 0.99216f, 0.95f };

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
	if ( (self = [super initWithFrame:frame] ) ) {
		icon   = nil;
		title  = nil;
		text   = nil;
		textHeight = 0.0f;
		titleHeight = 0.0f;
		target = nil;
		action = NULL;
		borderColor = [NSColor colorWithCalibratedRed:0.0f green:0.0f blue:0.0f alpha:0.5f];
	}
	return self;
}

- (void) dealloc {
	[icon release];
	[title release];
	[text release];
	[bgColor release];
	[textColor release];

	[super dealloc];
}

- (float)titleHeight {
	if ( !titleHeight ) {
		NSLayoutManager *lm = [[NSLayoutManager alloc] init];
		titleHeight = [lm defaultLineHeightForFont:[NSFont boldSystemFontOfSize:13.0f]];
		[lm release];
	}

	return titleHeight;
}

- (void) drawRect:(NSRect) rect {
	NSRect bounds = [self bounds];
	NSRect frame  = [self frame];

	[[NSColor clearColor] set];
	NSRectFill( frame );

	NSBezierPath *path = [NSBezierPath roundedRectPath:bounds radius:9.0f lineWidth:4.0f];

	NSGraphicsContext *graphicsContext = [NSGraphicsContext currentContext];
	[graphicsContext saveGraphicsState];

	[path setClip];

	// Create a callback function to generate the 
    // fill clipped graphics context with our gradient
	struct CGFunctionCallbacks callbacks = { 0U, GrowlBubblesShadeInterpolate, NULL };
	CGFunctionRef function = CGFunctionCreate( (void *) bgColor, 1U, /*domain*/ NULL, 4U, /*range*/ NULL, &callbacks );
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

	[borderColor set];
	[path stroke];

	// Top of the drawing area. The eye candy takes up 10 pixels on 
	// the top, so we've reserved some space for it.
	float contentHeight = frame.size.height - 10.0f;
	float savedTitleHeight = [self titleHeight];
	float titleYPosition = contentHeight - savedTitleHeight;
	NSRect drawRect;
	drawRect.origin.x = 55.0f;
	drawRect.origin.y = titleYPosition;
	drawRect.size.width = 200.0f;
	drawRect.size.height = savedTitleHeight;

	[title drawWithEllipsisInRect:drawRect withAttributes:
		[NSDictionary dictionaryWithObjectsAndKeys:
			[NSFont boldSystemFontOfSize:13.f], NSFontAttributeName,
			textColor, NSForegroundColorAttributeName,
			nil]];

	drawRect.origin.y = 10.0f;
	drawRect.size.height = titleYPosition - 10.0f;

	[text drawInRect:drawRect withAttributes:
		[NSDictionary dictionaryWithObjectsAndKeys:
			[NSFont messageFontOfSize:11.0f], NSFontAttributeName,
			textColor, NSForegroundColorAttributeName,
			nil]];
	
	drawRect.origin.x = 15.0f;
	drawRect.origin.y = contentHeight - 35.0f;
	drawRect.size.width = 32.0f;
	drawRect.size.height = 32.0f;
	
	// we do this because we are always working with a copy
	[icon drawScaledInRect:drawRect
				  operation:NSCompositeSourceAtop
				   fraction:1.0f];

	[[self window] invalidateShadow];
}

#pragma mark -

- (void) setPriority:(int)priority {
    NSString *key;
    NSString *textKey;
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

	bgColor = [NSColor colorWithCalibratedRed:0.69412f
										green:0.83147f
										 blue:0.96078f
										alpha:0.95f];

	READ_GROWL_PREF_VALUE(key, GrowlBubblesPrefDomain, CFArrayRef, (CFArrayRef*)&array);
    if (array && [array isKindOfClass:[NSArray class]]) {
        bgColor = [NSColor colorWithCalibratedRed:[[array objectAtIndex:0U] floatValue]
											green:[[array objectAtIndex:1U] floatValue]
											 blue:[[array objectAtIndex:2U] floatValue]
											alpha:0.95f];
        [array release];
    }
    [bgColor retain];

	textColor = [NSColor controlTextColor];
	READ_GROWL_PREF_VALUE(textKey, GrowlBubblesPrefDomain, CFArrayRef, (CFArrayRef*)&array);
    if (array && [array isKindOfClass:[NSArray class]]) {
        textColor = [NSColor colorWithCalibratedRed:[[array objectAtIndex:0U] floatValue]
											  green:[[array objectAtIndex:1U] floatValue]
											   blue:[[array objectAtIndex:2U] floatValue]
											  alpha:1.0f];
        [array release];
    }
    [textColor retain];
}

- (void) setIcon:(NSImage *) anIcon {
	[icon autorelease];
	icon = [anIcon retain];
	[self setNeedsDisplay:YES];
}

- (void) setTitle:(NSString *) aTitle {
	[title autorelease];
	title = [aTitle copy];
	titleHeight = 0.0f;
	[self setNeedsDisplay:YES];
}

- (void) setText:(NSString *) aText {
	[text autorelease];
	text = [aText copy];
	textHeight = 0.0f;
	[self setNeedsDisplay:YES];
	[self sizeToFit];
}

- (void) sizeToFit {
    NSRect rect = [self frame];
	rect.size.height = 10.0f + 12.0f + 15.0f + [self descriptionHeight];
	[self setFrame:rect];
}

- (float) descriptionHeight {
	if (!textHeight) {
		NSAttributedString *attributedText = [[NSAttributedString alloc] initWithString:text attributes:
			[NSDictionary dictionaryWithObjectsAndKeys:
				[NSFont messageFontOfSize:11.0f], NSFontAttributeName,
				textColor, NSForegroundColorAttributeName,
				nil]];
		NSTextStorage *textStorage = [[NSTextStorage alloc] initWithAttributedString:attributedText];
		NSTextContainer *textContainer = [[[NSTextContainer alloc]
			initWithContainerSize:NSMakeSize ( 200.0f, FLT_MAX )] autorelease];
		NSLayoutManager *layoutManager = [[[NSLayoutManager alloc] init] autorelease];

		[layoutManager addTextContainer:textContainer];
		[textStorage addLayoutManager:layoutManager];
		[layoutManager glyphRangeForTextContainer:textContainer];

		textHeight = [layoutManager usedRectForTextContainer:textContainer].size.height;
		[attributedText release];

		// for some reason, this code is using a 13-point line height for calculations, but the font 
		// in fact renders in 14 points of space. Do some adjustments.
		int rowCount = textHeight / 13;
		BOOL limitPref = YES;
		READ_GROWL_PREF_BOOL(KALimitPref, GrowlBubblesPrefDomain, &limitPref);
		if (limitPref) {
			textHeight = MIN(rowCount, 5) * 14.0f;
		} else {
			textHeight = rowCount * 14.0f;
		}
	}
	return MAX (textHeight, 30.0f);
}

- (int) descriptionRowCount {
	float height = [self descriptionHeight];
	NSAttributedString *attributedText = [[NSAttributedString alloc] initWithString:text attributes:
		[NSDictionary dictionaryWithObjectsAndKeys:
			[NSFont messageFontOfSize:11.0f], NSFontAttributeName,
			textColor, NSForegroundColorAttributeName,
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
	return target;
}

- (void) setTarget:(id) object {
	target = object;
}

#pragma mark -

- (SEL) action {
	return action;
}

- (void) setAction:(SEL) selector {
	action = selector;
}

#pragma mark -

- (BOOL) acceptsFirstMouse:(NSEvent *) event {
	return YES;
}

 - (void) mouseDown:(NSEvent *) event {
	if ( target && action && [target respondsToSelector:action] ) {
		[target performSelector:action withObject:self];
	}
}
@end
