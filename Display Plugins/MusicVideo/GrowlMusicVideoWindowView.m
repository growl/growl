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

- (id)initWithFrame:(NSRect)frame {
	if( ( self = [super initWithFrame:frame] ) ) {
		_icon = nil;
		_title = nil;
		_text = nil;
		_textHeight = 0;
		_target = nil;
		_action = nil;
	}
	return self;
}

- (void)dealloc {
	[_icon release];
	[_title release];
	[_text release];

	[super dealloc];
}

- (void)drawRect:(NSRect)rect {
	NSRect bounds = [self bounds];
	NSBezierPath *musicVideoPath = [NSBezierPath bezierPathWithRect:bounds];

	[[NSColor clearColor] set];
	NSRectFill( [self frame] );
	
	int opacityPref = MUSICVIDEO_DEFAULT_OPACITY;
	READ_GROWL_PREF_INT(MUSICVIDEO_OPACITY_PREF, MusicVideoPrefDomain, &opacityPref);
	
	[[NSColor colorWithCalibratedRed:0.f green:0.f blue:0.f alpha:(opacityPref*0.01f)] set];
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
	NSSize iconSize = [_icon size];
	
	if (sizePref == MUSICVIDEO_SIZE_HUGE) {
		titleRect = NSMakeRect(NSHeight(bounds), 120.f, NSWidth(bounds) - NSHeight(bounds) - 32.f, 40.f);
		textRect =  NSMakeRect(NSHeight(bounds), 16.f, NSWidth(bounds) - NSHeight(bounds) - 32.f, 96.f);
		titleFontSize = 32.0f;
		textFontSize = 20.0f;
		maxRows = 4;
		maxIconSize = NSMakeSize(128.f, 128.f);
		iconSourcePoint = 32.f;
		iconSize = [_icon adjustSizeToDrawAtSize:maxIconSize];
	} else {
		titleRect = NSMakeRect(NSHeight(bounds), 60.f, NSWidth(bounds) - NSHeight(bounds) - 16.f, 25.f);
		textRect =  NSMakeRect(NSHeight(bounds), 8.f, NSWidth(bounds) - NSHeight(bounds) - 16.f, 48.f);
		titleFontSize = 16.0f;
		textFontSize = 12.0f;
		maxRows = 3;
		maxIconSize = NSMakeSize(80.f, 80.f);
		iconSourcePoint = 8.f;
		iconSize = [_icon adjustSizeToDrawAtSize:maxIconSize];	
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

		NSSize      shadowSize = NSMakeSize(0.f, -2.f);
        [textShadow setShadowOffset:shadowSize];
        [textShadow setShadowBlurRadius:3.0f];
		[textShadow setShadowColor:[NSColor colorWithCalibratedRed:0.f green:0.f blue:0.f alpha:1.0f]];
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
	[_title drawWithEllipsisInRect:titleRect withAttributes:titleAttributes];

	NSMutableDictionary *textAttributes = [NSMutableDictionary dictionaryWithObjectsAndKeys:
				[NSColor whiteColor], NSForegroundColorAttributeName,
				parrafo, NSParagraphStyleAttributeName,
				[NSFont messageFontOfSize:textFontSize], NSFontAttributeName, nil];
	if ( pantherOrLater ) {
		[textAttributes setObject:textShadow forKey:NSShadowAttributeName];
	}
	[_text drawInRect:textRect withAttributes:textAttributes];

	NSRect iconRect;
	iconRect.origin = iconPoint;
	iconRect.size = maxIconSize;
	[_icon drawScaledInRect:iconRect operation:NSCompositeSourceOver fraction:1.f];
}

- (void)setIcon:(NSImage *)icon {
	[_icon autorelease];
	_icon = [icon retain];
	[self setNeedsDisplay:YES];
}

- (void)setTitle:(NSString *)title {
	[_title autorelease];
	_title = [title copy];
	[self setNeedsDisplay:YES];
}

- (void)setText:(NSString *)text {
	[_text autorelease];
	_text = [text copy];
	_textHeight = 0;
	[self setNeedsDisplay:YES];
}

- (float)descriptionHeight:(NSAttributedString *)text inRect:(NSRect)theRect {
	if (_textHeight == 0) {
		NSTextStorage* textStorage = [[NSTextStorage alloc] initWithAttributedString:text];
		NSTextContainer* textContainer = [[[NSTextContainer alloc]
			initWithContainerSize:NSMakeSize(NSWidth(theRect),NSHeight(theRect)+1000.f)] autorelease];
		NSLayoutManager* layoutManager = [[[NSLayoutManager alloc] init] autorelease];

		[layoutManager addTextContainer:textContainer];
		[textStorage addLayoutManager:layoutManager];
		(void)[layoutManager glyphRangeForTextContainer:textContainer];
	
		_textHeight = [layoutManager usedRectForTextContainer:textContainer].size.height;
		_textHeight = _textHeight / 13 * 14;
	}
	return MAX (_textHeight, 30);
}

- (int)descriptionRowCount:(NSAttributedString *)text inRect:(NSRect)theRect{
	float height = [self descriptionHeight:text inRect:theRect];
	float lineHeight = [text size].height;
	return (int) (height / lineHeight);
}

- (id) target {
	return _target;
}

- (void) setTarget:(id) object {
	_target = object;
}

#pragma mark -

- (SEL) action {
	return _action;
}

- (void) setAction:(SEL) selector {
	_action = selector;
}

#pragma mark -

- (void) mouseUp:(NSEvent *) event {
	if( _target && _action && [_target respondsToSelector:_action] ) {
		[_target performSelector:_action withObject:self];
	}
}

@end
