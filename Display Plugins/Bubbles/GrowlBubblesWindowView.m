//
//  GrowlBubblesWindowView.m
//  Growl
//
//  Created by Nelson Elhage on Wed Jun 09 2004.
//  Name changed from KABubbleWindowView.m by Justin Burns on Fri Nov 05 2004.
//  Copyright (c) 2004 Nelson Elhage. All rights reserved.
//

#import "GrowlBubblesWindowView.h"
#import "GrowlDefinesInternal.h"
#import "GrowlBubblesDefines.h"
#import "NSGrowlAdditions.h"
#import "GrowlImageAdditions.h"
#import "GrowlBezierPathAdditions.h"
#import <math.h>

/* to get the limit pref */
#import "GrowlBubblesPrefsController.h"

/* Hardcoded geometry values */
#define PANEL_WIDTH_PX			270.0f /*!< Total width of the panel, including border */
#define BORDER_WIDTH_PX			  4.0f
#define BORDER_RADIUS_PX		  9.0f
#define PANEL_VSPACE_PX			 10.0f /*!< Vertical padding from bounds to content area */
#define PANEL_HSPACE_PX			 15.0f /*!< Horizontal padding from bounds to content area */
#define ICON_SIZE_PX			 32.0f /*!< The width and height of the (square) icon */
#define ICON_HSPACE_PX			  8.0f /*!< Horizontal space between icon and title/description */
#define TITLE_VSPACE_PX			 15.0f /*!< Vertical space between title and description */
#define TITLE_FONT_SIZE_PTS		 13.0f
#define DESCR_FONT_SIZE_PTS		 11.0f
#define MIN_TEXT_HEIGHT_PX		 30.0f
#define MAX_TEXT_ROWS			    5  /*!< The maximum number of rows of text, used only if the limit preference is set. */

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
		titleFont = [[NSFont boldSystemFontOfSize:TITLE_FONT_SIZE_PTS] retain];
		textFont = [[NSFont messageFontOfSize:DESCR_FONT_SIZE_PTS] retain];
		icon   = nil;
		title  = nil;
		text   = nil;
		textHeight = 0.0f;
		titleHeight = 0.0f;
		target = nil;
		action = NULL;
		borderColor = [[NSColor colorWithCalibratedRed:0.0f green:0.0f blue:0.0f alpha:0.5f] retain];
	}
	return self;
}

- (void) dealloc {
	[titleFont release];
	[textFont release];
	[icon release];
	[title release];
	[text release];
	[bgColor release];
	[textColor release];
	[borderColor release];

	[super dealloc];
}

- (float)titleHeight {
	if ( !titleHeight ) {
		titleHeight = [titleFont defaultLineHeightForFont];
	}

	return titleHeight;
}

- (void) drawRect:(NSRect) rect {
	NSRect bounds = [self bounds];
	NSRect frame  = [self frame];

	[[NSColor clearColor] set];
	NSRectFill( frame );

	// Create a path with enough room to strike the border and remain inside our frame.
	// Since the path is in the middle of the line, this means we must inset it by half the border width.
	NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:NSInsetRect(bounds, BORDER_WIDTH_PX/2.0f, BORDER_WIDTH_PX/2.0f)
														  radius:BORDER_RADIUS_PX];
	[path setLineWidth:BORDER_WIDTH_PX];

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

	float contentHeight = frame.size.height - PANEL_VSPACE_PX;
	float savedTitleHeight = [self titleHeight];
	float titleYPosition = contentHeight - savedTitleHeight;
	NSRect drawRect;
	drawRect.origin.x = PANEL_HSPACE_PX + ICON_SIZE_PX + ICON_HSPACE_PX;
	drawRect.origin.y = titleYPosition;
	drawRect.size.width = PANEL_WIDTH_PX - PANEL_HSPACE_PX - drawRect.origin.x;
	drawRect.size.height = savedTitleHeight;

	[title drawWithEllipsisInRect:drawRect withAttributes:
		[NSDictionary dictionaryWithObjectsAndKeys:
			titleFont, NSFontAttributeName,
			textColor, NSForegroundColorAttributeName,
			nil]];

	drawRect.origin.y = PANEL_VSPACE_PX;
	drawRect.size.height = titleYPosition - TITLE_VSPACE_PX;

	[text drawInRect:drawRect withAttributes:
		[NSDictionary dictionaryWithObjectsAndKeys:
			textFont, NSFontAttributeName,
			textColor, NSForegroundColorAttributeName,
			nil]];
	
	drawRect.origin.x = PANEL_HSPACE_PX;
	drawRect.origin.y = contentHeight - ICON_SIZE_PX;
	drawRect.size.width = ICON_SIZE_PX;
	drawRect.size.height = ICON_SIZE_PX;
	
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
	rect.size.width = PANEL_WIDTH_PX;
	rect.size.height = 2.0f * PANEL_VSPACE_PX + [self titleHeight] + TITLE_VSPACE_PX + [self descriptionHeight];
	[self setFrame:rect];
}

- (float) descriptionHeight {
	if (!textHeight) {
		textHeight = [self descriptionRowCount] * [textFont defaultLineHeightForFont];
		textHeight = MAX(textHeight, MIN_TEXT_HEIGHT_PX);
	}
	return textHeight;
}

- (int) descriptionRowCount {
	NSAttributedString *attributedText = [[NSAttributedString alloc] initWithString:text attributes:
		[NSDictionary dictionaryWithObjectsAndKeys:
			textFont, NSFontAttributeName,
			textColor, NSForegroundColorAttributeName,
			nil]];
	NSTextStorage *textStorage = [[NSTextStorage alloc] initWithAttributedString:attributedText];
	NSTextContainer *textContainer = [[[NSTextContainer alloc]
		initWithContainerSize:NSMakeSize ( PANEL_WIDTH_PX - 2.0f * PANEL_HSPACE_PX - ICON_SIZE_PX - ICON_HSPACE_PX,
										   FLT_MAX )] autorelease];
	NSLayoutManager *layoutManager = [[[NSLayoutManager alloc] init] autorelease];

	[layoutManager addTextContainer:textContainer];
	[textStorage addLayoutManager:layoutManager];
	[layoutManager glyphRangeForTextContainer:textContainer];

	textHeight = [layoutManager usedRectForTextContainer:textContainer].size.height;
	[attributedText release];

	int rowCount = textHeight / [textFont defaultLineHeightForFont];
	BOOL limitPref = YES;
	READ_GROWL_PREF_BOOL(KALimitPref, GrowlBubblesPrefDomain, &limitPref);
	if (limitPref) {
		return MIN(rowCount, MAX_TEXT_ROWS);
	} else {
		return rowCount;
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
