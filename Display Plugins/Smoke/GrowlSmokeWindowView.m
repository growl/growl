//
//  GrowlSmokeWindowView.m
//  Display Plugins
//
//  Created by Matthew Walton on 11/09/2004.
//  Copyright 2004 The Growl Project. All rights reserved.
//

#import "GrowlSmokeWindowView.h"
#import "GrowlSmokeDefines.h"
#import "GrowlDefinesInternal.h"
#import "GrowlImageAdditions.h"
#import "GrowlBezierPathAdditions.h"

#define GrowlSmokeTextAreaWidth (GrowlSmokeNotificationWidth - GrowlSmokePadding - GrowlSmokeIconSize - GrowlSmokeIconTextPadding - GrowlSmokePadding)
#define GrowlSmokeMinTextHeight	(GrowlSmokePadding + GrowlSmokeIconSize + GrowlSmokePadding)

@implementation GrowlSmokeWindowView

- (id) initWithFrame:(NSRect) frame {
	if ((self = [super initWithFrame:frame])) {
		titleFont = [[NSFont boldSystemFontOfSize:GrowlSmokeTitleFontSize] retain];
		textFont = [[NSFont systemFontOfSize:GrowlSmokeTextFontSize] retain];
		layoutManager = [[NSLayoutManager alloc] init];
		titleHeight = [layoutManager defaultLineHeightForFont:titleFont];
		lineHeight = [layoutManager defaultLineHeightForFont:textFont];
		textShadow = [[NSShadow alloc] init];
		[textShadow setShadowOffset:NSMakeSize(0.0f, -2.0f)];
		[textShadow setShadowBlurRadius:3.0f];
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
	[textShadow    release];
	[textStorage   release];
	[layoutManager release];

	[super dealloc];
}

- (BOOL)isFlipped {
	// Coordinates are based on top left corner
    return YES;
}

- (void) drawRect:(NSRect)rect {
	NSRect bounds = [self bounds];
	NSRect frame  = [self frame];
	
	// clear the window
	[[NSColor clearColor] set];
	NSRectFill( frame );

	// calculate bounds based on icon-float pref on or off
	NSRect shadedBounds;
	BOOL floatIcon = GrowlSmokeFloatIconPrefDefault;
	READ_GROWL_PREF_FLOAT(GrowlSmokeFloatIconPref, GrowlSmokePrefDomain, &floatIcon);
	if (floatIcon) {
		float sizeReduction = GrowlSmokePadding + GrowlSmokeIconSize + (GrowlSmokeIconTextPadding * 0.5f);
		
		shadedBounds = NSMakeRect(bounds.origin.x + sizeReduction,
								  bounds.origin.y,
								  bounds.size.width - sizeReduction,
								  bounds.size.height);
	} else {
		shadedBounds = bounds;
	}

	// set up bezier path for rounded corners
	NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:shadedBounds
														  radius:GrowlSmokeBorderRadius];

	NSGraphicsContext *graphicsContext = [NSGraphicsContext currentContext];
	[graphicsContext saveGraphicsState];

	// clip graphics context to path
	[path setClip];

	// fill clipped graphics context with our background colour
	[bgColor set];
	NSRectFill(frame);

	// revert to unclipped graphics context
	[graphicsContext restoreGraphicsState];

	// draw the title and the text
	NSRect drawRect;
	drawRect.origin.x = GrowlSmokePadding + GrowlSmokeIconSize + GrowlSmokeIconTextPadding;
	drawRect.origin.y = GrowlSmokePadding;
	drawRect.size.width = GrowlSmokeTextAreaWidth;

	if (title && [title length]) {
		drawRect.size.height = titleHeight;

		// construct attributes for the title
		NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
		[paragraphStyle setLineBreakMode:NSLineBreakByTruncatingTail];
		NSDictionary *titleAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
			titleFont,      NSFontAttributeName,
			textColor,      NSForegroundColorAttributeName,
			textShadow,     NSShadowAttributeName,
			paragraphStyle, NSParagraphStyleAttributeName,
			nil];
		[title drawInRect:drawRect withAttributes:titleAttributes];
		[titleAttributes release];
		[paragraphStyle release];

		drawRect.origin.y += drawRect.size.height + GrowlSmokeTitleTextPadding;
	}

	if (text && [text length]) {
		NSRange glyphRange = [layoutManager glyphRangeForTextContainer:textContainer];
		[layoutManager drawGlyphsForGlyphRange:glyphRange atPoint:drawRect.origin];
	}

	drawRect.origin.x = GrowlSmokePadding;
	drawRect.origin.y = GrowlSmokePadding;
	drawRect.size.width = GrowlSmokeIconSize;
	drawRect.size.height = GrowlSmokeIconSize;

	// we do this because we are always working with a copy
	[icon setFlipped:YES];
	[icon drawScaledInRect:drawRect
				 operation:NSCompositeSourceOver
				  fraction:1.0f];

	[[self window] invalidateShadow];
}

- (void) setIcon:(NSImage *)anIcon {
	[icon release];
	icon = [anIcon retain];
	[self sizeToFit];
	[self setNeedsDisplay:YES];
}

- (void) setTitle:(NSString *)aTitle {
	[title release];
	title = [aTitle copy];
	[self sizeToFit];
	[self setNeedsDisplay:YES];
}

