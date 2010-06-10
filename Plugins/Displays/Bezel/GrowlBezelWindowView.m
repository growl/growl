//
//  GrowlBezelWindowView.m
//  Display Plugins
//
//  Created by Jorge Salvador Caffarena on 09/09/04.
//  Copyright 2004 Jorge Salvador Caffarena. All rights reserved.
//

#import "GrowlBezelWindowView.h"
#import "GrowlBezelPrefs.h"
#import "GrowlImageAdditions.h"
#import "GrowlBezierPathAdditions.h"

#define BORDER_RADIUS 20.0

@implementation GrowlBezelWindowView

- (id) initWithFrame:(NSRect) frame {
	if ((self = [super initWithFrame:frame])) {
		layoutManager = [[NSLayoutManager alloc] init];
	}
	return self;
}

- (void) dealloc {
	[icon            release];
	[title           release];
	[text            release];
	[textColor       release];
	[backgroundColor release];
	[layoutManager   release];

	[super dealloc];
}

static void CharcoalShadeInterpolate( void *info, const CGFloat *inData, CGFloat *outData ) {
//	const CGFloat colors[2] = {0.15, 0.35};
	const CGFloat colors[2] = {27.0 / 255.0 * 1.5, 58.0 / 255.0};

	CGFloat a = inData[0] * 2.0;
	CGFloat a_coeff;
	CGFloat c;

	if (a > 1.0)
		a = 2.0 - a;
	a_coeff = 1.0 - a;
	c = a * colors[1] + a_coeff * colors[0];
	outData[0] = c;
	outData[1] = c;
	outData[2] = c;
	outData[3] = *(CGFloat *)info;
}

- (void) drawRect:(NSRect)rect {
#pragma unused(rect)
	NSRect b = [self bounds];
	CGRect bounds = CGRectMake(b.origin.x, b.origin.y, b.size.width, b.size.height);

	CGContextRef context = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];

	addRoundedRectToPath(context, bounds, BORDER_RADIUS);

	CGFloat opacityPref = BEZEL_OPACITY_DEFAULT;
	READ_GROWL_PREF_FLOAT(BEZEL_OPACITY_PREF, GrowlBezelPrefDomain, &opacityPref);
	CGFloat alpha = opacityPref * 0.01;

	int style = 0;
	READ_GROWL_PREF_INT(BEZEL_STYLE_PREF, GrowlBezelPrefDomain, &style);
	switch (style) {
		default:
		case 0:
			// default style
			[[backgroundColor colorWithAlphaComponent:alpha] set];
			CGContextFillPath(context);
			break;
		case 1:
			// charcoal
			CGContextSaveGState(context);
			CGContextClip(context);

			struct CGFunctionCallbacks callbacks = { 0U, CharcoalShadeInterpolate, NULL };
			CGFunctionRef function = CGFunctionCreate( &alpha,
													   1U,
													   /*domain*/ NULL,
													   4U,
													   /*range*/ NULL,
													   &callbacks );
			CGColorSpaceRef cspace = CGColorSpaceCreateDeviceRGB();
			CGPoint src, dst;
			src.x = CGRectGetMinX(bounds);
			src.y = CGRectGetMinY(bounds);
			dst.x = CGRectGetMaxX(bounds);
			dst.y = src.y;
			CGShadingRef shading = CGShadingCreateAxial(cspace, src, dst,
														function, false, false);

			CGContextDrawShading(context, shading);

			CGShadingRelease(shading);
			CGColorSpaceRelease(cspace);
			CGFunctionRelease(function);

			CGContextRestoreGState(context);
			break;
	}

	int sizePref = BEZEL_SIZE_NORMAL;
	READ_GROWL_PREF_INT(BEZEL_SIZE_PREF, GrowlBezelPrefDomain, &sizePref);

	// rects
	NSRect titleRect, textRect;
	NSPoint iconPoint;
	int maxRows;
	NSSize maxIconSize;
	if (sizePref == BEZEL_SIZE_NORMAL) {
		titleRect.origin.x = 12.0;
		titleRect.origin.y = 90.0;
		titleRect.size.width = 187.0;
		titleRect.size.height = 30.0;
		textRect.origin.x = 12.0;
		textRect.origin.y = 4.0;
		textRect.size.width = 187.0;
		textRect.size.height = 80.0;
		maxRows = 4;
		maxIconSize.width = 72.0;
		maxIconSize.height = 72.0;
		iconPoint.x = 70.0;
		iconPoint.y = 120.0;
	} else {
		titleRect.origin.x = 8.0;
		titleRect.origin.y = 52.0;
		titleRect.size.width = 143.0;
		titleRect.size.height = 24.0;
		textRect.origin.x = 8.0;
		textRect.origin.y = 4.0;
		textRect.size.width = 143.0;
		textRect.size.height = 49.0;
		maxRows = 2;
		maxIconSize.width = 48.0;
		maxIconSize.height = 48.0;
		iconPoint.x = 57.0;
		iconPoint.y = 83.0;
	}

	NSShadow *textShadow = [[NSShadow alloc] init];
	NSSize shadowSize = {0.0, -2.0};
	[textShadow setShadowOffset:shadowSize];
	[textShadow setShadowBlurRadius:3.0];
	[textShadow setShadowColor:[NSColor blackColor]];

	// Draw the title, resize if text too big
	CGFloat titleFontSize = 20.0;
	NSMutableParagraphStyle *parrafo = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
	[parrafo setAlignment:NSCenterTextAlignment];
	NSMutableDictionary *titleAttributes = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
		textColor,                                   NSForegroundColorAttributeName,
		parrafo,                                     NSParagraphStyleAttributeName,
		[NSFont boldSystemFontOfSize:titleFontSize], NSFontAttributeName,
		textShadow,                                  NSShadowAttributeName,
		nil];
	CGFloat accumulator = 0.0;
	BOOL minFontSize = NO;
	NSSize titleSize = [title sizeWithAttributes:titleAttributes];

	while (titleSize.width > (NSWidth(titleRect) - (titleSize.height * 0.5))) {
		minFontSize = ( titleFontSize < 12.9 );
		if (minFontSize)
			break;
		titleFontSize -= 1.9;
		accumulator += 0.5;
		[titleAttributes setObject:[NSFont boldSystemFontOfSize:titleFontSize] forKey:NSFontAttributeName];
		titleSize = [title sizeWithAttributes:titleAttributes];
	}

	titleRect.origin.y += GrowlCGFloatCeiling(accumulator);
	titleRect.size.height = titleSize.height;

	if (minFontSize)
		[parrafo setLineBreakMode:NSLineBreakByTruncatingTail];
	[title drawInRect:titleRect withAttributes:titleAttributes];
	[titleAttributes release];

	NSFont *textFont = [NSFont systemFontOfSize:14.0];
	NSMutableDictionary *textAttributes = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
		textColor,  NSForegroundColorAttributeName,
		parrafo,    NSParagraphStyleAttributeName,
		textFont,   NSFontAttributeName,
		textShadow, NSShadowAttributeName,
		nil];
	[textShadow release];
	[parrafo release];

	CGFloat height = [self descriptionHeight:text attributes:textAttributes width:textRect.size.width];
	CGFloat lineHeight = [layoutManager defaultLineHeightForFont:textFont];
	NSInteger rowCount = height / lineHeight;

	if (rowCount > maxRows)
		[textAttributes setObject:[NSFont systemFontOfSize:12.0] forKey:NSFontAttributeName];
	[text drawInRect:textRect withAttributes:textAttributes];
	[textAttributes release];

	NSRect iconRect;
	iconRect.origin = iconPoint;
	iconRect.size = maxIconSize;
	[icon setFlipped:NO];
	[icon drawScaledInRect:iconRect operation:NSCompositeSourceOver fraction:1.0];
	[super drawRect:rect];
}

