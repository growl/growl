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
#import "NSGrowlAdditions.h"
#import "GrowlImageAdditions.h"
#import "GrowlBezierPathAdditions.h"

static float titleHeight;

@implementation GrowlSmokeWindowView

- (void) dealloc {
	[icon release];
	[title release];
	[text release];
	[bgColor release];
	[textColor release];

	[super dealloc];
}

- (void) drawRect:(NSRect)rect {
	NSRect bounds = [self bounds];
	NSRect frame  = [self frame];
	
	// clear the window
	[[NSColor clearColor] set];
	NSRectFill( frame );

	// draw bezier path for rounded corners
	float sizeReduction = GrowlSmokePadding + GrowlSmokeIconSize + (GrowlSmokeIconTextPadding * 0.5f);

	// calculate bounds based on icon-float pref on or off
	NSRect shadedBounds;
	BOOL floatIcon = GrowlSmokeFloatIconPrefDefault;
	READ_GROWL_PREF_FLOAT(GrowlSmokeFloatIconPref, GrowlSmokePrefDomain, &floatIcon);
	if (floatIcon) {
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
	NSRectFill( frame );

	// revert to unclipped graphics context
	[graphicsContext restoreGraphicsState];

	float notificationContentTop = frame.size.height - GrowlSmokePadding;

	// build an appropriate colour for the text
	//NSColor *textColour = [NSColor whiteColor];

	NSShadow *textShadow = [[[NSShadow alloc] init] autorelease];

	NSSize shadowSize = NSMakeSize(0.0f, -2.0f);
	[textShadow setShadowOffset:shadowSize];
	[textShadow setShadowBlurRadius:3.0f];
	[textShadow setShadowColor:[bgColor blendedColorWithFraction:0.5f ofColor:[NSColor blackColor]]];

	// construct attributes for the description text
	NSDictionary *descriptionAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSFont systemFontOfSize:GrowlSmokeTextFontSize], NSFontAttributeName,
		textColor, NSForegroundColorAttributeName,
		textShadow, NSShadowAttributeName,
		nil];
	// construct attributes for the title
	NSDictionary *titleAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSFont boldSystemFontOfSize:GrowlSmokeTitleFontSize], NSFontAttributeName,
		textColor, NSForegroundColorAttributeName,
		textShadow, NSShadowAttributeName,
		nil];

	// draw the title and the text
	unsigned textXPosition = GrowlSmokePadding + GrowlSmokeIconSize + GrowlSmokeIconTextPadding;
	unsigned titleYPosition = notificationContentTop - [self titleHeight];
	unsigned textYPosition = titleYPosition - ([self descriptionHeight] + GrowlSmokeTitleTextPadding);
	NSRect drawRect;

	drawRect.origin.x = textXPosition;
	drawRect.origin.y = titleYPosition;
	drawRect.size.width = [self textAreaWidth];
	drawRect.size.height = [self titleHeight];

	[title drawWithEllipsisInRect:drawRect
				   withAttributes:titleAttributes];

	drawRect.origin.y = textYPosition;
	drawRect.size.height = [self descriptionHeight];

	[text drawInRect:drawRect withAttributes:descriptionAttributes];

	drawRect.origin.x = GrowlSmokePadding;
	drawRect.origin.y = notificationContentTop - GrowlSmokeIconSize;
	drawRect.size.width = GrowlSmokeIconSize;
	drawRect.size.height = GrowlSmokeIconSize;

	// we do this because we are always working with a copy
	[icon drawScaledInRect:drawRect
				 operation:NSCompositeSourceOver
				  fraction:1.0f];

	[[self window] invalidateShadow];
}

- (void) setIcon:(NSImage *)anIcon {
	[icon autorelease];
	icon = [anIcon retain];
	[self sizeToFit];
	[self setNeedsDisplay:YES];
}

- (void) setTitle:(NSString *)aTitle {
	[title autorelease];
	title = [aTitle copy];
	[self sizeToFit];
	[self setNeedsDisplay:YES];
}

