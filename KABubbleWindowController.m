#import "KABubbleWindowController.h"
#import "KABubbleWindowView.h"

static unsigned int bubbleWindowDepth = 0;

@implementation KABubbleWindowController

#define TIMER_INTERVAL ( 1. / 30. )
#define FADE_INCREMENT 0.05
#define DISPLAY_TIME 4.
#define KABubblePadding 10.

#pragma mark -

+ (KABubbleWindowController *) bubble {
	return [[[self alloc] init] autorelease];
}

+ (KABubbleWindowController *) bubbleWithTitle:(NSString *) title text:(id) text icon:(NSImage *) icon {
	id ret = [[[self alloc] init] autorelease];
	[ret setTitle:title];
	if( [text isKindOfClass:[NSString class]] ) [ret setText:text];
	else if( [text isKindOfClass:[NSAttributedString class]] ) [ret setAttributedText:text];
	[ret setIcon:icon];
	return ret;
}

#pragma mark Regularly Scheduled Coding

- (id) init {
	extern unsigned int bubbleWindowDepth;

	NSPanel *panel = [[[NSPanel alloc] initWithContentRect:NSMakeRect( 0., 0., 270., 65. ) 
												 styleMask:NSBorderlessWindowMask 
												   backing:NSBackingStoreBuffered defer:NO] autorelease];
	NSRect panelFrame = [panel frame];
	[panel setBecomesKeyOnlyIfNeeded:YES];
	[panel setHidesOnDeactivate:NO];
	[panel setBackgroundColor:[NSColor clearColor]];
	[panel setLevel:NSStatusWindowLevel];
	[panel setAlphaValue:0.];
	[panel setOpaque:NO];
	[panel setHasShadow:YES];
	[panel setCanHide:NO];
	[panel setReleasedWhenClosed:YES];
	[panel setDelegate:self];

	KABubbleWindowView *view = [[[KABubbleWindowView alloc] initWithFrame:panelFrame] autorelease];
	[view setTarget:self];
	[view setAction:@selector( _bubbleClicked: )];
	[panel setContentView:view];

	NSRect screen = [[NSScreen mainScreen] visibleFrame];
	[panel setFrameTopLeftPoint:NSMakePoint( NSWidth( screen ) - NSWidth( panelFrame ) - KABubblePadding, 
											 NSMaxY( screen ) - KABubblePadding - ( NSHeight( panelFrame ) * bubbleWindowDepth ) )];

	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector( _applicationDidSwitch: ) 
												 name:NSApplicationDidBecomeActiveNotification 
											   object:[NSApplication sharedApplication]];
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector( _applicationDidSwitch: ) 
												 name:NSApplicationDidHideNotification 
											   object:[NSApplication sharedApplication]];

	_depth = ++bubbleWindowDepth;
	_autoFadeOut = YES;
	_delegate = nil;
	_target = nil;
	_representedObject = nil;
	_action = NULL;
	_animationTimer = nil;

	return ( self = [super initWithWindow:panel] );
}

- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[_target release];
	[_representedObject release];
	[_animationTimer invalidate];
	[_animationTimer release];

	_target = nil;
	_representedObject = nil;
	_delegate = nil;
	_animationTimer = nil;

	extern unsigned int bubbleWindowDepth;
	if( _depth == bubbleWindowDepth ) bubbleWindowDepth = 0;

	[super dealloc];
}

#pragma mark -

- (void) _stopTimer {
	[_animationTimer invalidate];
	[_animationTimer release];
	_animationTimer = nil;
}

- (void) _waitBeforeFadeOut {
	[self _stopTimer];
	_animationTimer = [[NSTimer scheduledTimerWithTimeInterval:DISPLAY_TIME target:self selector:@selector( startFadeOut ) userInfo:nil repeats:NO] retain];
}

