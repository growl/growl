//
//  GrowlSmokeWindowView.m
//  Display Plugins
//
//  Created by Matthew Walton on 11/09/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "GrowlSmokeWindowView.h"
#import "GrowlSmokeDefines.h"
#import "GrowlDefines.h"
#import "GrowlStringAdditions.h"
#import "GrowlImageAdditions.h"

@implementation GrowlSmokeWindowView

- (id)initWithFrame:(NSRect)frame {
	if( ( self = [super initWithFrame:frame] ) ) {
		_icon = nil;
		_title = nil;
		_text = nil;
		_textHeight = 0.0f;
		_titleHeight = 0.0f;
		_target = nil;
		_action = nil;
		_bgColor = nil;
		_textColor = nil;
	}
	return self;
}

- (void)dealloc {
	[_icon release];
	[_title release];
	[_text release];
	[_bgColor release];
	[_textColor release];

	[super dealloc];
}

- (void)drawRect:(NSRect)rect {
	NSRect bounds = [self bounds];
	
	// clear the window
	[[NSColor clearColor] set];
	NSRectFill( [self frame] );

	// set up bezier path for rounded corners
	float lineWidth = 1.f;
	NSBezierPath *path = [NSBezierPath bezierPath];
	[path setLineWidth:lineWidth];

	// draw bezier path for rounded corners
	float radius = 5.f;
	unsigned int sizeReduction = GrowlSmokePadding + GrowlSmokeIconSize + (GrowlSmokeIconTextPadding * 0.5f);

	// calculate bounds based on icon-float pref on or off
	NSRect shadedBounds;
	BOOL floatIcon = GrowlSmokeFloatIconPrefDefault;
	READ_GROWL_PREF_FLOAT(GrowlSmokeFloatIconPref, GrowlSmokePrefDomain, &floatIcon);
	if(floatIcon) {
		shadedBounds = NSMakeRect(bounds.origin.x + sizeReduction,
								  bounds.origin.y,
								  bounds.size.width - sizeReduction,
								  bounds.size.height);
	} else {
		shadedBounds = bounds;
	}

	NSRect irect = NSInsetRect(shadedBounds, radius + lineWidth, radius + lineWidth);
	float minX = NSMinX( irect );
	float minY = NSMinY( irect );
	float maxX = NSMaxX( irect );
	float maxY = NSMaxY( irect );
	
	[path appendBezierPathWithArcWithCenter:NSMakePoint( minX, minY )
									 radius:radius 
								 startAngle:180.f
								   endAngle:270.f];
	
	[path appendBezierPathWithArcWithCenter:NSMakePoint( maxX, minY )
									 radius:radius 
								 startAngle:270.f
								   endAngle:360.f];

	[path appendBezierPathWithArcWithCenter:NSMakePoint( maxX, maxY )
									 radius:radius 
								 startAngle:0.f
								   endAngle:90.f];

	[path appendBezierPathWithArcWithCenter:NSMakePoint( minX, maxY )
									 radius:radius 
								 startAngle:90.f
								   endAngle:180.f];

	[path closePath];

	NSGraphicsContext *graphicsContext = [NSGraphicsContext currentContext];
	[graphicsContext saveGraphicsState];

	// clip graphics context to path
	[path setClip];

	// fill clipped graphics context with our background colour
	[_bgColor set];
	NSRectFill( [self frame] );

	// revert to unclipped graphics context
	[graphicsContext restoreGraphicsState];

	float notificationContentTop = [self frame].size.height - GrowlSmokePadding;

	// build an appropriate colour for the text
	//NSColor *textColour = [NSColor colorWithCalibratedWhite:1.f alpha:1.f];

	// If we are on Panther or better, pretty shadow
	BOOL pantherOrLater = ( floor( NSAppKitVersionNumber ) > NSAppKitVersionNumber10_2 );
	id textShadow = nil; // NSShadow
	if(pantherOrLater) {
		Class NSShadowClass = NSClassFromString(@"NSShadow");
		textShadow = [[[NSShadowClass alloc] init] autorelease];
		
		NSSize shadowSize = NSMakeSize(0.f, -2.f);
		[textShadow setShadowOffset:shadowSize];
		[textShadow setShadowBlurRadius:3.0f];
		[textShadow setShadowColor:[NSColor colorWithCalibratedRed:0.f green:0.f blue:0.f alpha:1.0f]];
	}

	// construct attributes for the description text
	NSMutableDictionary *descriptionAttributes = [NSMutableDictionary dictionaryWithObjectsAndKeys:
		[NSFont systemFontOfSize:GrowlSmokeTextFontSize], NSFontAttributeName,
		_textColor, NSForegroundColorAttributeName,
		nil];
	// construct attributes for the title
	NSMutableDictionary *titleAttributes = [NSMutableDictionary dictionaryWithObjectsAndKeys:
		[NSFont boldSystemFontOfSize:GrowlSmokeTitleFontSize], NSFontAttributeName,
		_textColor, NSForegroundColorAttributeName,
		nil];

	// add shadow to both attributes
	if(pantherOrLater) {
		[descriptionAttributes setObject:textShadow forKey:NSShadowAttributeName];
		[titleAttributes setObject:textShadow forKey:NSShadowAttributeName];
	}

	// draw the title and the text
	unsigned int textXPosition = GrowlSmokePadding + GrowlSmokeIconSize + GrowlSmokeIconTextPadding;
	unsigned int titleYPosition = notificationContentTop - [self titleHeight];
	unsigned int textYPosition = titleYPosition - ([self descriptionHeight] + GrowlSmokeTitleTextPadding);
	NSRect drawRect;

	drawRect.origin.x = textXPosition;
	drawRect.origin.y = titleYPosition;
	drawRect.size.width = [self textAreaWidth];
	drawRect.size.height = [self titleHeight];

	[_title drawWithEllipsisInRect:drawRect
					withAttributes:titleAttributes];

	drawRect.origin.y = textYPosition;
	drawRect.size.height = [self descriptionHeight];

	[_text drawInRect:drawRect withAttributes:descriptionAttributes];

	drawRect.origin.x = GrowlSmokePadding;
	drawRect.origin.y = notificationContentTop - GrowlSmokeIconSize;
	drawRect.size.width = GrowlSmokeIconSize;
	drawRect.size.height = GrowlSmokeIconSize;

	// we do this because we are always working with a copy
	[_icon drawScaledInRect:drawRect
				  operation:NSCompositeSourceOver
				   fraction:1.f];

	[[self window] invalidateShadow];
}

