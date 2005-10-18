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
#import "NSMutableAttributedStringAdditions.h"
#import <WebKit/WebPreferences.h>

#define GrowlBrushedTextAreaWidth	(GrowlBrushedNotificationWidth - GrowlBrushedPadding - iconSize - GrowlBrushedIconTextPadding - GrowlBrushedPadding)
#define GrowlBrushedMinTextHeight	(GrowlBrushedPadding + iconSize + GrowlBrushedPadding)

@implementation GrowlBrushedWindowView

- (id) initWithFrame:(NSRect) frame {
	if ((self = [super initWithFrame:frame])) {
		textFont = [[NSFont systemFontOfSize:GrowlBrushedTextFontSize] retain];
		textLayoutManager = [[NSLayoutManager alloc] init];
		titleLayoutManager = [[NSLayoutManager alloc] init];
		lineHeight = [textLayoutManager defaultLineHeightForFont:textFont];
		textShadow = [[NSShadow alloc] init];
		[textShadow setShadowOffset:NSMakeSize(0.0f, -2.0f)];
		[textShadow setShadowBlurRadius:3.0f];
		[textShadow setShadowColor:[[[self window] backgroundColor] blendedColorWithFraction:0.5f
																					 ofColor:[NSColor blackColor]]];

		int size = GrowlBrushedSizePrefDefault;
		READ_GROWL_PREF_INT(GrowlBrushedSizePref, GrowlBrushedPrefDomain, &size);
		if (size == GrowlBrushedSizeLarge) {
			iconSize = GrowlBrushedIconSizeLarge;
		} else {
			iconSize = GrowlBrushedIconSize;
		}
	}

	return self;
}

- (void) dealloc {
	[textFont           release];
	[icon               release];
	[textColor          release];
	[textShadow         release];
	[textStorage        release];
	[textLayoutManager  release];
	[titleStorage       release];
	[titleLayoutManager release];

	[super dealloc];
}

- (BOOL)isFlipped {
	// Coordinates are based on top left corner
    return YES;
}

- (void) drawRect:(NSRect)rect {
	//Make sure that we don't draw in the main thread
	if ([super dispatchDrawingToThread:rect]) {
		NSRect b = [self bounds];
		CGRect bounds = CGRectMake(b.origin.x, b.origin.y, b.size.width, b.size.height);

		CGContextRef context = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];

		// clear the window
		CGContextClearRect(context, bounds);

		// calculate bounds based on icon-float pref on or off
		CGRect shadedBounds;
		BOOL floatIcon = GrowlBrushedFloatIconPrefDefault;
		READ_GROWL_PREF_BOOL(GrowlBrushedFloatIconPref, GrowlBrushedPrefDomain, &floatIcon);
		if (floatIcon) {
			float sizeReduction = GrowlBrushedPadding + iconSize + (GrowlBrushedIconTextPadding * 0.5f);

			shadedBounds = CGRectMake(bounds.origin.x + sizeReduction + 1.0f,
									  bounds.origin.y + 1.0f,
									  bounds.size.width - sizeReduction - 2.0f,
									  bounds.size.height - 2.0f);
		} else {
			shadedBounds = CGRectInset(bounds, 1.0f, 1.0f);
		}

		// set up path for rounded corners
		addRoundedRectToPath(context, shadedBounds, GrowlBrushedBorderRadius);
		CGContextSetLineWidth(context, 2.0f);

		// draw background
		NSWindow *window = [self window];
		NSColor *bgColor = [window backgroundColor];
		CGPathDrawingMode drawingMode;
		if (mouseOver) {
			drawingMode = kCGPathFillStroke;
			[bgColor setFill];
			[[NSColor keyboardFocusIndicatorColor] setStroke];
		} else {
			drawingMode = kCGPathFill;
			[bgColor set];
		}
		CGContextDrawPath(context, drawingMode);

		// draw the title and the text
		NSRect drawRect;
		drawRect.origin.x = GrowlBrushedPadding;
		drawRect.origin.y = GrowlBrushedPadding;
		drawRect.size.width = iconSize;
		drawRect.size.height = iconSize;

		[icon setFlipped:YES];
		[icon drawScaledInRect:drawRect
					 operation:NSCompositeSourceOver
					  fraction:1.0f];

		drawRect.origin.x += iconSize + GrowlBrushedIconTextPadding;

		if (haveTitle) {
			[titleLayoutManager drawGlyphsForGlyphRange:titleRange atPoint:drawRect.origin];
			drawRect.origin.y += titleHeight + GrowlBrushedTitleTextPadding;
		}

		if (haveText)
			[textLayoutManager drawGlyphsForGlyphRange:textRange atPoint:drawRect.origin];

		[window invalidateShadow];
	}
}