- (void) _fadeIn:(NSTimer *) inTimer {
	NSWindow *myWindow = [self window];
	float alpha = [myWindow alphaValue];
	if( alpha < 1. ) {
		[myWindow setAlphaValue:(alpha + FADE_INCREMENT)];
	} else if( _autoFadeOut ) {
		if( _delegate && [_delegate respondsToSelector:@selector( bubbleDidFadeIn: )] )
			[_delegate bubbleDidFadeIn:self];
		[self _waitBeforeFadeOut];
	}
}

- (void) _fadeOut:(NSTimer *) inTimer {
	NSWindow *myWindow = [self window];
	float alpha = [myWindow alphaValue];
	if( alpha > 0. ) {
		[myWindow setAlphaValue:(alpha - FADE_INCREMENT)];
	} else {
		[self _stopTimer];
		if( _delegate && [_delegate respondsToSelector:@selector( bubbleDidFadeOut: )] )
			[_delegate bubbleDidFadeOut:self];
		[self close];
		[self autorelease]; // Release, we retained when we faded in.
	}
}

- (void) _applicationDidSwitch:(NSNotification *) notification {
	[self startFadeOut];
}

- (void) _bubbleClicked:(id) sender {
	if( _target && _action && [_target respondsToSelector:_action] )
		[_target performSelector:_action withObject:self];
	[self startFadeOut];
}

#pragma mark -

- (void) startFadeIn {
	if( _delegate && [_delegate respondsToSelector:@selector( bubbleWillFadeIn: )] )
		[_delegate bubbleWillFadeIn:self];
	[self retain]; // Retain, after fade out we release.
	[self showWindow:nil];
	[self _stopTimer];
	_animationTimer = [[NSTimer scheduledTimerWithTimeInterval:TIMER_INTERVAL target:self selector:@selector( _fadeIn: ) userInfo:nil repeats:YES] retain];
}

- (void) startFadeOut {
	if( _delegate && [_delegate respondsToSelector:@selector( bubbleWillFadeOut: )] )
		[_delegate bubbleWillFadeOut:self];
	[self _stopTimer];
	_animationTimer = [[NSTimer scheduledTimerWithTimeInterval:TIMER_INTERVAL target:self selector:@selector( _fadeOut: ) userInfo:nil repeats:YES] retain];
}

#pragma mark -

- (BOOL) automaticallyFadesOut {
	return _autoFadeOut;
}

- (void) setAutomaticallyFadesOut:(BOOL) autoFade {
	_autoFadeOut = autoFade;
}

#pragma mark -

- (id) target {
	return _target;
}

- (void) setTarget:(id) object {
	[_target autorelease];
	_target = [object retain];
}

#pragma mark -

- (SEL) action {
	return _action;
}

- (void) setAction:(SEL) selector {
	_action = selector;
}

#pragma mark -

- (id) representedObject {
	return _representedObject;
}

- (void) setRepresentedObject:(id) object {
	[_representedObject autorelease];
	_representedObject = [object retain];
}

#pragma mark -

- (id) delegate {
	return _delegate;
}

- (void) setDelegate:(id) delegate {
	_delegate = delegate;
}

#pragma mark -

- (BOOL) respondsToSelector:(SEL) selector {
	BOOL contentViewRespondsToSelector = [[[self window] contentView] respondsToSelector:selector];
	return contentViewRespondsToSelector ? contentViewRespondsToSelector : [super respondsToSelector:selector];
}

- (void) forwardInvocation:(NSInvocation *) invocation {
	NSView *contentView = [[self window] contentView];
	if( [contentView respondsToSelector:[invocation selector]] )
		[invocation invokeWithTarget:contentView];
	else [super forwardInvocation:invocation];
}

- (NSMethodSignature *) methodSignatureForSelector:(SEL) selector {
	NSView *contentView = [[self window] contentView];
	if( [contentView respondsToSelector:selector] )
		return [contentView methodSignatureForSelector:selector];
	else return [super methodSignatureForSelector:selector];
}
@end