- (void)setIcon:(NSImage *)icon {
	[_icon autorelease];
	_icon = [icon retain];
	[self sizeToFit];
	[self setNeedsDisplay:YES];
}

- (void)setTitle:(NSString *)title {
	[_title autorelease];
	_title = [title copy];
	[self sizeToFit];
	[self setNeedsDisplay:YES];
}

- (void)setText:(NSString *)text {
	[_text autorelease];
	_text = [text copy];
	_textHeight = 0;
	[self sizeToFit];
	[self setNeedsDisplay:YES];
}

- (void)setPriority:(int)priority {
	NSString* key;
	NSString* textKey;
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
	NSArray *array;

	float backgroundAlpha = GrowlSmokeAlphaPrefDefault;
	READ_GROWL_PREF_FLOAT(GrowlSmokeAlphaPref, GrowlSmokePrefDomain, &backgroundAlpha);

	[_bgColor release];
	READ_GROWL_PREF_VALUE(key, GrowlSmokePrefDomain, CFArrayRef, (CFArrayRef*)&array);
	if (array && [array isKindOfClass:[NSArray class]]) {
		_bgColor = [[NSColor colorWithCalibratedRed:[[array objectAtIndex:0] floatValue]
											  green:[[array objectAtIndex:1] floatValue]
											   blue:[[array objectAtIndex:2] floatValue]
											  alpha:backgroundAlpha] retain];
		[array release];
	} else {
		_bgColor = [[NSColor colorWithCalibratedWhite:.1f alpha:backgroundAlpha] retain];
		if (array) {
			CFRelease((CFTypeRef)array);
		}
	}

	[_textColor release];
	READ_GROWL_PREF_VALUE(textKey, GrowlSmokePrefDomain, CFArrayRef, (CFArrayRef*)&array);
	if (array && [array isKindOfClass:[NSArray class]]) {
		_textColor = [[NSColor colorWithCalibratedRed:[[array objectAtIndex:0] floatValue]
												green:[[array objectAtIndex:1] floatValue]
												 blue:[[array objectAtIndex:2] floatValue]
												alpha:1.0f] retain];
		[array release];
	} else {
		_textColor = [[NSColor colorWithCalibratedWhite:1.0f alpha:1.0f] retain];
		if (array) {
			CFRelease((CFTypeRef)array);
		}
	}
}

