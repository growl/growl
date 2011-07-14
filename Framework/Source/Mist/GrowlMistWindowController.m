//
//  GrowlMistWindowController.m
//
//  Created by Rachel Blackman on 7/13/11.
//

#import "GrowlMistWindowController.h"

#import "GrowlDefinesInternal.h"

@implementation GrowlMistWindowController
@synthesize sticky;
@synthesize userInfo;
@synthesize visible;
@synthesize delegate;
@synthesize selected;

- (id)initWithNotificationTitle:(NSString *)title text:(NSString *)text image:(NSImage *)image sticky:(BOOL)isSticky userInfo:(id)info delegate:(id)aDelegate
{
	GrowlMistView *mistViewForSetup = [[[GrowlMistView alloc] initWithFrame:NSZeroRect] autorelease];
	mistViewForSetup.notificationTitle = title;
	mistViewForSetup.notificationText = text;
	mistViewForSetup.notificationImage = image;
	mistViewForSetup.delegate = self;
	[mistViewForSetup sizeToFit];
	
	NSRect mistRect = mistViewForSetup.frame;
	NSWindow *tempWindow = [[NSWindow alloc] initWithContentRect:mistRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:YES]; 
	self = [super initWithWindow:tempWindow];
	if (self) {
		mistView = [mistViewForSetup retain];
		[tempWindow setContentView:mistView];
		[tempWindow setOpaque:NO];
		[tempWindow setBackgroundColor:[NSColor clearColor]];
		[tempWindow setLevel:GrowlVisualDisplayWindowLevel];
		[tempWindow setAcceptsMouseMovedEvents:YES];
		userInfo = [info retain];
		delegate = aDelegate;
		visible = NO;
		sticky = isSticky;
		if (!sticky)
			lifetime = [[NSTimer scheduledTimerWithTimeInterval:MIST_LIFETIME target:self selector:@selector(lifetimeExpired:) userInfo:nil repeats:NO] retain];
	}
	[tempWindow release];
	return self;
}

- (void)dealloc {
	[lifetime invalidate];
	[lifetime release];
	[fadeAnimation stopAnimation]; //We'll release it in our response to the callback notifying us that it's stopping.
	[mistView release];
	[userInfo release];
	[super dealloc];
}

- (void)fadeIn {
	[[self window] setAlphaValue:0.0f];
	[[self window] orderFront:nil];
	
	NSDictionary *fadeIn = [NSDictionary dictionaryWithObjectsAndKeys:
							 [self window], NSViewAnimationTargetKey,
							 NSViewAnimationFadeInEffect, NSViewAnimationEffectKey,
							nil];	
	
    NSArray *animations;
    animations = [NSArray arrayWithObject:fadeIn];
	
    fadeAnimation = [[NSViewAnimation alloc]
				 initWithViewAnimations:animations];
	
    [fadeAnimation setAnimationBlockingMode:NSAnimationNonblocking];
    [fadeAnimation setDuration:0.3];
    [fadeAnimation startAnimation];	
	visible = YES;
}

- (void)animationDidEnd:(NSAnimation *)animation {
	// Free up the animation
	[animation release];
	[[self window] orderOut:nil];
	visible = NO;
	
	// Callback to our delegate, to let it know that we've finished.
	if (closed) {
		// We were closed via timeout or the close button
		if ([[self delegate] respondsToSelector:@selector(mistNotificationDismissed:)])
			[[self delegate] mistNotificationDismissed:self];
	}
	else {
		// We were clicked properly and so should use the callback
		if ([[self delegate] respondsToSelector:@selector(mistNotificationClicked:)])
			[[self delegate] mistNotificationClicked:self];
	}
}

- (void)animationDidStop:(NSAnimation *)animation {
	[self animationDidEnd:animation];
}

- (void)fadeOut {
	NSDictionary *fadeOut = [NSDictionary dictionaryWithObjectsAndKeys:
							 [self window], NSViewAnimationTargetKey,
							 NSViewAnimationFadeOutEffect,
							 NSViewAnimationEffectKey, nil];	
	
    NSArray *animations;
    animations = [NSArray arrayWithObject:fadeOut];
	
    fadeAnimation = [[NSViewAnimation alloc]
				 initWithViewAnimations:animations];
	
    [fadeAnimation setAnimationBlockingMode:NSAnimationNonblocking];
    [fadeAnimation setDuration:0.3];
	[fadeAnimation setDelegate:self];
    [fadeAnimation startAnimation];	
}

- (void)mistViewDismissed:(BOOL)wasClosed
{
	closed = wasClosed;
	[self fadeOut];
}


- (void)lifetimeExpired:(NSNotification *)timerNotification {
	// Act like the close button was clicked.
	[self mistViewDismissed:YES];
}

- (void)mistViewSelected:(BOOL)isSelected
{
	selected = isSelected;
	// Stop our lifetime-timer
	if (selected) {
		[lifetime invalidate];
		[lifetime release];
		lifetime = nil;
	}
	else {
		if (!sticky)
			lifetime = [[NSTimer scheduledTimerWithTimeInterval:MIST_LIFETIME target:self selector:@selector(lifetimeExpired:) userInfo:nil repeats:NO] retain];
	}
}


@end
