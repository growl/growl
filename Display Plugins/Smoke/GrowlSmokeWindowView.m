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


@implementation GrowlSmokeWindowView

- (id)initWithFrame:(NSRect)frame {
	if ( self = [super initWithFrame:frame] ) {
		_icon = nil;
		_title = nil;
		_text = nil;
		_textHeight = 0;
		_target = nil;
		_action = nil;
		_bgColor = nil;
	}
	return self;
}

- (void)dealloc {
	[_icon release];
	[_title release];
	[_text release];
	[_bgColor release];
	
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
	unsigned int sizeReduction = GrowlSmokePadding + GrowlSmokeIconSize + (GrowlSmokeIconTextPadding / 2);
	
	// calculate bounds based on icon-float pref on or off
	NSRect shadedBounds;
	bool floatIcon = GrowlSmokeFloatIconPrefDefault;
	READ_GROWL_PREF_FLOAT(GrowlSmokeFloatIconPref, GrowlSmokePrefDomain, &floatIcon);
	if(floatIcon) shadedBounds = NSMakeRect(bounds.origin.x + sizeReduction,
									 bounds.origin.y,
									 bounds.size.width - sizeReduction,
									 bounds.size.height);
	else shadedBounds = bounds;
	
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

	[[NSGraphicsContext currentContext] saveGraphicsState];

    // clip graphics context to path
	[path setClip];

    // fill clipped graphics context with our background colour
    [_bgColor set];
	NSRectFill( [self frame] );
	
	// revert to unclipped graphics context
	[[NSGraphicsContext currentContext] restoreGraphicsState];

	// Top of the drawing area. The eye candy takes up GrowlSmokePadding pixels on 
	// the top, so we've reserved some space for it.
	float heightOffset = [self frame].size.height - GrowlSmokePadding;

    // build an appropriate colour for the text
	NSColor *textColour = [NSColor colorWithCalibratedWhite:1.f alpha:1.f];
	
	// If we are on Panther or better, pretty shadow
	BOOL pantherOrLater = ( floor( NSAppKitVersionNumber ) > NSAppKitVersionNumber10_2 );
	id textShadow = nil; // NSShadow
	Class NSShadowClass = NSClassFromString(@"NSShadow");
	if(pantherOrLater) {
        textShadow = [[[NSShadowClass alloc] init] autorelease];
        
		NSSize shadowSize = NSMakeSize(0.f, -2.f);
        [textShadow setShadowOffset:shadowSize];
        [textShadow setShadowBlurRadius:3.0f];
		[textShadow setShadowColor:[NSColor colorWithCalibratedRed:0.f green:0.f blue:0.f alpha: 1.0f]];
	}
	
	// make the description text white
	NSMutableAttributedString *whiteText = [[[NSMutableAttributedString alloc] initWithString:_text] autorelease];
	NSRange allText;
	allText.location = 0;
	allText.length = [whiteText length];
	[whiteText removeAttribute:NSForegroundColorAttributeName range:allText];
	[whiteText addAttribute:NSForegroundColorAttributeName value:textColour range:allText];
	[whiteText addAttribute:NSFontAttributeName value:[NSFont systemFontOfSize:GrowlSmokeTextFontSize] range:allText];
	if(pantherOrLater) {
		[whiteText addAttribute:NSShadowAttributeName value:textShadow range:allText];
	}

	// construct attributes for the title
	NSMutableDictionary *titleAttributes = [NSMutableDictionary dictionaryWithObjectsAndKeys:
		[NSFont boldSystemFontOfSize:13.], NSFontAttributeName,
		textColour,                        NSForegroundColorAttributeName,
		nil];
 
	if(pantherOrLater) {
		[titleAttributes setObject:textShadow forKey:NSShadowAttributeName];
	}
	
    // draw the title and the text
	unsigned int textXPosition = GrowlSmokePadding + GrowlSmokeIconSize + GrowlSmokeIconTextPadding;
	[_title drawWithEllipsisInRect:NSMakeRect( textXPosition, heightOffset - 20., [self textAreaWidth], 15. + GrowlSmokePadding)
					withAttributes:titleAttributes];
	
	[whiteText drawInRect:NSMakeRect( textXPosition, GrowlSmokePadding, [self textAreaWidth], heightOffset - 25. )];

	NSSize iconSize = [_icon size];
	if( iconSize.width > GrowlSmokeIconSize || iconSize.height > GrowlSmokeIconSize ) {

		// scale the image appropriately
		float newWidth, newHeight, newX, newY;
		if( iconSize.width > iconSize.height ) {
			newWidth = GrowlSmokeIconSize;
			newHeight = GrowlSmokeIconSize / iconSize.width * iconSize.height;
		} else if( iconSize.width < iconSize.height ) {
			newWidth = GrowlSmokeIconSize / iconSize.height * iconSize.width;
			newHeight = GrowlSmokeIconSize;
		} else {
			newWidth = GrowlSmokeIconSize;
			newHeight = GrowlSmokeIconSize;
		}
		
		newX = floorf((GrowlSmokeIconSize - newWidth) * 0.5f);
		newY = floorf((GrowlSmokeIconSize - newHeight) * 0.5f);

		NSRect newBounds = { { newX, newY }, { newWidth, newHeight } };
		NSImageRep *sourceImageRep = [_icon bestRepresentationForDevice:nil];
		[_icon autorelease];
		_icon = [[NSImage alloc] initWithSize:NSMakeSize(GrowlSmokeIconSize, GrowlSmokeIconSize)];
		[_icon lockFocus];
		[[NSGraphicsContext currentContext] setImageInterpolation: NSImageInterpolationHigh];
		[sourceImageRep drawInRect:newBounds];
		[_icon unlockFocus];
	}

	[_icon compositeToPoint:NSMakePoint( GrowlSmokePadding, heightOffset - GrowlSmokeIconSize )
				  operation:NSCompositeSourceOver fraction:1.];

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
    switch (priority) {
        case -2:
            key = GrowlSmokeVeryLowColor;
            break;
        case -1:
            key = GrowlSmokeModerateColor;
            break;
        case 1:
            key = GrowlSmokeHighColor;
            break;
        case 2:
            key = GrowlSmokeEmergencyColor;
            break;
        case 0:
        default:
            key = GrowlSmokeNormalColor;
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
		_bgColor = [[NSColor colorWithCalibratedWhite:.1 alpha:backgroundAlpha] retain];
		if (array)
			CFRelease((CFTypeRef)array);
	}
    
}