- (void)sizeToFit {
	NSRect rect = [self frame];
	rect.size.height = GrowlSmokeIconPadding + GrowlSmokePadding + GrowlSmokeTitleTextPadding + [self titleHeight] + [self descriptionHeight];
	float minSize = (2.0f * GrowlSmokeIconPadding) + [self titleHeight] + GrowlSmokeTitleTextPadding + GrowlSmokeTextFontSize + 1.0f;
	if(rect.size.height < minSize) {
		rect.size.height = minSize;
	}
	[self setFrame:rect];
}

- (int)textAreaWidth {
	return GrowlSmokeNotificationWidth - GrowlSmokePadding
	   	- GrowlSmokeIconSize - GrowlSmokeIconPadding - GrowlSmokeIconTextPadding;
}

- (float)titleHeight {
	if( !_titleHeight ) {
		NSLayoutManager *lm = [[NSLayoutManager alloc] init];
		_titleHeight = [lm defaultLineHeightForFont:[NSFont boldSystemFontOfSize:GrowlSmokeTitleFontSize]];
		[lm release];
	}
	
	return _titleHeight;
}

- (float)descriptionHeight {

	if (_textHeight == 0) {
		NSString *content = _text ? _text : @"";
		NSTextStorage* textStorage = [[NSTextStorage alloc] initWithString:content
																attributes:[NSDictionary dictionaryWithObjectsAndKeys:
																	[NSFont systemFontOfSize:GrowlSmokeTextFontSize], NSFontAttributeName,
																	nil
																	]
			];

		NSSize containerSize;
		BOOL limitPref = GrowlSmokeLimitPrefDefault;
		READ_GROWL_PREF_BOOL(GrowlSmokeLimitPref, GrowlSmokePrefDomain, &limitPref);
		containerSize.width = [self textAreaWidth];
		if (limitPref) {
			// this will be horribly wrong, but don't worry about it for now
			float lineHeight = GrowlSmokeTextFontSize + 1;
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

		_textHeight = [layoutManager usedRectForTextContainer:textContainer].size.height;

		// for some reason, this code is using a 13-point line height for calculations, but the font 
		// in fact renders in 14 points of space. Do some adjustments.
		// Presumably this is all due to leading, so need to find out how to figure out what that
		// actually is for utmost accuracy
		_textHeight = _textHeight / GrowlSmokeTextFontSize * (GrowlSmokeTextFontSize + 1);

		[textContainer release];
		[layoutManager release];
	}
	
	return _textHeight;
}

- (int)descriptionRowCount {
	float height = [self descriptionHeight];
	// this will be horribly wrong, but don't worry about it for now
	float lineHeight = GrowlSmokeTextFontSize + 1;
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

- (BOOL) acceptsFirstMouse:(NSEvent *) theEvent {
	return YES;
}

 - (void) mouseDown:(NSEvent *) event {
	if( _target && _action && [_target respondsToSelector:_action] ) {
		[_target performSelector:_action withObject:self];
	}
}

@end
