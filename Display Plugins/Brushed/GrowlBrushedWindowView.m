//
//  GrowlBrushedWindowView.m
//  Display Plugins
//
//  Created by Ingmar Stein on 12/01/2004.
//  Copyright 2004-2005 The Growl Project. All rights reserved.
//

#import "GrowlBrushedWindowView.h"
#import "GrowlBrushedDefines.h"
#import "GrowlDefinesInternal.h"
#import "GrowlImageAdditions.h"
#import "GrowlBezierPathAdditions.h"

#define GrowlBrushedTextAreaWidth	(GrowlBrushedNotificationWidth - GrowlBrushedPadding - GrowlBrushedIconSize - GrowlBrushedIconTextPadding - GrowlBrushedPadding)
#define GrowlBrushedMinTextHeight	(GrowlBrushedPadding + GrowlBrushedIconSize + GrowlBrushedPadding)

@implementation GrowlBrushedWindowView

- (id) initWithFrame:(NSRect) frame {
	if ((self = [super initWithFrame:frame])) {
		titleFont = [[NSFont boldSystemFontOfSize:GrowlBrushedTitleFontSize] retain];
		textFont = [[NSFont systemFontOfSize:GrowlBrushedTextFontSize] retain];
		layoutManager = [[NSLayoutManager alloc] init];
		titleHeight = [layoutManager defaultLineHeightForFont:titleFont];
		lineHeight = [layoutManager defaultLineHeightForFont:textFont];
		textShadow = [[NSShadow alloc] init];
		[textShadow setShadowOffset:NSMakeSize(0.0f, -2.0f)];
		[textShadow setShadowBlurRadius:3.0f];
		[textShadow setShadowColor:[[[self window] backgroundColor] blendedColorWithFraction:0.5f
																					 ofColor:[NSColor blackColor]]];
	}

	return self;
}

- (void) dealloc {
	[titleFont     release];
	[textFont      release];
	[icon          release];
	[title         release];
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
	BOOL floatIcon = GrowlBrushedFloatIconPrefDefault;
	READ_GROWL_PREF_FLOAT(GrowlBrushedFloatIconPref, GrowlBrushedPrefDomain, &floatIcon);
	if (floatIcon) {
		float sizeReduction = GrowlBrushedPadding + GrowlBrushedIconSize + (GrowlBrushedIconTextPadding * 0.5f);

		shadedBounds = NSMakeRect(bounds.origin.x + sizeReduction,
								  bounds.origin.y,
								  bounds.size.width - sizeReduction,
								  bounds.size.height);
	} else {
		shadedBounds = bounds;
	}

	// set up bezier path for rounded corners
	NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:shadedBounds
														  radius:GrowlBrushedBorderRadius];

	NSGraphicsContext *graphicsContext = [NSGraphicsContext currentContext];
	[graphicsContext saveGraphicsState];

	// clip graphics context to path
	[path setClip];

	// fill clipped graphics context with our background colour
	NSWindow *window = [self window];
	NSColor *bgColor = [window backgroundColor];
	[bgColor set];
	NSRectFill( frame );

	// revert to unclipped graphics context
	[graphicsContext restoreGraphicsState];

	// draw the title and the text
	NSRect drawRect;
	drawRect.origin.x = GrowlBrushedPadding + GrowlBrushedIconSize + GrowlBrushedIconTextPadding;
	drawRect.origin.y = GrowlBrushedPadding;
	drawRect.size.width = GrowlBrushedTextAreaWidth;

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

		drawRect.origin.y += drawRect.size.height + GrowlBrushedTitleTextPadding;
	}

	if (haveText) {
		NSRange glyphRange = [layoutManager glyphRangeForTextContainer:textContainer];
		[layoutManager drawGlyphsForGlyphRange:glyphRange atPoint:drawRect.origin];
	}

	drawRect.origin.x = GrowlBrushedPadding;
	drawRect.origin.y = GrowlBrushedPadding;
	drawRect.size.width = GrowlBrushedIconSize;
	drawRect.size.height = GrowlBrushedIconSize;

	// we do this because we are always working with a copy
	[icon setFlipped:YES];
	[icon drawScaledInRect:drawRect
				 operation:NSCompositeSourceOver
				  fraction:1.0f];

	[window invalidateShadow];
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
	haveText = [aText length] != 0;

	if (!textStorage) {
		NSSize containerSize;  
		BOOL limitPref = GrowlBrushedLimitPrefDefault;
		READ_GROWL_PREF_BOOL(GrowlBrushedLimitPref, GrowlBrushedPrefDomain, &limitPref);
		containerSize.width = GrowlBrushedTextAreaWidth;
		if (limitPref) {
			containerSize.height = lineHeight * GrowlBrushedMaxLines;
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

	[[textStorage mutableString] setString:aText];
	[textStorage setAttributes:attributes range:NSMakeRange(0, [textStorage length])];

	[attributes release];

	[layoutManager glyphRangeForTextContainer:textContainer];	// force layout		
	textHeight = [layoutManager usedRectForTextContainer:textContainer].size.height;

	[self sizeToFit];
	[self setNeedsDisplay:YES];
}

- (void) setPriority:(int)priority {
	NSString *textKey;
	switch (priority) {
		case -2:
			textKey = GrowlBrushedVeryLowTextColor;
			break;
		case -1:
			textKey = GrowlBrushedModerateTextColor;
			break;
		case 1:
			textKey = GrowlBrushedHighTextColor;
			break;
		case 2:
			textKey = GrowlBrushedEmergencyTextColor;
			break;
		case 0:
		default:
			textKey = GrowlBrushedNormalTextColor;
			break;
	}
	NSData *data = nil;

	[textColor release];
	READ_GROWL_PREF_VALUE(textKey, GrowlBrushedPrefDomain, NSData *, &data);
	if (data && [data isKindOfClass:[NSData class]]) {
		textColor = [NSUnarchiver unarchiveObjectWithData:data];
	} else {
		textColor = [NSColor colorWithCalibratedWhite:0.1f alpha:1.0f];
	}
	[textColor retain];
	[data release];
}

- (void) sizeToFit {
	NSRect rect = [self frame];
	rect.size.height = GrowlBrushedPadding + GrowlBrushedPadding + [self titleHeight] + [self descriptionHeight];
	if (haveText && title && [title length]) {
		rect.size.height += GrowlBrushedTitleTextPadding;
	}
	if (rect.size.height < GrowlBrushedMinTextHeight) {
		rect.size.height = GrowlBrushedMinTextHeight;
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
	if (!haveText) {
		return 0.0f;
	}
	
	return textHeight;
}

- (int) descriptionRowCount {
	int rowCount = textHeight / lineHeight;
	BOOL limitPref = GrowlBrushedLimitPrefDefault;
	READ_GROWL_PREF_BOOL(GrowlBrushedLimitPref, GrowlBrushedPrefDomain, &limitPref);
	if (limitPref) {
		return MIN(rowCount, GrowlBrushedMaxLines);
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