- (void)sizeToFit {
	NSRect rect = [self frame];
	rect.size.height = (2 * GrowlSmokePadding) + 15 + [self descriptionHeight];
	[self setFrame:rect];
}

- (int)textAreaWidth {
	return GrowlSmokeNotificationWidth - GrowlSmokePadding
	       - GrowlSmokeIconSize - GrowlSmokeIconPadding - GrowlSmokeIconTextPadding;
}

- (float)descriptionHeight {
	
	if (_textHeight == 0)
	{
		NSString *content = _text ? _text : @"";
		NSTextStorage* textStorage = [[NSTextStorage alloc] initWithString:content
																attributes:[NSDictionary dictionaryWithObjectsAndKeys:
																	[NSFont systemFontOfSize:GrowlSmokeTextFontSize], NSFontAttributeName,
																	nil
																	]
			];
		NSTextContainer* textContainer = [[[NSTextContainer alloc]
			initWithContainerSize:NSMakeSize ( [self textAreaWidth], FLT_MAX )] autorelease];
		NSLayoutManager* layoutManager = [[[NSLayoutManager alloc] init] autorelease];
		
		[layoutManager addTextContainer:textContainer];
		[textStorage addLayoutManager:layoutManager];
		[textContainer setLineFragmentPadding:0.0];
		(void)[layoutManager glyphRangeForTextContainer:textContainer];
		
		_textHeight = [layoutManager usedRectForTextContainer:textContainer].size.height;
		
		// for some reason, this code is using a 13-point line height for calculations, but the font 
		// in fact renders in 14 points of space. Do some adjustments.
		_textHeight = _textHeight / GrowlSmokeTextFontSize * (GrowlSmokeTextFontSize + 1);
	}
	return MAX (_textHeight, 30);
}

- (int)descriptionRowCount {
	float height = [self descriptionHeight];
	// this will be horribly wrong, but don't worry about it for now
	float lineHeight = 12;
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
