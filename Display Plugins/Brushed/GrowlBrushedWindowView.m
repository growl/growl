//
//  GrowlBrushedWindowView.m
//  Display Plugins
//
//  Created by Ingmar Stein on 12/01/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "GrowlBrushedWindowView.h"
#import "GrowlBrushedDefines.h"
#import "GrowlDefines.h"
#import "GrowlStringAdditions.h"
#import "GrowlImageAdditions.h"
#import "GrowlBezierPathAdditions.h"

static float titleHeight;

@implementation GrowlBrushedWindowView

- (id) initWithFrame:(NSRect)frame {
	if ( ( self = [super initWithFrame:frame] ) ) {
		icon = nil;
		title = nil;
		text = nil;
		textHeight = 0.0f;
		target = nil;
		action = nil;
		textColor = nil;
	}
	return self;
}

- (void) dealloc {
	[icon release];
	[title release];
	[text release];
	[textColor release];

	[super dealloc];
}

- (void) drawRect:(NSRect)rect {
	NSRect bounds = [self bounds];

	// clear the window
	[[NSColor clearColor] set];
	NSRectFill( [self frame] );

	// draw bezier path for rounded corners
	unsigned sizeReduction = GrowlBrushedPadding + GrowlBrushedIconSize + (GrowlBrushedIconTextPadding * 0.5f);

	// calculate bounds based on icon-float pref on or off
	NSRect shadedBounds;
	BOOL floatIcon = GrowlBrushedFloatIconPrefDefault;
	READ_GROWL_PREF_FLOAT(GrowlBrushedFloatIconPref, GrowlBrushedPrefDomain, &floatIcon);
	if (floatIcon) {
		shadedBounds = NSMakeRect(bounds.origin.x + sizeReduction,
								  bounds.origin.y,
								  bounds.size.width - sizeReduction,
								  bounds.size.height);
	} else {
		shadedBounds = bounds;
	}

	// set up bezier path for rounded corners
	NSBezierPath *path = [NSBezierPath roundedRectPath:shadedBounds
												radius:GrowlBrushedBorderRadius
											 lineWidth:1.f];

	NSGraphicsContext *graphicsContext = [NSGraphicsContext currentContext];
	[graphicsContext saveGraphicsState];

	// clip graphics context to path
	[path setClip];

	// fill clipped graphics context with our background colour
	NSColor *bgColor = [[self window] backgroundColor];
	[bgColor set];
	NSRectFill( [self frame] );

	// revert to unclipped graphics context
	[graphicsContext restoreGraphicsState];
	float notificationContentTop = [self frame].size.height - GrowlBrushedPadding;

	// build an appropriate colour for the text
	//NSColor *textColour = [NSColor colorWithCalibratedWhite:1.f alpha:1.f];

	// If we are on Panther or better, pretty shadow
	BOOL pantherOrLater = ( floor( NSAppKitVersionNumber ) > NSAppKitVersionNumber10_2 );
	id textShadow = nil; // NSShadow
	if (pantherOrLater) {
		Class NSShadowClass = NSClassFromString(@"NSShadow");
		textShadow = [[[NSShadowClass alloc] init] autorelease];

		NSSize shadowSize = NSMakeSize(0.f, -2.f);
		[textShadow setShadowOffset:shadowSize];
		[textShadow setShadowBlurRadius:3.0f];
		[textShadow setShadowColor:[bgColor blendedColorWithFraction:0.5f ofColor:[NSColor colorWithCalibratedRed:0.f green:0.f blue:0.f alpha: 1.0f]]];
	}

	// construct attributes for the description text
	NSMutableDictionary *descriptionAttributes = [NSMutableDictionary dictionaryWithObjectsAndKeys:
		[NSFont systemFontOfSize:GrowlBrushedTextFontSize], NSFontAttributeName,
		textColor, NSForegroundColorAttributeName,
		nil];
	// construct attributes for the title
	NSMutableDictionary *titleAttributes = [NSMutableDictionary dictionaryWithObjectsAndKeys:
		[NSFont boldSystemFontOfSize:GrowlBrushedTitleFontSize], NSFontAttributeName,
		textColor, NSForegroundColorAttributeName,
		nil];

	// add shadow to both attributes
	if (pantherOrLater) {
		[descriptionAttributes setObject:textShadow forKey:NSShadowAttributeName];
		[titleAttributes setObject:textShadow forKey:NSShadowAttributeName];
	}

	// draw the title and the text
	unsigned textXPosition = GrowlBrushedPadding + GrowlBrushedIconSize + GrowlBrushedIconTextPadding;
	unsigned titleYPosition = notificationContentTop - [self titleHeight];
	unsigned textYPosition = titleYPosition - ([self descriptionHeight] + GrowlBrushedTitleTextPadding);
	NSRect drawRect;

	drawRect.origin.x = textXPosition;
	drawRect.origin.y = titleYPosition;
	drawRect.size.width = [self textAreaWidth];
	drawRect.size.height = [self titleHeight];

	[title drawWithEllipsisInRect:drawRect
				   withAttributes:titleAttributes];

	drawRect.origin.y = textYPosition;
	drawRect.size.height = [self descriptionHeight];

	[text drawInRect:drawRect withAttributes:descriptionAttributes];

	drawRect.origin.x = GrowlBrushedPadding;
	drawRect.origin.y = notificationContentTop - GrowlBrushedIconSize;
	drawRect.size.width = GrowlBrushedIconSize;
	drawRect.size.height = GrowlBrushedIconSize;

	// we do this because we are always working with a copy
	[icon drawScaledInRect:drawRect
				 operation:NSCompositeSourceOver
				  fraction:1.f];

	[[self window] invalidateShadow];
}

