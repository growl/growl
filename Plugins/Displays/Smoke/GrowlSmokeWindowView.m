//
//  GrowlSmokeWindowView.m
//  Display Plugins
//
//  Created by Matthew Walton on 11/09/2004.
//  Copyright 2004–2011 The Growl Project. All rights reserved.
//

#import "GrowlSmokeWindowView.h"
#import "GrowlSmokeDefines.h"
#import "GrowlDefinesInternal.h"
#import "GrowlImageAdditions.h"
#import "NSMutableAttributedStringAdditions.h"
#import <WebKit/WebPreferences.h>

#define GrowlSmokeTextAreaWidth (GrowlSmokeNotificationWidth - GrowlSmokePadding - iconSize - GrowlSmokeIconTextPadding - GrowlSmokePadding)
#define GrowlSmokeMinTextHeight	(GrowlSmokePadding + iconSize + GrowlSmokePadding)

@interface ISProgressIndicator : NSProgressIndicator {
}
@end
@implementation ISProgressIndicator
- (void) startAnimation:(id)sender {
}
- (void) stopAnimation:(id)sender {
}
- (void) animate:(id)sender {
}
@end

@implementation GrowlSmokeWindowView

- (id) initWithFrame:(NSRect)frame {
	if ((self = [super initWithFrame:frame])) {
		textFont = [[NSFont systemFontOfSize:GrowlSmokeTextFontSize] retain];
		textLayoutManager = [[NSLayoutManager alloc] init];
		titleLayoutManager = [[NSLayoutManager alloc] init];
		lineHeight = [textLayoutManager defaultLineHeightForFont:textFont];
		textShadow = [[NSShadow alloc] init];
		[textShadow setShadowOffset:NSMakeSize(0.0, -2.0)];
		[textShadow setShadowBlurRadius:3.0];

		int size = GrowlSmokeSizePrefDefault;
		READ_GROWL_PREF_INT(GrowlSmokeSizePref, GrowlSmokePrefDomain, &size);
		if (size == GrowlSmokeSizeLarge)
			iconSize = GrowlSmokeIconSizeLarge;
		else
			iconSize = GrowlSmokeIconSize;
	}
	[self setCloseBoxOrigin:NSMakePoint(2,3)];
	return self;
}

- (void) setProgress:(NSNumber *)value {
	if (value) {
		if (!progressIndicator) {
			progressIndicator = [[ISProgressIndicator alloc] initWithFrame:NSMakeRect(GrowlSmokePadding, GrowlSmokePadding + iconSize + GrowlSmokeIconProgressPadding, iconSize, NSProgressIndicatorPreferredSmallThickness)];
			[progressIndicator setStyle:NSProgressIndicatorBarStyle];
			[progressIndicator setControlSize:NSSmallControlSize];
			[progressIndicator setBezeled:NO];
			[progressIndicator setControlTint:NSDefaultControlTint];
			[progressIndicator setIndeterminate:NO];
			[self addSubview:progressIndicator];
			[progressIndicator release];
		}
		[progressIndicator setDoubleValue:[value doubleValue]];
		[self setNeedsDisplay:YES];
	} else if (progressIndicator) {
		[progressIndicator removeFromSuperview];
		progressIndicator = nil;
	}
}

- (void) dealloc {
	[textFont           release];
	[icon               release];
	[bgColor            release];
	[textColor          release];
	[textShadow         release];
	[textStorage        release];
	[textLayoutManager  release];
	[titleStorage       release];
	[titleLayoutManager release];

	[super dealloc];
}

- (BOOL) isFlipped {
	// Coordinates are based on top left corner
    return YES;
}

