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

extern CGLayerRef CGLayerCreateWithContext() __attribute__((weak_import));

@implementation GrowlMusicVideoWindowView

- (id) initWithFrame:(NSRect)frame {
	if ((self = [super initWithFrame:frame])) {
		cache = [[NSImage alloc] initWithSize:frame.size];
		needsDisplay = YES;
	}

	return self;
}

- (void) dealloc {
	[titleAttributes release];
	[textAttributes  release];
	[backgroundColor release];
	[textColor       release];
	[icon            release];
	[title           release];
	[text            release];
	[cache           release];
	if (layer)
		CGLayerRelease(layer);

	[super dealloc];
}

- (void) drawRect:(NSRect)rect {
	//Make sure that we don't draw in the main thread
	//if ([super dispatchDrawingToThread:rect]) {
		NSGraphicsContext *context = [NSGraphicsContext currentContext];
		CGContextRef cgContext = [context graphicsPort];
		NSRect bounds = [self bounds];
		if (needsDisplay) {
			// rects and sizes
			int sizePref = 0;
			READ_GROWL_PREF_INT(MUSICVIDEO_SIZE_PREF, GrowlMusicVideoPrefDomain, &sizePref);
			NSRect titleRect, textRect;
			NSRect iconRect;

			if (sizePref == MUSICVIDEO_SIZE_HUGE) {
				titleRect.origin.x = 192.0f;
				titleRect.origin.y = NSHeight(bounds) - 72.0f;
				titleRect.size.width = NSWidth(bounds) - 192.0f - 32.0f;
				titleRect.size.height = 40.0f;
				textRect.origin.y = NSHeight(bounds) - 176.0f;
				textRect.size.height = 96.0f;
				iconRect.origin.x = 32.0f;
				iconRect.origin.y = NSHeight(bounds) - 160.0f;
				iconRect.size.width = 128.0f;
				iconRect.size.height = 128.0f;
			} else {
				titleRect.origin.x = 96.0f;
				titleRect.origin.y = NSHeight(bounds) - 36.0f;
				titleRect.size.width = NSWidth(bounds) - 96.0f - 16.0f;
				titleRect.size.height = 25.0f;
				textRect.origin.y = NSHeight(bounds) - 88.0f,
					textRect.size.height = 48.0f;
				iconRect.origin.x = 8.0f;
				iconRect.origin.y = NSHeight(bounds) - 88.0f;
				iconRect.size.width = 80.0f;
				iconRect.size.height = 80.0f;
			}
			textRect.origin.x = titleRect.origin.x;
			textRect.size.width = titleRect.size.width;

			//draw to cache
			if (CGLayerCreateWithContext) {
				if (!layer)
					layer = CGLayerCreateWithContext(cgContext, CGSizeMake(bounds.size.width, bounds.size.height), NULL);
				[NSGraphicsContext setCurrentContext:
					[NSGraphicsContext graphicsContextWithGraphicsPort:CGLayerGetContext(layer) flipped:NO]];
			} else {
				[cache lockFocus];
			}

			[backgroundColor set];
			bounds.origin = NSZeroPoint;
			NSRectFill(bounds);

			[title drawInRect:titleRect withAttributes:titleAttributes];

			[text drawInRect:textRect withAttributes:textAttributes];

			[icon setFlipped:NO];
			[icon drawScaledInRect:iconRect operation:NSCompositeSourceOver fraction:1.0f];

			if (CGLayerCreateWithContext)
				[NSGraphicsContext setCurrentContext:context];
			else
				[cache unlockFocus];

			needsDisplay = NO;
		}

		// draw background
		[[NSColor clearColor] set];
		NSRectFill(rect);

		// draw cache to screen
		NSRect imageRect = rect;
		int effect = MUSICVIDEO_EFFECT_SLIDE;
		READ_GROWL_PREF_INT(MUSICVIDEO_EFFECT_PREF, GrowlMusicVideoPrefDomain, &effect);
		if (effect == MUSICVIDEO_EFFECT_SLIDE) {
			if (CGLayerCreateWithContext)
				imageRect.origin.y = 0.0f;
		} else if (effect == MUSICVIDEO_EFFECT_WIPE) {
			rect.size.height -= imageRect.origin.y;
			imageRect.size.height -= imageRect.origin.y;
			if (!CGLayerCreateWithContext)
				imageRect.origin.y = 0.0f;
		} else if (effect == MUSICVIDEO_EFFECT_FADING) {
			if (CGLayerCreateWithContext)
				imageRect.origin.y = 0.0f;		
		}

		if (CGLayerCreateWithContext) {
			CGRect cgRect;
			cgRect.origin.x = imageRect.origin.x;
			cgRect.origin.y = imageRect.origin.y;
			cgRect.size.width = rect.size.width;
			if (effect == MUSICVIDEO_EFFECT_WIPE) {
				cgRect.size.height = rect.size.height;
				CGContextClipToRect(cgContext, cgRect);
			}
			cgRect.size.height = bounds.size.height;
			CGContextDrawLayerInRect(cgContext, cgRect, layer);
		} else {
			[cache drawInRect:rect fromRect:imageRect operation:NSCompositeSourceOver fraction:1.0f];
		}
	//}
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

- (void) setPriority:(int)priority {
	NSString *key;
	NSString *textKey;
	switch (priority) {
		case -2:
			key = GrowlMusicVideoVeryLowBackgroundColor;
			textKey = GrowlMusicVideoVeryLowTextColor;
			break;
		case -1:
			key = GrowlMusicVideoModerateBackgroundColor;
			textKey = GrowlMusicVideoModerateTextColor;
			break;
		case 1:
			key = GrowlMusicVideoHighBackgroundColor;
			textKey = GrowlMusicVideoHighTextColor;
			break;
		case 2:
			key = GrowlMusicVideoEmergencyBackgroundColor;
			textKey = GrowlMusicVideoEmergencyTextColor;
			break;
		case 0:
		default:
			key = GrowlMusicVideoNormalBackgroundColor;
			textKey = GrowlMusicVideoNormalTextColor;
			break;
	}

	[backgroundColor release];

	float opacityPref = MUSICVIDEO_DEFAULT_OPACITY;
	READ_GROWL_PREF_FLOAT(MUSICVIDEO_OPACITY_PREF, GrowlMusicVideoPrefDomain, &opacityPref);
	float alpha = opacityPref * 0.01f;

	Class NSDataClass = [NSData class];
	NSData *data = nil;

	READ_GROWL_PREF_VALUE(key, GrowlMusicVideoPrefDomain, NSData *, &data);
	if (data && [data isKindOfClass:NSDataClass])
		backgroundColor = [NSUnarchiver unarchiveObjectWithData:data];
	else
		backgroundColor = [NSColor blackColor];
	backgroundColor = [[backgroundColor colorWithAlphaComponent:alpha] retain];
	[data release];
	data = nil;

	[textColor release];
	READ_GROWL_PREF_VALUE(textKey, GrowlMusicVideoPrefDomain, NSData *, &data);
	if (data && [data isKindOfClass:NSDataClass])
		textColor = [NSUnarchiver unarchiveObjectWithData:data];
	else
		textColor = [NSColor whiteColor];
	[textColor retain];
	[data release];

	float titleFontSize;
	float textFontSize;
	int sizePref = 0;
	READ_GROWL_PREF_INT(MUSICVIDEO_SIZE_PREF, GrowlMusicVideoPrefDomain, &sizePref);

	if (sizePref == MUSICVIDEO_SIZE_HUGE) {
		titleFontSize = 32.0f;
		textFontSize = 20.0f;
	} else {
		titleFontSize = 16.0f;
		textFontSize = 12.0f;
	}

	NSShadow *textShadow = [[NSShadow alloc] init];

	NSSize shadowSize = {0.0f, -2.0f};
	[textShadow setShadowOffset:shadowSize];
	[textShadow setShadowBlurRadius:3.0f];
	[textShadow setShadowColor:[NSColor blackColor]];

	NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
	[paragraphStyle setAlignment:NSLeftTextAlignment];
	[paragraphStyle setLineBreakMode:NSLineBreakByTruncatingTail];
	[titleAttributes release];
	titleAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
		textColor,                                   NSForegroundColorAttributeName,
		paragraphStyle,                              NSParagraphStyleAttributeName,
		[NSFont boldSystemFontOfSize:titleFontSize], NSFontAttributeName,
		textShadow,                                  NSShadowAttributeName,
		nil];
	[paragraphStyle release];

	paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
	[paragraphStyle setAlignment:NSLeftTextAlignment];
	[textAttributes release];
	textAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
		textColor,                               NSForegroundColorAttributeName,
		paragraphStyle,                          NSParagraphStyleAttributeName,
		[NSFont messageFontOfSize:textFontSize], NSFontAttributeName,
		textShadow,                              NSShadowAttributeName,
		nil];
	[paragraphStyle release];
	[textShadow release];
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


- (BOOL) showsCloseBox {
    return NO;
}
#pragma mark -

- (BOOL) needsDisplay {
	return needsDisplay && [super needsDisplay];
}

@end
