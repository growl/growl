//
//  GrowlNotificationView.m
//  Growl
//
//  Created by Jamie Kirkpatrick on 27/11/05.
//  Copyright 2005-2006  Jamie Kirkpatrick. All rights reserved.
//

#import "GrowlNotificationView.h"


@implementation GrowlNotificationView

@synthesize target;
@synthesize action;

- (id) init {
	if( (self = [super init ]) ) {
		closeBoxOrigin = NSMakePoint(0,0);
	}
	return self;
}

#pragma mark -

- (BOOL) shouldDelayWindowOrderingForEvent:(NSEvent *)theEvent {
	[NSApp preventWindowOrdering];
	return YES;
}

- (BOOL) mouseOver {
	return mouseOver;
}

- (void) setCloseOnMouseExit:(BOOL)flag {
	closeOnMouseExit = flag;
}

- (BOOL) acceptsFirstMouse:(NSEvent *)theEvent {
	return YES;
}

- (void) mouseEntered:(NSEvent *)theEvent {
    [self setCloseBoxVisible:YES];
	mouseOver = YES;
	[self setNeedsDisplay:YES];
	
	if ([[[self window] windowController] respondsToSelector:@selector(mouseEnteredNotificationView:)])
		[[[self window] windowController] performSelector:@selector(mouseEnteredNotificationView:)
											   withObject:self];
}

- (void) mouseExited:(NSEvent *)theEvent {
	mouseOver = NO;
    [self setCloseBoxVisible:NO];
	[self setNeedsDisplay:YES];
	
	// abuse the target object
	if (closeOnMouseExit) {
		if ([[[self window] windowController] respondsToSelector:@selector(stopDisplay)])
			[[[self window] windowController] performSelector:@selector(stopDisplay)];
	}
	
	if ([[[self window] windowController] respondsToSelector:@selector(mouseExitedNotificationView:)])
		[[[self window] windowController] performSelector:@selector(mouseExitedNotificationView:)
											   withObject:self];
}

- (void) mouseUp:(NSEvent *)event {
	mouseOver = NO;
	if (target && action && [target respondsToSelector:action])
		[target performSelector:action withObject:self];
}

static NSButton *gCloseButton;
+ (NSButton *) closeButton {
	if (!gCloseButton) {
	    gCloseButton = [[NSButton alloc] initWithFrame:NSMakeRect(0,0,30,30)];
	    [gCloseButton setBezelStyle:NSRegularSquareBezelStyle];
	    [gCloseButton setBordered:NO];
	    [gCloseButton setButtonType:NSMomentaryChangeButton];
	    [gCloseButton setImagePosition:NSImageOnly];
	    [gCloseButton setImage:[NSImage imageNamed:@"closebox.png"]];
	    [gCloseButton setAlternateImage:[NSImage imageNamed:@"closebox_pressed.png"]];
	}
	return gCloseButton;
}

- (BOOL) showsCloseBox {
	return YES;
}

- (void) clickedCloseBox:(id)sender {
	mouseOver = NO;
	if ([[[self window] windowController] respondsToSelector:@selector(clickedClose)])
		[[[self window] windowController] performSelector:@selector(clickedClose)];

	/* NSButton can mess up our display in its rect after mouseUp,
	 * so do a re-display on the next run loop.
	 */
	[self performSelector:@selector(display)
			   withObject:nil
			   afterDelay:0];
	
	if (([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask) != 0) {
		[[NSNotificationCenter defaultCenter] postNotificationName:GROWL_CLOSE_ALL_NOTIFICATIONS
															object:nil];
	}
}

- (void) setCloseBoxVisible:(BOOL)yorn {
	if ([self showsCloseBox]) {
		[GrowlNotificationView closeButton];
		[gCloseButton setTarget:self];
		[gCloseButton setAction:@selector(clickedCloseBox:)];
		[gCloseButton setFrameOrigin:closeBoxOrigin];
		if(yorn)
			[self addSubview:gCloseButton];
		else 
			[gCloseButton removeFromSuperview];
	}
}

- (void) setCloseBoxOrigin:(NSPoint)inOrigin {
	closeBoxOrigin = inOrigin;
}

- (void)drawRect:(NSRect)rect
{
	if(!initialDisplayTest) {
		initialDisplayTest = YES;
		if([self showsCloseBox] && NSPointInRect([[self window] convertScreenToBase:[NSEvent mouseLocation]], [self frame]))
			[self mouseEntered:nil];
	}
	[super drawRect:rect];
}

#pragma mark For subclasses
- (void) setPriority:(int)priority {
}
- (void) setTitle:(NSString *) aTitle {
}
- (void) setText:(NSString *)aText {
}
- (void) setIcon:(NSImage *)anIcon {
}
- (void) sizeToFit {};

@end
