//
//  GrowlNotificationView.m
//  Growl
//
//  Created by Jamie Kirkpatrick on 27/11/05.
//  Copyright 2005-2006  Jamie Kirkpatrick. All rights reserved.
//

#import <GrowlPlugins/GrowlNotificationView.h>
#import "GrowlDefinesInternal.h"

@implementation GrowlNotificationView

@synthesize target;
@synthesize action;

- (id) init {
	if( (self = [super init ]) ) {
		closeBoxOrigin = NSMakePoint(0,0);
	}
	return self;
}

- (id) initWithFrame:(NSRect)frameRect {
	if((self = [super initWithFrame:frameRect])){
		NSDictionary *bundleDict = [[NSBundle bundleForClass:[self class]] infoDictionary];
		CGFloat xOrig = 0;
		CGFloat yOrig = 0;
		if([bundleDict objectForKey:@"GrowlCloseButtonXOrigin"])
			xOrig = [[bundleDict objectForKey:@"GrowlCloseButtonXOrigin"] floatValue];
		if([bundleDict objectForKey:@"GrowlCloseButtonYOrigin"])
			yOrig = [[bundleDict objectForKey:@"GrowlCloseButtonYOrigin"] floatValue];
		
		closeBoxOrigin = NSMakePoint(xOrig,yOrig);
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
	if([event clickCount] == 1) {
        mouseOver = NO;

        if (target && action && [target respondsToSelector:action])
            [target performSelector:action withObject:self];
    }
}

- (void)rightMouseUp:(NSEvent *)theEvent {
    [self clickedCloseBox:self];
}

static NSMutableDictionary *buttonDict = nil;
static NSButton *gCloseButton = nil;
+ (void)initialize {
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		buttonDict = [[NSMutableDictionary alloc] init];
		gCloseButton = [[NSButton alloc] initWithFrame:NSMakeRect(0,0,30,30)];
		[gCloseButton setBezelStyle:NSRegularSquareBezelStyle];
		[gCloseButton setBordered:NO];
		[gCloseButton setButtonType:NSMomentaryChangeButton];
		[gCloseButton setImagePosition:NSImageOnly];
		[gCloseButton setImage:[NSImage imageNamed:@"closebox"]];
		[gCloseButton setAlternateImage:[NSImage imageNamed:@"closebox_pressed"]];
	});
}

+ (NSButton *) closeButton {
	return gCloseButton;
}

+ (NSButton *) closeButtonForKey:(NSString*)key {
	NSButton *result = nil;
	if(key && buttonDict){
		result = [buttonDict valueForKey:key];
	}
	if(!result){
		result = gCloseButton;
	}
	return result;
}

+ (void)makeButtonWithImage:(NSImage*)image pressedImage:(NSImage*)pressed forKey:(NSString*)key {
	if(key && (image || pressed)){
		NSButton *button = [[NSButton alloc] initWithFrame:CGRectMake(0.0, 0.0, 30.0, 30.0)];
		[button setBezelStyle:NSRegularSquareBezelStyle];
		[button setBordered:NO];
		[button setButtonType:NSMomentaryChangeButton];
		[button setImagePosition:NSImageOnly];
		[button setImage:image ? image : [NSImage imageNamed:@"closebox"]];
		[button setAlternateImage:pressed ? pressed : [NSImage imageNamed:@"closebox_pressed"]];
		[self setButton:button forKey:key];
		[button release];
	}
}

+ (void)setButton:(NSButton*)button forKey:(NSString*)key {
	if(key && button){
		[buttonDict setObject:button forKey:key];
	}
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
				  afterDelay:0
					  inModes:[NSArray arrayWithObjects:NSRunLoopCommonModes, NSEventTrackingRunLoopMode, nil]];
	
	if (([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask) != 0) {
		[[NSNotificationCenter defaultCenter] postNotificationName:GROWL_CLOSE_ALL_NOTIFICATIONS
															object:nil];
	}
}

- (void) setCloseBoxVisible:(BOOL)yorn {
	if ([self showsCloseBox]) {
		NSButton *button = [GrowlNotificationView closeButtonForKey:[self buttonKey]];
		[button setTarget:self];
		[button setAction:@selector(clickedCloseBox:)];
		[button setFrameOrigin:closeBoxOrigin];
		if(yorn)
			[self addSubview:button];
		else 
			[button removeFromSuperview];
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

-(NSDictionary*)configurationDict {
	if([[[self window] windowController] respondsToSelector:@selector(configurationDict)])
		return [[[self window] windowController] configurationDict];
	return nil;
}

-(NSString*)buttonKey {
	return [[NSBundle bundleForClass:[self class]] bundleIdentifier];
}

@end
