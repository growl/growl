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


@implementation GrowlSmokeWindowView

- (id)initWithFrame:(NSRect)frame {
	if ( self = [super initWithFrame:frame] ) {
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
	
	_icon = nil;
	_title = nil;
	_text = nil;
	_target = nil;
	
	[super dealloc];
}

- (void)drawRect:(NSRect)rect {
	NSRect bounds = [self bounds];
	
	// clear the window
	[[NSColor clearColor] set];
	NSRectFill( [self frame] );

    // set up bezier path for rounded corners
	float lineWidth = 1.;
	NSBezierPath *path = [NSBezierPath bezierPath];
	[path setLineWidth:lineWidth];

    // draw bezier path for rounded corners
	float radius = 9.;
	NSRect irect = NSInsetRect( bounds, radius + lineWidth, radius + lineWidth );
	[path appendBezierPathWithArcWithCenter:NSMakePoint( NSMinX( irect ), 
														 NSMinY( irect ) ) 
									 radius:radius 
								 startAngle:180. 
								   endAngle:270.];
	
	[path appendBezierPathWithArcWithCenter:NSMakePoint( NSMaxX( irect ), 
														 NSMinY( irect ) ) 
									 radius:radius 
								 startAngle:270. 
								   endAngle:360.];
	
	[path appendBezierPathWithArcWithCenter:NSMakePoint( NSMaxX( irect ), 
														 NSMaxY( irect ) ) 
									 radius:radius 
								 startAngle:0. 
								   endAngle:90.];
	
	[path appendBezierPathWithArcWithCenter:NSMakePoint( NSMinX( irect ), 
														 NSMaxY( irect ) ) 
									 radius:radius 
								 startAngle:90. 
								   endAngle:180.];
	
	[path closePath];

	[[NSGraphicsContext currentContext] saveGraphicsState];

    // clip graphics context to path
	[path setClip];

    // fill clipped graphics context with our background colour
	float backgroundAlpha = GrowlSmokeAlphaPrefDefault;
	READ_GROWL_PREF_FLOAT(GrowlSmokeAlphaPref, GrowlSmokePrefDomain, &backgroundAlpha);
	[[NSColor colorWithCalibratedWhite:.1 alpha:backgroundAlpha] set];
	NSRectFill( [self frame] );
	
	// revert to unclipped graphics context
	[[NSGraphicsContext currentContext] restoreGraphicsState];

	// Top of the drawing area. The eye candy takes up 10 pixels on 
	// the top, so we've reserved some space for it.
	float heightOffset = [self frame].size.height - GrowlSmokePadding;

    // build an appropriate colour for the text
	NSColor *textColour = [NSColor colorWithCalibratedWhite:1. alpha:1.];
	
	// If we are on Panther or better, pretty shadow
	BOOL pantherOrLater = ( floor( NSAppKitVersionNumber ) > NSAppKitVersionNumber10_2 );
	id textShadow = nil; // NSShadow
	Class NSShadowClass = NSClassFromString(@"NSShadow");
	if(pantherOrLater) {
        textShadow = [[[NSShadowClass alloc] init] autorelease];
        
		NSSize shadowSize = NSMakeSize(0., -2.);
        [textShadow setShadowOffset:shadowSize];
        [textShadow setShadowBlurRadius:3.0];
		[textShadow setShadowColor:[NSColor colorWithCalibratedRed:0. green:0. blue:0. alpha: 1.0]];
	}
	
	// make the description text white
	NSMutableAttributedString *whiteText = [[[NSMutableAttributedString alloc] initWithString:_text] autorelease];
	NSRange allText;
	allText.location = 0;
	allText.length = [whiteText length];
	[whiteText removeAttribute:NSForegroundColorAttributeName range:allText];
	[whiteText addAttribute:NSForegroundColorAttributeName value:textColour range:allText];
	if(pantherOrLater) [whiteText addAttribute:NSShadowAttributeName value:textShadow range:allText];
	

	
	// construct attributes for the title
	NSMutableDictionary *titleAttributes = [NSMutableDictionary dictionaryWithObjectsAndKeys:
		[NSFont boldSystemFontOfSize:13.], NSFontAttributeName,
		textColour,                        NSForegroundColorAttributeName,
		nil];
 
	if(pantherOrLater) {
		NSMutableParagraphStyle *ellipsisingStyle = [[[[NSParagraphStyle defaultParagraphStyle] mutableCopy] 
			setLineBreakMode:NSLineBreakByTruncatingTail] autorelease];
		[titleAttributes setObject:ellipsisingStyle forKey:NSParagraphStyleAttributeName];
		[titleAttributes setObject:textShadow forKey:NSShadowAttributeName];
	}
	
    // draw the title and the text
	//[_title drawAtPoint:NSMakePoint( 55., heightOffset - 15. ) withAttributes:titleAttributes];
	NSMutableAttributedString *attTitle = [[[NSMutableAttributedString alloc] initWithString:_title attributes:titleAttributes] autorelease];
	[attTitle drawInRect:NSMakeRect( 55., heightOffset - 20., [self textAreaWidth], 15. + GrowlSmokePadding )];
	
	[whiteText drawInRect:NSMakeRect( 55., GrowlSmokePadding, [self textAreaWidth], heightOffset - 25. )];

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
		
		newX = floorf((GrowlSmokeIconSize - newWidth) / 2.f);
		newY = floorf((GrowlSmokeIconSize - newHeight) / 2.f);
		
		NSRect newBounds = { { newX, newY }, { newWidth, newHeight } };
		NSImageRep *sourceImageRep = [_icon bestRepresentationForDevice:nil];
		[_icon autorelease];
		_icon = [[NSImage alloc] initWithSize:NSMakeSize(GrowlSmokeIconSize, GrowlSmokeIconSize)];
		[_icon lockFocus];
		[[NSGraphicsContext currentContext] setImageInterpolation: NSImageInterpolationHigh];
		[sourceImageRep drawInRect:newBounds];
		[_icon unlockFocus];
	}

	[_icon compositeToPoint:NSMakePoint( 15., heightOffset - 35. ) operation:NSCompositeSourceOver fraction:1.];

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

- (void)sizeToFit {
	NSRect rect = [self frame];
	rect.size.height = (2 * GrowlSmokePadding) + 15 + [self descriptionHeight];
	[self setFrame:rect];
}

- (int)textAreaWidth {
	return GrowlSmokeNotificationWidth - (GrowlSmokePadding * 2)
	       - GrowlSmokeIconSize - GrowlSmokeIconPadding;
}

- (float)descriptionHeight {
	
	if (_textHeight == 0)
	{
		NSTextStorage* textStorage = [[NSTextStorage alloc] initWithString:_text];
		NSTextContainer* textContainer = [[[NSTextContainer alloc]
			initWithContainerSize:NSMakeSize ( [self textAreaWidth], FLT_MAX )] autorelease];
		NSLayoutManager* layoutManager = [[[NSLayoutManager alloc] init] autorelease];
		
		[layoutManager addTextContainer:textContainer];
		[textStorage addLayoutManager:layoutManager];
		(void)[layoutManager glyphRangeForTextContainer:textContainer];
		
		_textHeight = [layoutManager usedRectForTextContainer:textContainer].size.height;
		
		// for some reason, this code is using a 13-point line height for calculations, but the font 
		// in fact renders in 14 points of space. Do some adjustments.
		_textHeight = _textHeight / 13 * 14;
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
	if( _target && _action && [_target respondsToSelector:_action] )
		[_target performSelector:_action withObject:self];
}

@end