- (void) setIcon:(NSImage *)anIcon {
	[icon autorelease];
	icon = [anIcon retain];
	[self sizeToFit];
	[self setNeedsDisplay:YES];
}

- (void) setTitle:(NSString *)aTitle {
	[title autorelease];
	title = [aTitle copy];
	[self sizeToFit];
	[self setNeedsDisplay:YES];
}

- (void) setText:(NSString *)aText {
	[text autorelease];
	text = [aText copy];
	textHeight = 0.0f;
	[self sizeToFit];
	[self setNeedsDisplay:YES];
}

- (void) setPriority:(int)priority {
	NSString* textKey;
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
	NSArray *array;

	float backgroundAlpha = GrowlBrushedAlphaPrefDefault;
	READ_GROWL_PREF_FLOAT(GrowlBrushedAlphaPref, GrowlBrushedPrefDomain, &backgroundAlpha);

	[textColor release];
	READ_GROWL_PREF_VALUE(textKey, GrowlBrushedPrefDomain, CFArrayRef, (CFArrayRef*)&array);
	if (array && [array isKindOfClass:[NSArray class]]) {
		textColor = [[NSColor colorWithCalibratedRed:[[array objectAtIndex:0] floatValue]
											   green:[[array objectAtIndex:1] floatValue]
												blue:[[array objectAtIndex:2] floatValue]
											   alpha:1.0f] retain];
		[array release];
	} else {
		textColor = [[NSColor colorWithCalibratedWhite:1.0f alpha:1.0f] retain];
		if (array) {
			CFRelease((CFTypeRef)array);
		}
	}
}

- (void)sizeToFit {
	NSRect rect = [self frame];
	rect.size.height = GrowlBrushedIconPadding + GrowlBrushedPadding + GrowlBrushedTitleTextPadding + [self titleHeight] + [self descriptionHeight];
	float minSize = (2.0f * GrowlBrushedIconPadding) + [self titleHeight] + GrowlBrushedTitleTextPadding + GrowlBrushedTextFontSize + 1.0f;
	if (rect.size.height < minSize) {
		rect.size.height = minSize;
	}
	[self setFrame:rect];
}

- (int) textAreaWidth {
	return GrowlBrushedNotificationWidth - GrowlBrushedPadding
	   	- GrowlBrushedIconSize - GrowlBrushedIconPadding - GrowlBrushedIconTextPadding;
}

- (float) titleHeight {
	if ( !titleHeight ) {
		NSLayoutManager *lm = [[NSLayoutManager alloc] init];
		titleHeight = [lm defaultLineHeightForFont:[NSFont boldSystemFontOfSize:GrowlBrushedTitleFontSize]];
		[lm release];
	}
	
	return titleHeight;
}

- (float) descriptionHeight {

	if (!textHeight) {
		NSString *content = text ? text : @"";
		NSTextStorage* textStorage = [[NSTextStorage alloc] initWithString:content
																attributes:[NSDictionary dictionaryWithObjectsAndKeys:
																	[NSFont systemFontOfSize:GrowlBrushedTextFontSize], NSFontAttributeName,
																	nil]];

		NSSize containerSize;
		BOOL limitPref = GrowlBrushedLimitPrefDefault;
		READ_GROWL_PREF_BOOL(GrowlBrushedLimitPref, GrowlBrushedPrefDomain, &limitPref);
		containerSize.width = [self textAreaWidth];
		if (limitPref) {
			// this will be horribly wrong, but don't worry about it for now
			float lineHeight = GrowlBrushedTextFontSize + 1;
			containerSize.height = lineHeight * 6.0f;
		} else {
			containerSize.height = FLT_MAX;
		}
		NSTextContainer* textContainer = [[NSTextContainer alloc]
			initWithContainerSize:containerSize];
		NSLayoutManager* layoutManager = [[NSLayoutManager alloc] init];

		[layoutManager addTextContainer:textContainer];
		[textStorage addLayoutManager:layoutManager];
		[textContainer setLineFragmentPadding:0.0];
		[layoutManager glyphRangeForTextContainer:textContainer];

		textHeight = [layoutManager usedRectForTextContainer:textContainer].size.height;

		// for some reason, this code is using a 13-point line height for calculations, but the font 
		// in fact renders in 14 points of space. Do some adjustments.
		// Presumably this is all due to leading, so need to find out how to figure out what that
		// actually is for utmost accuracy
		textHeight = textHeight / GrowlBrushedTextFontSize * (GrowlBrushedTextFontSize + 1);

		[textContainer release];
		[layoutManager release];
	}
	
	return textHeight;
}

- (int) descriptionRowCount {
	float height = [self descriptionHeight];
	// this will be horribly wrong, but don't worry about it for now
	float lineHeight = GrowlBrushedTextFontSize + 1;
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

- (BOOL) acceptsFirstMouse:(NSEvent *) theEvent {
	return YES;
}

 - (void) mouseDown:(NSEvent *) event {
	if ( target && action && [target respondsToSelector:action] ) {
		[target performSelector:action withObject:self];
	}
}

@end
