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
#import "GrowlImageAdditions.h"
#import "GrowlBezierPathAdditions.h"

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
#define TITLE_VSPACE_PX			  5.0f /*!< Vertical space between title and description */
#define TITLE_FONT_SIZE_PTS		 13.0f
#define DESCR_FONT_SIZE_PTS		 11.0f
#define MAX_TEXT_ROWS				5  /*!< The maximum number of rows of text, used only if the limit preference is set. */
#define MIN_TEXT_HEIGHT			(PANEL_VSPACE_PX + PANEL_VSPACE_PX + ICON_SIZE_PX)
#define TEXT_AREA_WIDTH			(PANEL_WIDTH_PX - PANEL_HSPACE_PX - PANEL_HSPACE_PX - ICON_SIZE_PX - ICON_HSPACE_PX)

static void GrowlBubblesShadeInterpolate( void *info, const float *inData, float *outData ) {
	float *colors = (float *) info;

	register float a = inData[0];
	register float a_coeff = 1.0f - a;

	// SIMD could come in handy here
	// outData[0..3] = a_coeff * colors[4..7] + a * colors[0..3]
	outData[0] = a_coeff * colors[4] + a * colors[0];
	outData[1] = a_coeff * colors[5] + a * colors[1];
	outData[2] = a_coeff * colors[6] + a * colors[2];
	outData[3] = a_coeff * colors[7] + a * colors[3];
}

#pragma mark -

@implementation GrowlBubblesWindowView
- (id) initWithFrame:(NSRect) frame {
	if ((self = [super initWithFrame:frame])) {
		titleFont = [[NSFont boldSystemFontOfSize:TITLE_FONT_SIZE_PTS] retain];
		textFont = [[NSFont messageFontOfSize:DESCR_FONT_SIZE_PTS] retain];
		borderColor = [[NSColor colorWithCalibratedRed:0.0f green:0.0f blue:0.0f alpha:0.5f] retain];
		layoutManager = [[NSLayoutManager alloc] init];
		titleHeight = [layoutManager defaultLineHeightForFont:titleFont];
	}
	return self;
}

- (void) dealloc {
	[titleFont     release];
	[textFont      release];
	[icon          release];
	[title         release];
	[text          release];
	[bgColor       release];
	[textColor     release];
	[borderColor   release];
	[lightColor    release];
	[textStorage   release];
	[layoutManager release];

	[super dealloc];
}

- (float)titleHeight {
	if (!title || ![title length]) {
		return 0.0f;
	}

	return titleHeight;
}

