//
//  GrowlMusicVideoWindowView.m
//  Display Plugins
//
//  Created by Jorge Salvador Caffarena on 09/09/04.
//  Copyright 2004 Jorge Salvador Caffarena. All rights reserved.
//

#import "GrowlMusicVideoWindowView.h"
#import "GrowlMusicVideoPrefs.h"
#import "GrowlImageAdditions.h"
#import "NSGrowlAdditions.h"

@implementation GrowlMusicVideoWindowView

- (void) dealloc {
	[icon release];
	[title release];
	[text release];

	[super dealloc];
}

- (void) drawRect:(NSRect)rect {
	NSRect bounds = [self bounds];
	NSBezierPath *musicVideoPath = [NSBezierPath bezierPathWithRect:bounds];

	[[NSColor clearColor] set];
	NSRectFill( [self frame] );
	
	int opacityPref = MUSICVIDEO_DEFAULT_OPACITY;
	READ_GROWL_PREF_INT(MUSICVIDEO_OPACITY_PREF, MusicVideoPrefDomain, &opacityPref);

	[[NSColor colorWithCalibratedRed:0.0f green:0.0f blue:0.0f alpha:(opacityPref * 0.01f)] set];
	[musicVideoPath fill];
	
	// rects and sizes
	int sizePref = 0;
	READ_GROWL_PREF_INT(MUSICVIDEO_SIZE_PREF, MusicVideoPrefDomain, &sizePref);
	NSRect titleRect, textRect;
	float titleFontSize;
	float textFontSize;
	NSPoint iconPoint;
	int maxRows;
	int iconSourcePoint;
	NSSize maxIconSize;
	NSSize iconSize = [icon size];

	titleRect.origin.x = NSHeight(bounds);
	textRect.origin.x =  NSHeight(bounds);

	if (sizePref == MUSICVIDEO_SIZE_HUGE) {
		titleRect.origin.y = 120.0f;
		titleRect.size.width = NSWidth(bounds) - NSHeight(bounds) - 32.0f;
		titleRect.size.height = 40.0f;
		textRect.origin.y = 16.0f;
		textRect.size.width = NSWidth(bounds) - NSHeight(bounds) - 32.0f;
		textRect.size.height = 96.0f;
		titleFontSize = 32.0f;
		textFontSize = 20.0f;
		maxRows = 4;
		maxIconSize.width = 128.0f;
		maxIconSize.height = 128.0f;
		iconSourcePoint = 32.0f;
	} else {
		titleRect.origin.y = 60.0f;
		titleRect.size.width = NSWidth(bounds) - NSHeight(bounds) - 16.0f;
		titleRect.size.height = 25.0f;
		textRect.origin.y = 8.0f,
		textRect.size.width = NSWidth(bounds) - NSHeight(bounds) - 16.0f;
		textRect.size.height = 48.0f;
		titleFontSize = 16.0f;
		textFontSize = 12.0f;
		maxRows = 3;
		maxIconSize.width = 80.0f;
		maxIconSize.height = 80.0f;
		iconSourcePoint = 8.0f;
	}

	iconSize = [icon adjustSizeToDrawAtSize:maxIconSize];	

	if ( iconSize.width < maxIconSize.width ) {
		iconPoint.x = iconSourcePoint + ceilf( (maxIconSize.width - iconSize.width) * 0.5f );
	} else {
		iconPoint.x = iconSourcePoint;
	}
	if ( iconSize.height < maxIconSize.height ) {
		iconPoint.y = iconSourcePoint + ceilf( (maxIconSize.height - iconSize.height) * 0.5f );
	} else {
		iconPoint.y = iconSourcePoint;
	}

	NSShadow *textShadow = [[[NSShadow alloc] init] autorelease];

	NSSize shadowSize = {0.0f, -2.0f};
	[textShadow setShadowOffset:shadowSize];
	[textShadow setShadowBlurRadius:3.0f];
	[textShadow setShadowColor:[NSColor blackColor]];

	// Draw the title, resize if text too big
	NSMutableParagraphStyle *parrafo = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
	[parrafo setAlignment:NSLeftTextAlignment];
	NSMutableDictionary *titleAttributes = [NSMutableDictionary dictionaryWithObjectsAndKeys:
		[NSColor whiteColor], NSForegroundColorAttributeName,
		parrafo, NSParagraphStyleAttributeName,
		[NSFont boldSystemFontOfSize:titleFontSize], NSFontAttributeName,
		textShadow, NSShadowAttributeName, nil];
	[title drawWithEllipsisInRect:titleRect withAttributes:titleAttributes];

	NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSColor whiteColor], NSForegroundColorAttributeName,
		parrafo, NSParagraphStyleAttributeName,
		[NSFont messageFontOfSize:textFontSize], NSFontAttributeName,
		textShadow, NSShadowAttributeName, nil];
	[text drawInRect:textRect withAttributes:textAttributes];

	NSRect iconRect;
	iconRect.origin = iconPoint;
	iconRect.size = maxIconSize;
	[icon drawScaledInRect:iconRect operation:NSCompositeSourceOver fraction:1.0f];
}

- (void) setIcon:(NSImage *)anIcon {
	[icon autorelease];
	icon = [anIcon retain];
	[self setNeedsDisplay:YES];
}

- (void) setTitle:(NSString *)aTitle {
	[title autorelease];
	title = [aTitle copy];
	[self setNeedsDisplay:YES];
}

- (void) setText:(NSString *)aText {
	[text autorelease];
	text = [aText copy];
	textHeight = 0.0f;
	[self setNeedsDisplay:YES];
}

- (float) descriptionHeight:(NSAttributedString *)theText inRect:(NSRect)theRect {
	if (!textHeight) {
		NSTextStorage *textStorage = [[NSTextStorage alloc] initWithAttributedString:theText];
		theRect.size.height += 1000.0f;
		NSTextContainer *textContainer = [[NSTextContainer alloc] initWithContainerSize:theRect.size];
		NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];

		[layoutManager addTextContainer:textContainer];
		[textStorage addLayoutManager:layoutManager];
		[layoutManager glyphRangeForTextContainer:textContainer];

		textHeight = [layoutManager usedRectForTextContainer:textContainer].size.height;
		[layoutManager release];
		[textContainer release];
		[textStorage release];
		textHeight = textHeight / 13.0f * 14.0f;
	}
	return MAX (textHeight, 30.0f);
}

- (int)descriptionRowCount:(NSAttributedString *)theText inRect:(NSRect)theRect{
	float height = [self descriptionHeight:theText inRect:theRect];
	float lineHeight = [theText size].height;
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

- (void) mouseUp:(NSEvent *) event {
	if ( target && action && [target respondsToSelector:action] ) {
		[target performSelector:action withObject:self];
	}
}

@end