- (void) drawRect:(NSRect)rect {
	NSRect b = [self bounds];
	CGRect bounds = CGRectMake(b.origin.x, b.origin.y, b.size.width, b.size.height);

	// calculate bounds based on icon-float pref on or off
	CGRect shadedBounds;
	BOOL floatIcon = GrowlSmokeFloatIconPrefDefault;
	READ_GROWL_PREF_BOOL(GrowlSmokeFloatIconPref, GrowlSmokePrefDomain, &floatIcon);
	if (floatIcon) {
		CGFloat sizeReduction = GrowlSmokePadding + iconSize + (GrowlSmokeIconTextPadding * 0.5);

		shadedBounds = CGRectMake(bounds.origin.x + sizeReduction + 1.0,
								  bounds.origin.y + 1.0,
								  bounds.size.width - sizeReduction - 2.0,
								  bounds.size.height - 2.0);
	} else {
		shadedBounds = CGRectInset(bounds, 1.0, 1.0);
	}

	// set up bezier path for rounded corners
    NSBezierPath *bezierPath = [NSBezierPath bezierPathWithRoundedRect:shadedBounds xRadius:GrowlSmokeBorderRadius yRadius:GrowlSmokeBorderRadius];
	[bezierPath setLineWidth:2.0f];

	// draw background
	if (mouseOver) {
		[bgColor setFill];
		[textColor setStroke];
        [bezierPath fill];
        [bezierPath stroke];
	} else {
		[bgColor set];
        [bezierPath fill];
	}

	// draw the title and the text
	NSRect drawRect;
	drawRect.origin.x = GrowlSmokePadding;
	drawRect.origin.y = GrowlSmokePadding;
	drawRect.size.width = iconSize;
	drawRect.size.height = iconSize;

	[icon setFlipped:YES];
	[icon drawScaledInRect:drawRect
				 operation:NSCompositeSourceOver
				  fraction:1.0];

	drawRect.origin.x += iconSize + GrowlSmokeIconTextPadding;
    
    [NSGraphicsContext saveGraphicsState];
    //we do this because we don't want 10.7 helping us.
    CGContextSetShouldSmoothFonts([[NSGraphicsContext currentContext] graphicsPort], false);
	if (haveTitle) {
		[titleLayoutManager drawGlyphsForGlyphRange:titleRange atPoint:drawRect.origin];
		drawRect.origin.y += titleHeight + GrowlSmokeTitleTextPadding;
	}

	if (haveText)
		[textLayoutManager drawGlyphsForGlyphRange:textRange atPoint:drawRect.origin];
    
    [NSGraphicsContext restoreGraphicsState];
	[[self window] invalidateShadow];
	[super drawRect:rect];
}

- (void) setIcon:(NSImage *)anIcon {
	[icon release];
	icon = [anIcon retain];
	[self setNeedsDisplay:YES];
}

- (void) setTitle:(NSString *)aTitle {
	haveTitle = [aTitle length] != 0;

	if (!haveTitle) {
		[self setNeedsDisplay:YES];
		return;
	}

	if (!titleStorage) {
		NSSize containerSize;
		containerSize.width = GrowlSmokeTextAreaWidth;
		containerSize.height = FLT_MAX;
		titleStorage = [[NSTextStorage alloc] init];
		titleContainer = [[NSTextContainer alloc] initWithContainerSize:containerSize];
        [titleLayoutManager addTextContainer:titleContainer];	// retains textContainer
		[titleContainer release];
		[titleStorage addLayoutManager:titleLayoutManager];	// retains layoutManager
		[titleContainer setLineFragmentPadding:0.0];
	}

	// construct attributes for the title
	NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
	[paragraphStyle setLineBreakMode:NSLineBreakByTruncatingTail];
	NSFont *titleFont = [NSFont boldSystemFontOfSize:GrowlSmokeTitleFontSize];
	NSDictionary *defaultAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
		titleFont,		NSFontAttributeName,
		textColor,		NSForegroundColorAttributeName,
		textShadow,     NSShadowAttributeName,
		paragraphStyle, NSParagraphStyleAttributeName,
		nil];
	[paragraphStyle release];

	[[titleStorage mutableString] setString:aTitle];
	[titleStorage setAttributes:defaultAttributes range:NSMakeRange(0U, [aTitle length])];

	[defaultAttributes release];

	titleRange = [titleLayoutManager glyphRangeForTextContainer:titleContainer];	// force layout
	titleHeight = [titleLayoutManager usedRectForTextContainer:titleContainer].size.height;

	[self setNeedsDisplay:YES];
}

