//
//  GrowlBezelWindowView.m
//  Display Plugins
//
//  Created by Jorge Salvador Caffarena on 09/09/04.
//  Copyright 2004 Jorge Salvador Caffarena. All rights reserved.
//

#import "GrowlBezelWindowView.h"
#import "GrowlImageAdditions.h"
#import "GrowlBezierPathAdditions.h"
#import "GrowlStringAdditions.h"

#define BORDER_RADIUS 20.0f

@implementation GrowlBezelWindowView

- (id)initWithFrame:(NSRect)frame {
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

- (void)dealloc {
	[icon release];
	[title release];
	[text release];

	[super dealloc];
}

- (void)drawRect:(NSRect)rect {
	NSRect bounds = [self bounds];

	// clear the window
	[[NSColor clearColor] set];
	NSRectFill( [self frame] );

	NSBezierPath *path = [NSBezierPath roundedRectPath:bounds radius:BORDER_RADIUS lineWidth:1.0f];

	int opacityPref = 40;
	READ_GROWL_PREF_INT(BEZEL_OPACITY_PREF, BezelPrefDomain, &opacityPref);
	
	[[NSColor colorWithCalibratedRed:0.f green:0.f blue:0.f alpha:(opacityPref*0.01f)] set];
	[path fill];

	int sizePref = BEZEL_SIZE_NORMAL;
	READ_GROWL_PREF_INT(BEZEL_SIZE_PREF, BezelPrefDomain, &sizePref);

	// rects
	NSRect titleRect, textRect;
	NSPoint iconPoint;
	int maxRows;
	int iconOffset = 0;
	NSSize maxIconSize;
	NSSize iconSize = [icon size];
	if (sizePref == BEZEL_SIZE_NORMAL) {
		titleRect = NSMakeRect(12.f, 90.f, 187.f, 30.f);
		textRect =  NSMakeRect(12.f, 4.f, 187.f, 80.f);
		maxRows = 4;
		maxIconSize = NSMakeSize(72.f, 72.f);
		iconSize = [icon adjustSizeToDrawAtSize:maxIconSize];
		if ( iconSize.width < maxIconSize.width ) {
			iconOffset = ceilf( (maxIconSize.width - iconSize.width) * 0.5f );
		}
		iconPoint = NSMakePoint(70.f + iconOffset, 120.f);
	} else {
		titleRect = NSMakeRect(8.f, 52.f, 143.f, 24.f);
		textRect =  NSMakeRect(8.f, 4.f, 143.f, 49.f);
		maxRows = 2;
		maxIconSize = NSMakeSize(48.f, 48.f);
		iconSize = [icon adjustSizeToDrawAtSize:maxIconSize];
		if ( iconSize.width < maxIconSize.width ) {
			iconOffset = ceilf( (maxIconSize.width - iconSize.width) * 0.5f );
		}
		iconPoint = NSMakePoint(57.f + iconOffset, 83.f);
	}

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
	float titleFontSize = 20.0f;
    NSMutableParagraphStyle *parrafo = [[[[NSParagraphStyle defaultParagraphStyle] mutableCopy] 
			setAlignment:NSCenterTextAlignment] autorelease];
	NSMutableDictionary *titleAttributes = [NSMutableDictionary dictionaryWithObjectsAndKeys:
				[NSColor whiteColor], NSForegroundColorAttributeName,
				parrafo, NSParagraphStyleAttributeName,
				[NSFont boldSystemFontOfSize:titleFontSize], NSFontAttributeName, nil];
	if ( pantherOrLater ) {
		[titleAttributes setObject:textShadow forKey:NSShadowAttributeName];
	}
	float accumulator = 0.f;
	BOOL minFontSize = NO;
	NSSize titleSize = [title sizeWithAttributes:titleAttributes];

	while ( titleSize.width > ( NSWidth(titleRect) - ( titleSize.height * 0.5f ) ) ) {
		minFontSize = ( titleFontSize < 12.f );
		if ( minFontSize ) {
			break;
		}
		titleFontSize -= 1.f;
		accumulator += 0.5f;
		[titleAttributes setObject:[NSFont boldSystemFontOfSize:titleFontSize] forKey:NSFontAttributeName];
		titleSize = [title sizeWithAttributes:titleAttributes];
	}

	titleRect.origin.y += ceilf(accumulator);
	titleRect.size.height = titleSize.height;

	if ( minFontSize ) {
		[title drawWithEllipsisInRect:titleRect withAttributes:titleAttributes];
	} else {
		[title drawInRect:titleRect withAttributes:titleAttributes];
	}

	NSMutableDictionary *textAttributes = [NSMutableDictionary dictionaryWithObjectsAndKeys:
				[NSColor whiteColor], NSForegroundColorAttributeName,
				parrafo, NSParagraphStyleAttributeName,
				[NSFont systemFontOfSize:14.0f], NSFontAttributeName, nil];
	if ( pantherOrLater ) {
		[textAttributes setObject:textShadow forKey:NSShadowAttributeName];
	}
	NSAttributedString *textAttributed;
	NSArray *linesN = [text componentsSeparatedByString:@"\n"];
	int rowCount = 0;
	if ( [linesN count] > 1 ) {
		NSEnumerator *stringEnum = [linesN objectEnumerator];
		NSString *stringLine;
		while( (stringLine = [stringEnum nextObject] ) ) {
			textAttributed = [[NSAttributedString alloc] initWithString:stringLine attributes:textAttributes];
			rowCount += [self descriptionRowCount:textAttributed inRect:textRect];
			[textAttributed release];
			textHeight = 0.0f;
		}
	} else {
		textAttributed = [[NSAttributedString alloc] initWithString:text attributes:textAttributes];
		rowCount = [self descriptionRowCount:textAttributed inRect:textRect];
		[textAttributed release];
	}

	if ( rowCount > maxRows ) {
		[textAttributes setObject:[NSFont systemFontOfSize:12.0f] forKey:NSFontAttributeName];
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
		NSTextStorage* textStorage = [[NSTextStorage alloc] initWithAttributedString:theText];
		NSTextContainer* textContainer = [[NSTextContainer alloc]
			initWithContainerSize:NSMakeSize(NSWidth(theRect),NSHeight(theRect)+1000.f)];
		NSLayoutManager* layoutManager = [[NSLayoutManager alloc] init];

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

- (int) descriptionRowCount:(NSAttributedString *)theText inRect:(NSRect)theRect{
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
