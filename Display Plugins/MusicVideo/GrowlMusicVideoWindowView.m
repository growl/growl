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

@implementation GrowlMusicVideoWindowView

- (id) initWithFrame:(NSRect)frame {
	if ((self = [super initWithFrame:frame])) {
		float titleFontSize;
		float textFontSize;
		int sizePref = 0;
		READ_GROWL_PREF_INT(MUSICVIDEO_SIZE_PREF, MusicVideoPrefDomain, &sizePref);

		if (sizePref == MUSICVIDEO_SIZE_HUGE) {
			titleFontSize = 32.0f;
			textFontSize = 20.0f;
		} else {
			titleFontSize = 16.0f;
			textFontSize = 12.0f;
		}

		int opacityPref = MUSICVIDEO_DEFAULT_OPACITY;
		READ_GROWL_PREF_INT(MUSICVIDEO_OPACITY_PREF, MusicVideoPrefDomain, &opacityPref);
		backgroundColor = [[NSColor colorWithCalibratedRed:0.0f green:0.0f blue:0.0f alpha:(opacityPref * 0.01f)] retain];

		NSShadow *textShadow = [[NSShadow alloc] init];

		NSSize shadowSize = {0.0f, -2.0f};
		[textShadow setShadowOffset:shadowSize];
		[textShadow setShadowBlurRadius:3.0f];
		[textShadow setShadowColor:[NSColor blackColor]];

		NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
		[paragraphStyle setAlignment:NSLeftTextAlignment];
		[paragraphStyle setLineBreakMode:NSLineBreakByTruncatingTail];
		titleAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
			[NSColor whiteColor], NSForegroundColorAttributeName,
			paragraphStyle, NSParagraphStyleAttributeName,
			[NSFont boldSystemFontOfSize:titleFontSize], NSFontAttributeName,
			textShadow, NSShadowAttributeName,
			nil];
		[paragraphStyle release];

		paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
		[paragraphStyle setAlignment:NSLeftTextAlignment];
		textAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
			[NSColor whiteColor], NSForegroundColorAttributeName,
			paragraphStyle, NSParagraphStyleAttributeName,
			[NSFont messageFontOfSize:textFontSize], NSFontAttributeName,
			textShadow, NSShadowAttributeName,
			nil];
		[paragraphStyle release];
		[textShadow release];

		needsDisplay = YES;
	}

	return self;
}

- (void) dealloc {
	[titleAttributes release];
	[textAttributes  release];
	[backgroundColor release];
	[icon            release];
	[title           release];
	[text            release];

	[super dealloc];
}

- (void) drawRect:(NSRect)rect {
	NSRect bounds = [self bounds];

	[backgroundColor set];
	NSRectFill(bounds);

	// rects and sizes
	int sizePref = 0;
	READ_GROWL_PREF_INT(MUSICVIDEO_SIZE_PREF, MusicVideoPrefDomain, &sizePref);
	NSRect titleRect, textRect;
	int maxRows;
	NSPoint iconSourcePoint;
	NSRect iconRect;
	NSSize iconSize = [icon size];

	if (sizePref == MUSICVIDEO_SIZE_HUGE) {
		titleRect.origin.x = 192.0f;
		titleRect.origin.y = NSHeight(bounds) - 72.0f;
		titleRect.size.width = NSWidth(bounds) - 192.0f - 32.0f;
		titleRect.size.height = 40.0f;
		textRect.origin.y = NSHeight(bounds) - 176.0f;
		textRect.size.height = 96.0f;
		maxRows = 4;
		iconRect.size.width = 128.0f;
		iconRect.size.height = 128.0f;
		iconSourcePoint.x = 32.0f;
		iconSourcePoint.y = NSHeight(bounds) - 160.0f;
	} else {
		titleRect.origin.x = 96.0f;
		titleRect.origin.y = NSHeight(bounds) - 36.0f;
		titleRect.size.width = NSWidth(bounds) - 96.0f - 16.0f;
		titleRect.size.height = 25.0f;
		textRect.origin.y = NSHeight(bounds) - 88.0f,
		textRect.size.height = 48.0f;
		maxRows = 3;
		iconRect.size.width = 80.0f;
		iconRect.size.height = 80.0f;
		iconSourcePoint.x = 8.0f;
		iconSourcePoint.y = NSHeight(bounds) - 88.0f;
	}
	textRect.origin.x = titleRect.origin.x;
	textRect.size.width = titleRect.size.width;

	iconSize = [icon adjustSizeToDrawAtSize:iconRect.size];	

	if (iconSize.width < iconRect.size.width) {
		iconRect.origin.x = iconSourcePoint.x + ceilf( (iconRect.size.width - iconSize.width) * 0.5f );
	} else {
		iconRect.origin.x = iconSourcePoint.x;
	}
	if (iconSize.height < iconRect.size.height) {
		iconRect.origin.y = iconSourcePoint.y + ceilf( (iconRect.size.height - iconSize.height) * 0.5f );
	} else {
		iconRect.origin.y = iconSourcePoint.y;
	}

	[title drawInRect:titleRect withAttributes:titleAttributes];

	[text drawInRect:textRect withAttributes:textAttributes];

	[icon drawScaledInRect:iconRect operation:NSCompositeSourceOver fraction:1.0f];
}

- (void) setIcon:(NSImage *)anIcon {
	[icon autorelease];
	icon = [anIcon retain];
	[self setNeedsDisplay:(needsDisplay = YES)];
}

- (void) setTitle:(NSString *)aTitle {
	[title autorelease];
	title = [aTitle copy];
	[self setNeedsDisplay:(needsDisplay = YES)];
}

- (void) setText:(NSString *)aText {
	[text autorelease];
	text = [aText copy];
	[self setNeedsDisplay:(needsDisplay = YES)];
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

- (BOOL)needsDisplay {
	return needsDisplay;
}

- (void)displayIfNeeded {
	if (needsDisplay) {
		[super displayIfNeeded];
		needsDisplay = NO;
	}
}

#pragma mark -

- (void) mouseUp:(NSEvent *) event {
	if (target && action && [target respondsToSelector:action]) {
		[target performSelector:action withObject:self];
	}
}

@end