- (void) setIcon:(NSImage *)anIcon {
	[icon release];
	icon = [anIcon retain];
	[self setNeedsDisplay:YES];
}

- (void) setTitle:(NSString *)aTitle isHTML:(BOOL)isHTML {
	haveTitle = [aTitle length] != 0;

	if (!haveTitle) {
		[self setNeedsDisplay:YES];
		return;
	}

	if (!titleStorage) {
		NSSize containerSize;
		containerSize.width = GrowlBrushedTextAreaWidth;
		containerSize.height = FLT_MAX;
		titleStorage = [[NSTextStorage alloc] init];
		titleContainer = [[NSTextContainer alloc] initWithContainerSize:containerSize];
		[titleLayoutManager addTextContainer:titleContainer];	// retains textContainer
		[titleContainer release];
		[titleStorage addLayoutManager:titleLayoutManager];	// retains layoutManager
		[titleContainer setLineFragmentPadding:0.0f];
	}

	// construct attributes for the title
	NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
	NSFont *titleFont = [NSFont boldSystemFontOfSize:GrowlBrushedTitleFontSize];
	[paragraphStyle setLineBreakMode:NSLineBreakByTruncatingTail];
	NSDictionary *defaultAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
		titleFont,      NSFontAttributeName,
		textColor,      NSForegroundColorAttributeName,
		textShadow,     NSShadowAttributeName,
		paragraphStyle, NSParagraphStyleAttributeName,
		nil];
	[paragraphStyle release];

	if (isHTML) {
		WebPreferences *webPreferences = [[WebPreferences alloc] initWithIdentifier:@"GrowlBrushedTitle"];
		[webPreferences setJavaEnabled:NO];
		[webPreferences setJavaScriptEnabled:NO];
		[webPreferences setPlugInsEnabled:NO];
		[webPreferences setUserStyleSheetEnabled:NO];
		[webPreferences setStandardFontFamily:[titleFont familyName]];
		[webPreferences setDefaultFontSize:GrowlBrushedTitleFontSize];
		NSNumber *useWebKit = [[NSNumber alloc] initWithInt:1];
		NSDictionary *options = [[NSDictionary alloc] initWithObjectsAndKeys:
			useWebKit,      @"UseWebKit",
			webPreferences, NSWebPreferencesDocumentOption,
			nil];
		[useWebKit      release];
		[webPreferences release];

		NSString *boldTitle = [[NSString alloc] initWithFormat:@"<strong>%@</strong>", aTitle];
		NSMutableAttributedString *content = [[NSMutableAttributedString alloc] initWithHTML:[boldTitle dataUsingEncoding:NSUnicodeStringEncoding allowLossyConversion:NO]
																					 options:options
																		  documentAttributes:NULL];
		[boldTitle release];
		[options   release];
		[content addDefaultAttributes:defaultAttributes];
		[titleStorage setAttributedString:content];
		[content release];
	} else {
		[[titleStorage mutableString] setString:aTitle];
		[titleStorage setAttributes:defaultAttributes range:NSMakeRange(0, [titleStorage length])];
	}

	[defaultAttributes release];

	titleRange = [titleLayoutManager glyphRangeForTextContainer:titleContainer];	// force layout
	titleHeight = [titleLayoutManager usedRectForTextContainer:titleContainer].size.height;

	[self setNeedsDisplay:YES];
}