- (void) setIcon:(NSImage *)anIcon {
	[icon release];
	icon = [anIcon retain];
	[self setNeedsDisplay:YES];
}

- (void) setTitle:(NSString *)aTitle {
	[title release];
	title = [aTitle copy];
	[self setNeedsDisplay:YES];
}

- (void) setText:(NSString *)aText {
	[text release];
	text = [aText copy];
	[self setNeedsDisplay:YES];
}

- (void) setPriority:(int)priority {
	NSString *key;
	NSString *textKey;
	switch (priority) {
		case -2:
			key = GrowlBezelVeryLowBackgroundColor;
			textKey = GrowlBezelVeryLowTextColor;
			break;
		case -1:
			key = GrowlBezelModerateBackgroundColor;
			textKey = GrowlBezelModerateTextColor;
			break;
		case 1:
			key = GrowlBezelHighBackgroundColor;
			textKey = GrowlBezelHighTextColor;
			break;
		case 2:
			key = GrowlBezelEmergencyBackgroundColor;
			textKey = GrowlBezelEmergencyTextColor;
			break;
		case 0:
		default:
			key = GrowlBezelNormalBackgroundColor;
			textKey = GrowlBezelNormalTextColor;
			break;
	}

	[backgroundColor release];

	Class NSDataClass = [NSData class];
	NSData *data = nil;

	READ_GROWL_PREF_VALUE(key, GrowlBezelPrefDomain, NSData *, &data);
	if(data)
		CFMakeCollectable(data);		
	if (data && [data isKindOfClass:NSDataClass]) {
			backgroundColor = [NSUnarchiver unarchiveObjectWithData:data];
	} else {
		backgroundColor = [NSColor blackColor];
	}
	[backgroundColor retain];
	[data release];
	data = nil;

	[textColor release];
	READ_GROWL_PREF_VALUE(textKey, GrowlBezelPrefDomain, NSData *, &data);
	if(data)
		CFMakeCollectable(data);		
	if (data && [data isKindOfClass:NSDataClass]) {
			textColor = [NSUnarchiver unarchiveObjectWithData:data];
	} else {
		textColor = [NSColor whiteColor];
	}
	[textColor retain];
	[data release];
	data = nil;
}

- (CGFloat) descriptionHeight:(NSString *)theText attributes:(NSDictionary *)attributes width:(CGFloat)width {
	NSSize containerSize;
	containerSize.width = width;
	containerSize.height = FLT_MAX;
	NSTextStorage *textStorage = [[NSTextStorage alloc] initWithString:theText attributes:attributes];
	NSTextContainer *textContainer = [[NSTextContainer alloc] initWithContainerSize:containerSize];
	[textContainer setLineFragmentPadding:0.0];

	[layoutManager addTextContainer:textContainer];
	[textStorage addLayoutManager:layoutManager];
	[layoutManager glyphRangeForTextContainer:textContainer];	// force layout

	CGFloat textHeight = [layoutManager usedRectForTextContainer:textContainer].size.height;
	[textContainer release];
	[textStorage release];

	return MAX (textHeight, 30.0);
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

- (BOOL) showsCloseBox {
    return NO;
}

@end