- (void) setText:(NSString *)aText {
	[text autorelease];
	text = [aText copy];
	textHeight = 0.0f;
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
	NSArray *array = nil;

	float backgroundAlpha = GrowlSmokeAlphaPrefDefault;
	READ_GROWL_PREF_FLOAT(GrowlSmokeAlphaPref, GrowlSmokePrefDomain, &backgroundAlpha);

	[bgColor release];

	Class NSArrayClass = [NSArray class];
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
}

- (void)sizeToFit {
	NSRect rect = [self frame];
	rect.size.height = GrowlSmokeIconPadding + GrowlSmokePadding + GrowlSmokeTitleTextPadding + [self titleHeight] + [self descriptionHeight];
	float minSize = (2.0f * GrowlSmokeIconPadding) + [self titleHeight] + GrowlSmokeTitleTextPadding + GrowlSmokeTextFontSize + 1.0f;
	if (rect.size.height < minSize) {
		rect.size.height = minSize;
	}
	[self setFrame:rect];
}

- (int) textAreaWidth {
	return GrowlSmokeNotificationWidth - GrowlSmokePadding
	   	- GrowlSmokeIconSize - GrowlSmokeIconPadding - GrowlSmokeIconTextPadding;
}

- (float) titleHeight {
	if ( !titleHeight ) {
		NSLayoutManager *lm = [[NSLayoutManager alloc] init];
		titleHeight = [lm defaultLineHeightForFont:[NSFont boldSystemFontOfSize:GrowlSmokeTitleFontSize]];
		[lm release];
	}

	return titleHeight;
}

- (float) descriptionHeight {
	if (!textHeight) {
		NSString *content = text ? text : @"";
		NSTextStorage *textStorage = [[NSTextStorage alloc] initWithString:content
																attributes:[NSDictionary dictionaryWithObjectsAndKeys:
																	[NSFont systemFontOfSize:GrowlSmokeTextFontSize], NSFontAttributeName,
																	nil]];

		NSSize containerSize;
		BOOL limitPref = GrowlSmokeLimitPrefDefault;
		READ_GROWL_PREF_BOOL(GrowlSmokeLimitPref, GrowlSmokePrefDomain, &limitPref);
		containerSize.width = [self textAreaWidth];
		if (limitPref) {
			// this will be horribly wrong, but don't worry about it for now
			float lineHeight = GrowlSmokeTextFontSize + 1.0f;
			containerSize.height = lineHeight * 6.0f;
		} else {
			containerSize.height = FLT_MAX;
		}
		NSTextContainer* textContainer = [[NSTextContainer alloc]
			initWithContainerSize:containerSize];
		NSLayoutManager* layoutManager = [[NSLayoutManager alloc] init];

		[layoutManager addTextContainer:textContainer];
		[textStorage addLayoutManager:layoutManager];
		[textContainer setLineFragmentPadding:0.0f];
		[layoutManager glyphRangeForTextContainer:textContainer];

		textHeight = [layoutManager usedRectForTextContainer:textContainer].size.height;

		// for some reason, this code is using a 13-point line height for calculations, but the font 
		// in fact renders in 14 points of space. Do some adjustments.
		// Presumably this is all due to leading, so need to find out how to figure out what that
		// actually is for utmost accuracy
		textHeight = textHeight / GrowlSmokeTextFontSize * (GrowlSmokeTextFontSize + 1.0f);

		[textStorage release];
		[textContainer release];
		[layoutManager release];
	}
	
	return textHeight;
}

- (int) descriptionRowCount {
	float height = [self descriptionHeight];
	// this will be horribly wrong, but don't worry about it for now
	float lineHeight = GrowlSmokeTextFontSize + 1.0f;
	return (int) (height / lineHeight);
}

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
	if ( target && action && [target respondsToSelector:action] ) {
		[target performSelector:action withObject:self];
	}
}

@end