- (void) drawRect:(NSRect) rect {
	NSRect bounds = [self bounds];
	NSRect frame  = [self frame];

	[[NSColor clearColor] set];
	NSRectFill(frame);

	// Create a path with enough room to strike the border and remain inside our frame.
	// Since the path is in the middle of the line, this means we must inset it by half the border width.
	NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:NSInsetRect(bounds, BORDER_WIDTH_PX*0.5f, BORDER_WIDTH_PX*0.5f)
														  radius:BORDER_RADIUS_PX];
	[path setLineWidth:BORDER_WIDTH_PX];

	NSGraphicsContext *graphicsContext = [NSGraphicsContext currentContext];
	[graphicsContext saveGraphicsState];

	[path setClip];

	// Create a callback function to generate the 
	// fill clipped graphics context with our gradient
	struct CGFunctionCallbacks callbacks = { 0U, GrowlBubblesShadeInterpolate, NULL };
	float colors[8];

	[bgColor getRed:&colors[0]
			  green:&colors[1]
			   blue:&colors[2]
			  alpha:&colors[3]];

	[lightColor getRed:&colors[4]
				 green:&colors[5]
				  blue:&colors[6]
				 alpha:&colors[7]];

	CGFunctionRef function = CGFunctionCreate( (void *) colors,
											   1U,
											   /*domain*/ NULL,
											   4U,
											   /*range*/ NULL,
											   &callbacks );
	CGColorSpaceRef cspace = CGColorSpaceCreateDeviceRGB();

	CGPoint src, dst;
	src.x = NSMinX( bounds );
	src.y = NSMinY( bounds );
	dst.x = src.x;
	dst.y = NSMaxY( bounds );
	CGShadingRef shading = CGShadingCreateAxial( cspace, src, dst,
												 function, false, false );	

	CGContextDrawShading( [graphicsContext graphicsPort], shading );

	CGShadingRelease( shading );
	CGColorSpaceRelease( cspace );
	CGFunctionRelease( function );

	[graphicsContext restoreGraphicsState];

	[borderColor set];
	[path stroke];

	NSRect drawRect;
	drawRect.origin.x = PANEL_HSPACE_PX + ICON_SIZE_PX + ICON_HSPACE_PX;
	drawRect.origin.y = PANEL_VSPACE_PX;
	drawRect.size.width = TEXT_AREA_WIDTH;

	if (title && [title length]) {
		drawRect.size.height = titleHeight;

		NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
		[paragraphStyle setLineBreakMode:NSLineBreakByTruncatingTail];

		NSDictionary *attributes = [[NSDictionary alloc] initWithObjectsAndKeys:
			titleFont,      NSFontAttributeName,
			textColor,      NSForegroundColorAttributeName,
			paragraphStyle, NSParagraphStyleAttributeName,
			nil];
		[title drawInRect:drawRect withAttributes:attributes];
		[attributes release];
		[paragraphStyle release];

		drawRect.origin.y += drawRect.size.height + TITLE_VSPACE_PX;
	}

	if (text && [text length]) {
		NSRange glyphRange = [layoutManager glyphRangeForTextContainer:textContainer];
		[layoutManager drawGlyphsForGlyphRange:glyphRange atPoint:drawRect.origin];
	}

	drawRect.origin.x = PANEL_HSPACE_PX;
	drawRect.origin.y = PANEL_VSPACE_PX;
	drawRect.size.width = ICON_SIZE_PX;
	drawRect.size.height = ICON_SIZE_PX;

	[icon setFlipped:YES];
	[icon drawScaledInRect:drawRect
				  operation:NSCompositeSourceOver
				   fraction:1.0f];

	[[self window] invalidateShadow];
}

#pragma mark -

- (void) setPriority:(int)priority {
	NSString *key;
	NSString *textKey;
	NSString *topKey;

	switch (priority) {
		case -2:
			key = GrowlBubblesVeryLowColor;
			textKey = GrowlBubblesVeryLowTextColor;
			topKey = GrowlBubblesVeryLowTopColor;
			break;
		case -1:
			key = GrowlBubblesModerateColor;
			textKey = GrowlBubblesModerateTextColor;
			topKey = GrowlBubblesModerateTopColor;
			break;
		case 1:
			key = GrowlBubblesHighColor;
			textKey = GrowlBubblesHighTextColor;
			topKey = GrowlBubblesHighTopColor;
			break;
		case 2:
			key = GrowlBubblesEmergencyColor;
			textKey = GrowlBubblesEmergencyTextColor;
			topKey = GrowlBubblesEmergencyTopColor;
			break;
		case 0:
		default:
			key = GrowlBubblesNormalColor;
			textKey = GrowlBubblesNormalTextColor;
			topKey = GrowlBubblesNormalTopColor;
			break;
	}
	NSArray *array = nil;

	float backgroundAlpha = 0.95f;
	READ_GROWL_PREF_FLOAT(GrowlBubblesOpacity, GrowlBubblesPrefDomain, &backgroundAlpha);

	Class NSArrayClass = [NSArray class];
	READ_GROWL_PREF_VALUE(key, GrowlBubblesPrefDomain, NSArray *, &array);
	if (array && [array isKindOfClass:NSArrayClass]) {
		bgColor = [NSColor colorWithCalibratedRed:[[array objectAtIndex:0U] floatValue]
											green:[[array objectAtIndex:1U] floatValue]
											 blue:[[array objectAtIndex:2U] floatValue]
											alpha:backgroundAlpha];
	} else {
		bgColor = [NSColor colorWithCalibratedRed:0.69412f
											green:0.83147f
											 blue:0.96078f
											alpha:backgroundAlpha];
	}
	[bgColor retain];
	[array release];

	array = nil;
	READ_GROWL_PREF_VALUE(textKey, GrowlBubblesPrefDomain, NSArray *, &array);
	if (array && [array isKindOfClass:NSArrayClass]) {
		textColor = [NSColor colorWithCalibratedRed:[[array objectAtIndex:0U] floatValue]
											  green:[[array objectAtIndex:1U] floatValue]
											   blue:[[array objectAtIndex:2U] floatValue]
											  alpha:1.0f];
	} else {
		textColor = [NSColor controlTextColor];
	}
	[textColor retain];
	[array release];

	array = nil;
	READ_GROWL_PREF_VALUE(topKey, GrowlBubblesPrefDomain, NSArray *, &array);
	if (array && [array isKindOfClass:NSArrayClass]) {
		lightColor = [NSColor colorWithCalibratedRed:[[array objectAtIndex:0U] floatValue]
											   green:[[array objectAtIndex:1U] floatValue]
												blue:[[array objectAtIndex:2U] floatValue]
											   alpha:1.0f];
	} else {
		lightColor = [NSColor colorWithCalibratedRed:0.93725f green:0.96863f blue:0.99216f alpha:0.95f];
	}
	[lightColor retain];
	[array release];
}

