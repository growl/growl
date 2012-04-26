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

#define HUGE_TITLE_X_SHIFT 192.0f
#define HUGE_TITLE_Y_SHIFT 72.0f
#define HUGE_TITLE_WIDTH_PAD 32.0f
#define HUGE_TEXT_Y_SHIFT 176.0f
#define HUGE_ICON_SHIFT 32.0f
#define HUGE_ICON_SIZE 128.0f

#define TITLE_X_SHIFT 96.0f
#define TITLE_Y_SHIFT 36.0f
#define TITLE_WIDTH_PAD 16.0f
#define TEXT_Y_SHIFT 88.0f
#define ICON_SHIFT 8.0f
#define ICON_SIZE 80.0f

- (void) drawRect:(NSRect)rect {
	NSGraphicsContext *context = [NSGraphicsContext currentContext];
	CGContextRef cgContext = [context graphicsPort];
	NSRect bounds = [self bounds];
	if (needsDisplay) {
		// rects and sizes
		int sizePref = 0;
		if([[self configurationDict] valueForKey:MUSICVIDEO_SIZE_PREF]){
			sizePref = [[[self configurationDict] valueForKey:MUSICVIDEO_SIZE_PREF] boolValue];
		}
		NSRect titleRect, textRect;
		NSRect iconRect;
		
		NSTextAlignment alignment = NSLeftTextAlignment;
		if([[self configurationDict] valueForKey:MUSICVIDEO_TEXT_ALIGN_PREF])
			alignment = [[[self configurationDict] valueForKey:MUSICVIDEO_TEXT_ALIGN_PREF] intValue];

		if (sizePref == MUSICVIDEO_SIZE_HUGE) {
			if(alignment == NSLeftTextAlignment){
				titleRect.origin.x = HUGE_TITLE_X_SHIFT;
				iconRect.origin.x = HUGE_ICON_SHIFT;
			}else{
				titleRect.origin.x = HUGE_TITLE_WIDTH_PAD;
				iconRect.origin.x = NSWidth(bounds) - (HUGE_ICON_SHIFT + HUGE_ICON_SIZE);
			}
			titleRect.origin.y = NSHeight(bounds) - HUGE_TITLE_Y_SHIFT;
			titleRect.size.width = NSWidth(bounds) - HUGE_TITLE_X_SHIFT - HUGE_TITLE_WIDTH_PAD;
			titleRect.size.height = 40.0;
			textRect.origin.y = NSHeight(bounds) - HUGE_TEXT_Y_SHIFT;
			textRect.size.height = 96.0;
			iconRect.origin.y = NSHeight(bounds) - (HUGE_ICON_SIZE + HUGE_ICON_SHIFT);
			iconRect.size.width = HUGE_ICON_SIZE;
			iconRect.size.height = HUGE_ICON_SIZE;
		} else {
			if(alignment == NSLeftTextAlignment){
				titleRect.origin.x = TITLE_X_SHIFT;
				iconRect.origin.x = ICON_SHIFT;
			}else{
				titleRect.origin.x = TITLE_WIDTH_PAD;
				iconRect.origin.x = NSWidth(bounds) - (ICON_SHIFT + ICON_SIZE);
			}
			titleRect.origin.y = NSHeight(bounds) - TITLE_Y_SHIFT;
			titleRect.size.width = NSWidth(bounds) - TITLE_X_SHIFT - TITLE_WIDTH_PAD;
			titleRect.size.height = 20.0;
			textRect.origin.y = NSHeight(bounds) - TEXT_Y_SHIFT;
			textRect.size.height = 48.0;
			iconRect.origin.y = NSHeight(bounds) - (ICON_SIZE + ICON_SHIFT);
			iconRect.size.width = ICON_SIZE;
			iconRect.size.height = ICON_SIZE;
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
		[icon drawScaledInRect:iconRect operation:NSCompositeSourceOver fraction:1.0];

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
	if([[self configurationDict] valueForKey:MUSICVIDEO_EFFECT_PREF]){
		effect = [[[self configurationDict] valueForKey:MUSICVIDEO_EFFECT_PREF] intValue];
	}
	if (effect == MUSICVIDEO_EFFECT_SLIDE) {
		if (CGLayerCreateWithContext)
			imageRect.origin.y = 0.0;
	} else if (effect == MUSICVIDEO_EFFECT_WIPE) {
		rect.size.height -= imageRect.origin.y;
		imageRect.size.height -= imageRect.origin.y;
		if (!CGLayerCreateWithContext)
			imageRect.origin.y = 0.0;
	} else if (effect == MUSICVIDEO_EFFECT_FADING) {
		if (CGLayerCreateWithContext)
			imageRect.origin.y = 0.0;		
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
		[cache drawInRect:rect fromRect:imageRect operation:NSCompositeSourceOver fraction:1.0];
	}
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

	CGFloat opacityPref = MUSICVIDEO_DEFAULT_OPACITY;
	if([[self configurationDict] valueForKey:MUSICVIDEO_OPACITY_PREF]){
		opacityPref = [[[self configurationDict] valueForKey:MUSICVIDEO_OPACITY_PREF] floatValue];
	}
	CGFloat alpha = opacityPref * 0.01;

	Class NSDataClass = [NSData class];
	NSData *data = [[self configurationDict] valueForKey:key];

	if (data && [data isKindOfClass:NSDataClass])
		backgroundColor = [NSUnarchiver unarchiveObjectWithData:data];
	else
		backgroundColor = [NSColor blackColor];
	backgroundColor = [[backgroundColor colorWithAlphaComponent:alpha] retain];
	data = nil;

	[textColor release];
	data = [[self configurationDict] valueForKey:textKey];
	if (data && [data isKindOfClass:NSDataClass])
		textColor = [NSUnarchiver unarchiveObjectWithData:data];
	else
		textColor = [NSColor whiteColor];
	[textColor retain];

	CGFloat titleFontSize;
	CGFloat textFontSize;
	int sizePref = 0;
	if([[self configurationDict] valueForKey:MUSICVIDEO_SIZE_PREF]){
		sizePref = [[[self configurationDict] valueForKey:MUSICVIDEO_SIZE_PREF] intValue];
	}

	if (sizePref == MUSICVIDEO_SIZE_HUGE) {
		titleFontSize = 32.0;
		textFontSize = 20.0;
	} else {
		titleFontSize = 16.0;
		textFontSize = 12.0;
	}

	NSShadow *textShadow = [[NSShadow alloc] init];

	NSSize shadowSize = {0.0, -2.0};
	[textShadow setShadowOffset:shadowSize];
	[textShadow setShadowBlurRadius:3.0];
	[textShadow setShadowColor:[NSColor blackColor]];

	NSTextAlignment alignment = NSLeftTextAlignment;
	if([[self configurationDict] valueForKey:MUSICVIDEO_TEXT_ALIGN_PREF])
		alignment = [[[self configurationDict] valueForKey:MUSICVIDEO_TEXT_ALIGN_PREF] intValue];
	
	NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
	[paragraphStyle setAlignment:alignment];
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
	[paragraphStyle setAlignment:alignment];
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
