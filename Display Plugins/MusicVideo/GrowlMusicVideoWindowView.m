//
//  GrowlMusicVideoWindowView.m
//  Display Plugins
//
//  Created by Jorge Salvador Caffarena on 09/09/04.
//  Copyright 2004 Jorge Salvador Caffarena. All rights reserved.
//

#import "GrowlMusicVideoWindowView.h"
#import "GrowlImageAdditions.h"
#import "GrowlStringAdditions.h"

@implementation GrowlMusicVideoWindowView

- (id) initWithFrame:(NSRect)frame {
	if ( ( self = [super initWithFrame:frame] ) ) {
		icon = nil;
		title = nil;
		text = nil;
		textHeight = 0.0f;
		target = nil;
		action = nil;
	}
	return self;
}

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
	int iconHorizontalOffset = 0;
	int iconVerticalOffset = 0;
	int iconSourcePoint;
	NSSize maxIconSize;
	NSSize iconSize = [icon size];

	if (sizePref == MUSICVIDEO_SIZE_HUGE) {
		titleRect = NSMakeRect(NSHeight(bounds), 120.0f, NSWidth(bounds) - NSHeight(bounds) - 32.0f, 40.0f);
		textRect =  NSMakeRect(NSHeight(bounds),  16.0f, NSWidth(bounds) - NSHeight(bounds) - 32.0f, 96.0f);
		titleFontSize = 32.0f;
		textFontSize = 20.0f;
		maxRows = 4;
		maxIconSize = NSMakeSize(128.0f, 128.0f);
		iconSourcePoint = 32.0f;
		iconSize = [icon adjustSizeToDrawAtSize:maxIconSize];
	} else {
		titleRect = NSMakeRect(NSHeight(bounds), 60.0f, NSWidth(bounds) - NSHeight(bounds) - 16.0f, 25.0f);
		textRect =  NSMakeRect(NSHeight(bounds),  8.0f, NSWidth(bounds) - NSHeight(bounds) - 16.0f, 48.0f);
		titleFontSize = 16.0f;
		textFontSize = 12.0f;
		maxRows = 3;
		maxIconSize = NSMakeSize(80.0f, 80.0f);
		iconSourcePoint = 8.0f;
		iconSize = [icon adjustSizeToDrawAtSize:maxIconSize];	
	}

	if ( iconSize.width < maxIconSize.width ) {
		iconHorizontalOffset = ceilf( (maxIconSize.width - iconSize.width) * 0.5f );
	}
	if ( iconSize.height < maxIconSize.height ) {
		iconVerticalOffset = ceilf( (maxIconSize.height - iconSize.height) * 0.5f );
	}
	iconPoint = NSMakePoint(iconSourcePoint + iconHorizontalOffset, iconSourcePoint + iconVerticalOffset);
	
	// If we are on Panther or better, pretty shadow
	BOOL pantherOrLater = ( floor( NSAppKitVersionNumber ) > NSAppKitVersionNumber10_2 );
	id textShadow = nil; // NSShadow
	if ( pantherOrLater ) {
		Class NSShadowClass = NSClassFromString(@"NSShadow");
        textShadow = [[[NSShadowClass alloc] init] autorelease];

		NSSize      shadowSize = NSMakeSize(0.0f, -2.0f);
        [textShadow setShadowOffset:shadowSize];
        [textShadow setShadowBlurRadius:3.0f];
		[textShadow setShadowColor:[NSColor blackColor]];
	}
	
	// Draw the title, resize if text too big
    NSMutableParagraphStyle *parrafo = [[[[NSParagraphStyle defaultParagraphStyle] mutableCopy] 
			setAlignment:NSLeftTextAlignment] autorelease];
	NSMutableDictionary *titleAttributes = [NSMutableDictionary dictionaryWithObjectsAndKeys:
				[NSColor whiteColor], NSForegroundColorAttributeName,
				parrafo, NSParagraphStyleAttributeName,
				[NSFont boldSystemFontOfSize:titleFontSize], NSFontAttributeName, nil];
	if ( pantherOrLater ) {
		[titleAttributes setObject:textShadow forKey:NSShadowAttributeName];
	}
	[title drawWithEllipsisInRect:titleRect withAttributes:titleAttributes];

	NSMutableDictionary *textAttributes = [NSMutableDictionary dictionaryWithObjectsAndKeys:
				[NSColor whiteColor], NSForegroundColorAttributeName,
				parrafo, NSParagraphStyleAttributeName,
				[NSFont messageFontOfSize:textFontSize], NSFontAttributeName, nil];
	if ( pantherOrLater ) {
		[textAttributes setObject:textShadow forKey:NSShadowAttributeName];
	}
	[text drawInRect:textRect withAttributes:textAttributes];

	NSRect iconRect;
	iconRect.origin = iconPoint;
	iconRect.size = maxIconSize;
	[icon drawScaledInRect:iconRect operation:NSCompositeSourceOver fraction:1.f];
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
		NSTextContainer *textContainer = [[[NSTextContainer alloc]
			initWithContainerSize:NSMakeSize(NSWidth(theRect),NSHeight(theRect)+1000.f)] autorelease];
		NSLayoutManager *layoutManager = [[[NSLayoutManager alloc] init] autorelease];

		[layoutManager addTextContainer:textContainer];
		[textStorage addLayoutManager:layoutManager];
		[layoutManager glyphRangeForTextContainer:textContainer];

		textHeight = [layoutManager usedRectForTextContainer:textContainer].size.height;
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