- (void) setIcon:(NSImage *) anIcon {
	[icon release];
	icon = [anIcon retain];
	[self setNeedsDisplay:YES];
}

- (void) setTitle:(NSString *) aTitle {
	[title release];
	title = [aTitle copy];
	[self setNeedsDisplay:YES];
}

- (void) setText:(NSString *) aText {
	[text release];
	text = [aText copy];

	if (!textStorage) {
		textStorage = [[NSTextStorage alloc] init];
		NSSize containerSize = { TEXT_AREA_WIDTH, FLT_MAX };
		textContainer = [[NSTextContainer alloc] initWithContainerSize:containerSize];
		[layoutManager addTextContainer:textContainer];	// retains textContainer
		[textContainer release];
		[textStorage addLayoutManager:layoutManager];	// retains layoutManager
		[textContainer setLineFragmentPadding:0.0f];
	}

	NSDictionary *attributes = [[NSDictionary alloc] initWithObjectsAndKeys:
		textFont,  NSFontAttributeName,
		textColor, NSForegroundColorAttributeName,
		nil];

	[[textStorage mutableString] setString:text];
	[textStorage setAttributes:attributes range:NSMakeRange(0, [textStorage length])];

	[attributes release];

	[layoutManager glyphRangeForTextContainer:textContainer];	// force layout		
	textHeight = [layoutManager usedRectForTextContainer:textContainer].size.height;

	[self sizeToFit];
	[self setNeedsDisplay:YES];
}

- (void) sizeToFit {
	NSRect rect = [self frame];
	rect.size.width = PANEL_WIDTH_PX;
	rect.size.height = PANEL_VSPACE_PX + PANEL_VSPACE_PX + [self titleHeight] + [self descriptionHeight];
	if (title && text && [title length] && [text length]) {
		rect.size.height += TITLE_VSPACE_PX;
	}
	if (rect.size.height < MIN_TEXT_HEIGHT) {
		rect.size.height = MIN_TEXT_HEIGHT;
	}
	[self setFrame:rect];
}

- (BOOL)isFlipped {
	// Coordinates are based on top left corner
    return YES;
}

- (float) descriptionHeight {
	if (!text || ![text length]) {
		return 0.0f;
	}

	return textHeight;
}

- (int) descriptionRowCount {
	int rowCount = textHeight / [layoutManager defaultLineHeightForFont:textFont];
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
	if (target && action && [target respondsToSelector:action]) {
		[target performSelector:action withObject:self];
	}
}
@end
