//
//  GrowlMusicVideoWindowView.m
//  Display Plugins
//
//  Created by Jorge Salvador Caffarena on 09/09/04.
//  Copyright 2004 Jorge Salvador Caffarena. All rights reserved.
//

#import "GrowlMusicVideoWindowView.h"
#import "GrowlImageAdditions.h"

#define BORDER_RADIUS 20.0
#define ELIPSIS_STRING @"..."

@interface GrowlMusicVideoWindowView (PRIVATE)
- (NSSize)resizeIcon:(NSImage *)theImage toSize:(NSSize)theSize;
@end

@implementation GrowlMusicVideoWindowView

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
	NSBezierPath *musicVideoPath = [NSBezierPath bezierPathWithRect:bounds];

	[[NSColor clearColor] set];
	NSRectFill( [self frame] );
	
	int opacityPref = MUSICVIDEO_DEFAULT_OPACITY;
	READ_GROWL_PREF_INT(MUSICVIDEO_OPACITY_PREF, @"com.Growl.MusicVideo", &opacityPref);
	
	[[NSColor colorWithCalibratedRed:0. green:0. blue:0. alpha:((float)opacityPref/100.)] set];
	[musicVideoPath fill];
	
	
	// rects and sizes
	int sizePref = 0;
	READ_GROWL_PREF_INT(MUSICVIDEO_SIZE_PREF, @"com.Growl.MusicVideo", &sizePref);
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
	if (sizePref == MUSICVIDEO_SIZE_NORMAL) {
		titleRect = NSMakeRect(NSHeight(bounds), 120., NSWidth(bounds) - NSHeight(bounds) - 32., 40.);
		textRect =  NSMakeRect(NSHeight(bounds), 16., NSWidth(bounds) - NSHeight(bounds) - 32., 96.);
		titleFontSize = 32.0;
		textFontSize = 20.0;
		maxRows = 4;
		maxIconSize = NSMakeSize(128., 128.);
		iconSourcePoint = 32.;
		iconSize = [_icon adjustSizeToDrawAtSize:maxIconSize];
	} else {
		titleRect = NSMakeRect(NSHeight(bounds), 60., NSWidth(bounds) - NSHeight(bounds) - 16., 20.);
		textRect =  NSMakeRect(NSHeight(bounds), 8., NSWidth(bounds) - NSHeight(bounds) - 16., 48.);
		titleFontSize = 16.0;
		textFontSize = 12.0;
		maxRows = 3;
		maxIconSize = NSMakeSize(64., 64.);
		iconSourcePoint = 16.;
		iconSize = [_icon adjustSizeToDrawAtSize:maxIconSize];	
	}

	if ( iconSize.width > maxIconSize.width || iconSize.height > maxIconSize.height ) {
		// scale the image appropiately
		iconSize = [self resizeIcon:_icon toSize:maxIconSize];
	}
	
	if ( iconSize.width < maxIconSize.width ) {
		iconHorizontalOffset = ceil( (maxIconSize.width - iconSize.width) / 2. );
	}
	if ( iconSize.height < maxIconSize.height ) {
		iconVerticalOffset = ceil( (maxIconSize.height - iconSize.height) / 2. );
	}
	iconPoint = NSMakePoint(iconSourcePoint + iconHorizontalOffset, iconSourcePoint + iconVerticalOffset);

	
	// If we are on Panther or better, pretty shadow
	BOOL pantherOrLater = ( floor( NSAppKitVersionNumber ) > NSAppKitVersionNumber10_2 );
	id textShadow = nil; // NSShadow
	Class NSShadowClass = NSClassFromString(@"NSShadow");
	if ( pantherOrLater ) {
        textShadow = [[[NSShadowClass alloc] init] autorelease];
        
		NSSize      shadowSize = NSMakeSize(0., -2.);
        [textShadow setShadowOffset:shadowSize];
        [textShadow setShadowBlurRadius:3.0];
		[textShadow setShadowColor:[NSColor colorWithCalibratedRed:0. green:0. blue:0. alpha: 1.0]];
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
	[_title drawInRect:titleRect withAttributes:titleAttributes];
	
	NSMutableDictionary *textAttributes = [NSMutableDictionary dictionaryWithObjectsAndKeys:
				[NSColor whiteColor], NSForegroundColorAttributeName,
				parrafo, NSParagraphStyleAttributeName,
				[NSFont systemFontOfSize:textFontSize], NSFontAttributeName, nil];
	if ( pantherOrLater ) {
		[textAttributes setObject:textShadow forKey:NSShadowAttributeName];
	}
	[_text drawInRect:textRect withAttributes:textAttributes];
		
	[_icon compositeToPoint:iconPoint operation:NSCompositeSourceOver fraction:1.];
}

- (NSSize)resizeIcon:(NSImage *)theImage toSize:(NSSize)theSize {
	float newWidth, newHeight, newX, newY;
	NSSize iconSize = [theImage size];
	if ( iconSize.width > iconSize.height ) {
		newWidth = theSize.width;
		newHeight = theSize.height / iconSize.width * iconSize.height;
	} else if( iconSize.width < iconSize.height ) {
		newWidth = theSize.width / iconSize.height * iconSize.width;
		newHeight = theSize.height;
	} else {
		newWidth = theSize.width;
		newHeight = theSize.height;
	}
	
	newX = floorf((theSize.width - newWidth) / 2.);
	newY = floorf((theSize.width - newHeight) / 2.);
	
	NSRect newBounds = { { newX, newY }, { newWidth, newHeight } };
	NSImageRep *sourceImageRep = [_icon bestRepresentationForDevice:nil];
	[_icon autorelease];
	_icon = [[NSImage alloc] initWithSize:theSize];
	[_icon lockFocus];
	[[NSGraphicsContext currentContext] setImageInterpolation: NSImageInterpolationHigh];
	[sourceImageRep drawInRect:newBounds];
	[_icon unlockFocus];
	
	return NSMakeSize( newWidth, newHeight );
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
	
	if (_textHeight == 0)
	{
		NSTextStorage* textStorage = [[NSTextStorage alloc] initWithAttributedString:text];
		NSTextContainer* textContainer = [[[NSTextContainer alloc]
			initWithContainerSize:NSMakeSize(NSWidth(theRect),NSHeight(theRect)+1000.)] autorelease];
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
	if( _target && _action && [_target respondsToSelector:_action] )
		[_target performSelector:_action withObject:self];
}

@end