- (void) setText:(NSString *)aText {
	haveText = [aText length] != 0;

	if (!haveText) {
		[self setNeedsDisplay:YES];
		return;
	}

	if (!textStorage) {
		NSSize containerSize;
		BOOL limitPref = GrowlSmokeLimitPrefDefault;
		READ_GROWL_PREF_BOOL(GrowlSmokeLimitPref, GrowlSmokePrefDomain, &limitPref);
		containerSize.width = GrowlSmokeTextAreaWidth;
		if (limitPref)
			containerSize.height = lineHeight * GrowlSmokeMaxLines;
		else
			containerSize.height = FLT_MAX;
		textStorage = [[NSTextStorage alloc] init];
		textContainer = [[NSTextContainer alloc] initWithContainerSize:containerSize];
		[textLayoutManager addTextContainer:textContainer];	// retains textContainer
		[textContainer release];
		[textStorage addLayoutManager:textLayoutManager];	// retains layoutManager
		[textContainer setLineFragmentPadding:0.0];
	}

	// construct default attributes for the description text
	NSDictionary *defaultAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
		textFont,	NSFontAttributeName,
		textColor,  NSForegroundColorAttributeName,
		textShadow, NSShadowAttributeName,
		nil];

	[[textStorage mutableString] setString:aText];
	[textStorage setAttributes:defaultAttributes range:NSMakeRange(0U, [aText length])];

	[defaultAttributes release];

	textRange = [textLayoutManager glyphRangeForTextContainer:textContainer];	// force layout
	textHeight = [textLayoutManager usedRectForTextContainer:textContainer].size.height;

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

	CGFloat backgroundAlpha = GrowlSmokeAlphaPrefDefault;
	READ_GROWL_PREF_FLOAT(GrowlSmokeAlphaPref, GrowlSmokePrefDomain, &backgroundAlpha);
	backgroundAlpha *= 0.01;

	[bgColor release];

	Class NSDataClass = [NSData class];
	NSData *data = nil;

	READ_GROWL_PREF_VALUE(key, GrowlSmokePrefDomain, NSData *, &data);
	if(data)
		CFMakeCollectable(data);		
	if (data && [data isKindOfClass:NSDataClass]) {
			bgColor = [NSUnarchiver unarchiveObjectWithData:data];
			bgColor = [bgColor colorWithAlphaComponent:backgroundAlpha];
	} else {
		bgColor = [NSColor colorWithCalibratedWhite:0.1 alpha:backgroundAlpha];
	}
	[bgColor retain];
	[data release];
	data = nil;

	[textColor release];
	READ_GROWL_PREF_VALUE(textKey, GrowlSmokePrefDomain, NSData *, &data);
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
	
	[textShadow setShadowColor:[bgColor blendedColorWithFraction:0.5 ofColor:[NSColor blackColor]]];
}

- (void) sizeToFit {
	CGFloat height = GrowlSmokePadding + GrowlSmokePadding + [self titleHeight] + [self descriptionHeight];
	if (haveTitle && haveText)
		height += GrowlSmokeTitleTextPadding;
	if (progressIndicator)
		height += GrowlSmokeIconProgressPadding + [progressIndicator bounds].size.height;
	if (height < GrowlSmokeMinTextHeight)
		height = GrowlSmokeMinTextHeight;

	NSRect rect = [self frame];
	rect.size.height = height;
	[self setFrame:rect];

	// resize the window so that it contains the tracking rect
	NSWindow *window = [self window];
	NSRect windowRect = [window frame];
	windowRect.origin.y -= height - windowRect.size.height;
	windowRect.size.height = height;
	[window setFrame:windowRect display:YES animate:YES];

	if (trackingRectTag)
		[self removeTrackingRect:trackingRectTag];
	trackingRectTag = [self addTrackingRect:rect owner:self userData:NULL assumeInside:NO];
}

- (CGFloat) titleHeight {
	return haveTitle ? titleHeight : 0.0;
}

- (CGFloat) descriptionHeight {
	return haveText ? textHeight : 0.0;
}

- (NSInteger) descriptionRowCount {
	NSInteger rowCount = textHeight / lineHeight;
	BOOL limitPref = GrowlSmokeLimitPrefDefault;
	READ_GROWL_PREF_BOOL(GrowlSmokeLimitPref, GrowlSmokePrefDomain, &limitPref);
	if (limitPref)
		return MIN(rowCount, GrowlSmokeMaxLines);
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

@end