- (void) setText:(NSString *)aText {
	[text release];
	text = [aText copy];

	if (!textStorage) {
		NSSize containerSize;  
		BOOL limitPref = GrowlSmokeLimitPrefDefault;
		READ_GROWL_PREF_BOOL(GrowlSmokeLimitPref, GrowlSmokePrefDomain, &limitPref);
		containerSize.width = GrowlSmokeTextAreaWidth;
		if (limitPref) {
			containerSize.height = lineHeight * GrowlSmokeMaxLines;
		} else {
			containerSize.height = FLT_MAX;
		}
		textStorage = [[NSTextStorage alloc] init];
		textContainer = [[NSTextContainer alloc] initWithContainerSize:containerSize];
		[layoutManager addTextContainer:textContainer];	// retains textContainer
		[textContainer release];
		[textStorage addLayoutManager:layoutManager];	// retains layoutManager
		[textContainer setLineFragmentPadding:0.0f];
	}

	// construct attributes for the description text
	NSDictionary *attributes = [[NSDictionary alloc] initWithObjectsAndKeys:
		textFont,   NSFontAttributeName,
		textColor,  NSForegroundColorAttributeName,
		textShadow, NSShadowAttributeName,
		nil];

	[[textStorage mutableString] setString:text];
	[textStorage setAttributes:attributes range:NSMakeRange(0, [textStorage length])];
	
	[attributes release];

	[layoutManager glyphRangeForTextContainer:textContainer];	// force layout		
	textHeight = [layoutManager usedRectForTextContainer:textContainer].size.height;

	[self sizeToFit];
	[self setNeedsDisplay:YES];
}

- (void) setPriority:(int)priority {
	NSString *key;
	NSString *textKey;
	switch (priority) {
		case -2:
			key = GrowlSmokeVeryLowColor;
			textKey = GrowlSmokeVeryLowTextColor;
			break;
		case -1:
			key = GrowlSmokeModerateColor;
			textKey = GrowlSmokeModerateTextColor;
			break;
		case 1:
			key = GrowlSmokeHighColor;
			textKey = GrowlSmokeHighTextColor;
			break;
		case 2:
			key = GrowlSmokeEmergencyColor;
			textKey = GrowlSmokeEmergencyTextColor;
			break;
		case 0:
		default:
			key = GrowlSmokeNormalColor;
			textKey = GrowlSmokeNormalTextColor;
			break;
	}

	float backgroundAlpha = GrowlSmokeAlphaPrefDefault;
	READ_GROWL_PREF_FLOAT(GrowlSmokeAlphaPref, GrowlSmokePrefDomain, &backgroundAlpha);

	[bgColor release];

	Class NSArrayClass = [NSArray class];
	NSArray *array = nil;

	READ_GROWL_PREF_VALUE(key, GrowlSmokePrefDomain, NSArray *, &array);
	if (array && [array isKindOfClass:NSArrayClass]) {
		bgColor = [NSColor colorWithCalibratedRed:[[array objectAtIndex:0U] floatValue]
											green:[[array objectAtIndex:1U] floatValue]
											 blue:[[array objectAtIndex:2U] floatValue]
											alpha:backgroundAlpha];
	} else {
		bgColor = [NSColor colorWithCalibratedWhite:0.1f alpha:backgroundAlpha];
	}
	[bgColor retain];
	[array release];
	array = nil;

	[textColor release];
	READ_GROWL_PREF_VALUE(textKey, GrowlSmokePrefDomain, NSArray *, &array);
	if (array && [array isKindOfClass:NSArrayClass]) {
		textColor = [NSColor colorWithCalibratedRed:[[array objectAtIndex:0U] floatValue]
											  green:[[array objectAtIndex:1U] floatValue]
											   blue:[[array objectAtIndex:2U] floatValue]
											  alpha:1.0f];
	} else {
		textColor = [NSColor whiteColor];
	}
	[textColor retain];
	[array release];

	[textShadow setShadowColor:[bgColor blendedColorWithFraction:0.5f ofColor:[NSColor blackColor]]];
}

- (void)sizeToFit {
	NSRect rect = [self frame];
	rect.size.height = GrowlSmokePadding + GrowlSmokePadding + [self titleHeight] + [self descriptionHeight];
	if (title && text && [title length] && [text length]) {
		rect.size.height += GrowlSmokeTitleTextPadding;
	}
	if (rect.size.height < GrowlSmokeMinTextHeight) {
		rect.size.height = GrowlSmokeMinTextHeight;
	}
	[self setFrame:rect];
}

- (float) titleHeight {
	if (!title || ![title length]) {
		return 0.0f;
	}

	return titleHeight;
}

- (float) descriptionHeight {
	if (!text || ![text length]) {
		return 0.0f;
	}

	return textHeight;
}

- (int) descriptionRowCount {
	int rowCount = textHeight / lineHeight;
	BOOL limitPref = GrowlSmokeLimitPrefDefault;
	READ_GROWL_PREF_BOOL(GrowlSmokeLimitPref, GrowlSmokePrefDomain, &limitPref);
	if (limitPref) {
		return MIN(rowCount, GrowlSmokeMaxLines);
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

- (BOOL) acceptsFirstMouse:(NSEvent *) theEvent {
	return YES;
}

- (void) mouseDown:(NSEvent *) event {
	if (target && action && [target respondsToSelector:action]) {
		[target performSelector:action withObject:self];
	}
}

@end