- (void) setText:(NSString *)aText isHTML:(BOOL)isHTML {
	haveText = [aText length] != 0;

	if (!haveText) {
		[self setNeedsDisplay:YES];
		return;
	}

	if (!textStorage) {
		NSSize containerSize;
		BOOL limitPref = GrowlBrushedLimitPrefDefault;
		READ_GROWL_PREF_BOOL(GrowlBrushedLimitPref, GrowlBrushedPrefDomain, &limitPref);
		containerSize.width = GrowlBrushedTextAreaWidth;
		if (limitPref)
			containerSize.height = lineHeight * GrowlBrushedMaxLines;
		else
			containerSize.height = FLT_MAX;
		textStorage = [[NSTextStorage alloc] init];
		textContainer = [[NSTextContainer alloc] initWithContainerSize:containerSize];
		[textLayoutManager addTextContainer:textContainer];	// retains textContainer
		[textContainer release];
		[textStorage addLayoutManager:textLayoutManager];	// retains layoutManager
		[textContainer setLineFragmentPadding:0.0f];
	}

	// construct attributes for the description text
	NSDictionary *defaultAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
		textFont,   NSFontAttributeName,
		textColor,  NSForegroundColorAttributeName,
		textShadow, NSShadowAttributeName,
		nil];

	if (isHTML) {
		WebPreferences *webPreferences = [[WebPreferences alloc] initWithIdentifier:@"GrowlBrushedText"];
		[webPreferences setJavaEnabled:NO];
		[webPreferences setJavaScriptEnabled:NO];
		[webPreferences setPlugInsEnabled:NO];
		[webPreferences setUserStyleSheetEnabled:NO];
		[webPreferences setStandardFontFamily:[textFont familyName]];
		[webPreferences setDefaultFontSize:GrowlBrushedTextFontSize];
		NSNumber *useWebKit = [[NSNumber alloc] initWithInt:1];
		NSDictionary *options = [[NSDictionary alloc] initWithObjectsAndKeys:
			useWebKit,      @"UseWebKit",
			webPreferences, NSWebPreferencesDocumentOption,
			nil];
		[useWebKit      release];
		[webPreferences release];

		NSMutableAttributedString *content = [[NSMutableAttributedString alloc] initWithHTML:[aText dataUsingEncoding:NSUnicodeStringEncoding allowLossyConversion:NO]
																					 options:options
																		  documentAttributes:NULL];
		[options release];
		[content addDefaultAttributes:defaultAttributes];
		[textStorage setAttributedString:content];
		[content release];
	} else {
		[[textStorage mutableString] setString:aText];
		[textStorage setAttributes:defaultAttributes range:NSMakeRange(0, [textStorage length])];
	}

	[defaultAttributes release];

	textRange = [textLayoutManager glyphRangeForTextContainer:textContainer];	// force layout
	textHeight = [textLayoutManager usedRectForTextContainer:textContainer].size.height;

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
	float height = GrowlBrushedPadding + GrowlBrushedPadding + [self titleHeight] + [self descriptionHeight];
	if (haveTitle && haveText)
		height += GrowlBrushedTitleTextPadding;
	if (height < GrowlBrushedMinTextHeight)
		height = GrowlBrushedMinTextHeight;

	// resize the window so that it contains the tracking rect
	NSWindow *window = [self window];
	NSRect windowRect = [[self window] frame];
	windowRect.origin.y -= height - windowRect.size.height;
	windowRect.size.height = height;
	[window setFrame:windowRect display:NO];

	if (trackingRectTag)
		[self removeTrackingRect:trackingRectTag];
	trackingRectTag = [self addTrackingRect:[self frame] owner:self userData:NULL assumeInside:NO];
}

- (float) titleHeight {
	return haveTitle ? titleHeight : 0.0f;
}

- (float) descriptionHeight {
	return haveText ? textHeight : 0.0f;
}

- (int) descriptionRowCount {
	int rowCount = textHeight / lineHeight;
	BOOL limitPref = GrowlBrushedLimitPrefDefault;
	READ_GROWL_PREF_BOOL(GrowlBrushedLimitPref, GrowlBrushedPrefDomain, &limitPref);
	if (limitPref)
		return MIN(rowCount, GrowlBrushedMaxLines);
	else
		return rowCount;
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

- (BOOL) shouldDelayWindowOrderingForEvent:(NSEvent *)theEvent {
#pragma unused(theEvent)
	[NSApp preventWindowOrdering];
	return YES;
}

- (BOOL) mouseOver {
	return mouseOver;
}

- (void) setCloseOnMouseExit:(BOOL)flag {
	closeOnMouseExit = flag;
}

- (BOOL) acceptsFirstMouse:(NSEvent *) theEvent {
#pragma unused(theEvent)
	return YES;
}

- (void) mouseEntered:(NSEvent *)theEvent {
#pragma unused(theEvent)
	mouseOver = YES;
	[self setNeedsDisplay:YES];
}

- (void) mouseExited:(NSEvent *)theEvent {
#pragma unused(theEvent)
	mouseOver = NO;
	[self setNeedsDisplay:YES];

	// abuse the target object
	if (closeOnMouseExit && [target respondsToSelector:@selector(startFadeOut)])
		[target performSelector:@selector(startFadeOut)];
}

- (void) mouseDown:(NSEvent *) event {
#pragma unused(event)
	mouseOver = NO;
	if (target && action && [target respondsToSelector:action])
		[target performSelector:action withObject:self];
}

@end
