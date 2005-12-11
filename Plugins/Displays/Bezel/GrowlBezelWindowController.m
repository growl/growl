//
//  GrowlBezelWindowController.m
//  Display Plugins
//
//  Created by Jorge Salvador Caffarena on 09/09/04.
//  Copyright 2004 Jorge Salvador Caffarena. All rights reserved.
//

#import "GrowlBezelWindowController.h"
#import "GrowlBezelWindowView.h"
#import "GrowlBezelPrefs.h"
#import "NSWindow+Transforms.h"
#include "CFDictionaryAdditions.h"
#import "GrowlAnimation.h"
#import "GrowlFadingWindowTransition.h"
#import "GrowlFlippingWindowTransition.h"
#import "GrowlShrinkingWindowTransition.h"
#import "GrowlWindowTransition.h"


@implementation GrowlBezelWindowController

#define MIN_DISPLAY_TIME 3.0
#define GrowlBezelPadding 10.0f

- (id) init {
	NSLog(@"%s\n", __FUNCTION__);
	int sizePref = 0;
	screenNumber = 0U;
	shrinkEnabled = NO;
	flipEnabled = NO;

	displayDuration = MIN_DISPLAY_TIME;
	
	CFNumberRef prefsDuration = NULL;
	CFTimeInterval value = -1.0f;
	READ_GROWL_PREF_VALUE(GrowlBezelDuration, GrowlBezelPrefDomain, CFNumberRef, &prefsDuration);
	if(prefsDuration) {
		CFNumberGetValue(prefsDuration, kCFNumberDoubleType, &value);
		//NSLog(@"%lf\n", value);
		if (value > 0.0f)
			displayDuration = value;
	}

	READ_GROWL_PREF_INT(BEZEL_SCREEN_PREF, GrowlBezelPrefDomain, &screenNumber);
	[self setScreen:[[NSScreen screens] objectAtIndex:screenNumber]];
	
	READ_GROWL_PREF_INT(BEZEL_SIZE_PREF, GrowlBezelPrefDomain, &sizePref);
	READ_GROWL_PREF_BOOL(BEZEL_SHRINK_PREF, GrowlBezelPrefDomain, &shrinkEnabled);
	READ_GROWL_PREF_BOOL(BEZEL_FLIP_PREF, GrowlBezelPrefDomain, &flipEnabled);

	NSRect sizeRect;
	sizeRect.origin.x = 0.0f;
	sizeRect.origin.y = 0.0f;

	if (sizePref == BEZEL_SIZE_NORMAL) {
		sizeRect.size.width = 211.0f;
		sizeRect.size.height = 206.0f;
	} else {
		sizeRect.size.width = 160.0f;
		sizeRect.size.height = 160.0f;
	}
	NSPanel *panel = [[NSPanel alloc] initWithContentRect:sizeRect
												styleMask:NSBorderlessWindowMask
												  backing:NSBackingStoreBuffered
													defer:NO];
	NSRect panelFrame = [panel frame];
	[panel setBecomesKeyOnlyIfNeeded:YES];
	[panel setHidesOnDeactivate:NO];
	[panel setBackgroundColor:[NSColor clearColor]];
	[panel setLevel:NSStatusWindowLevel];
	[panel setIgnoresMouseEvents:YES];
	[panel setSticky:YES];
	[panel setOpaque:NO];
	[panel setHasShadow:NO];
	[panel setCanHide:NO];
	[panel setOneShot:YES];
	[panel useOptimizedDrawing:YES];
	[panel setAlphaValue:0.0f];
	//[panel setReleasedWhenClosed:YES]; // ignored for windows owned by window controllers.
	[panel setDelegate:self];

	GrowlBezelWindowView *view = [[GrowlBezelWindowView alloc] initWithFrame:panelFrame];
	[view setTarget:self];
	[view setAction:@selector(notificationClicked:)];
	[view setDelegate:self];
	[view setCloseOnMouseExit:YES];
	[panel setContentView:view];

	panelFrame = [view frame];
	[panel setFrame:panelFrame display:NO];

	NSPoint panelTopLeft;
	int positionPref = BEZEL_POSITION_DEFAULT;
	READ_GROWL_PREF_INT(BEZEL_POSITION_PREF, GrowlBezelPrefDomain, &positionPref);
	NSRect screen;
	switch (positionPref) {
		default:
		case BEZEL_POSITION_DEFAULT:
			screen = [[self screen] frame];
			panelTopLeft.x = screen.origin.x + ceilf((NSWidth(screen) - NSWidth(panelFrame)) * 0.5f);
			panelTopLeft.y = screen.origin.y + 140.0f + NSHeight(panelFrame);
			break;
		case BEZEL_POSITION_TOPRIGHT:
			screen = [[self screen] visibleFrame];
			panelTopLeft.x = NSMaxX(screen) - NSWidth(panelFrame) - GrowlBezelPadding;
			panelTopLeft.y = NSMaxY(screen) - GrowlBezelPadding;
			break;
		case BEZEL_POSITION_BOTTOMRIGHT:
			screen = [[self screen] visibleFrame];
			panelTopLeft.x = NSMaxX(screen) - NSWidth(panelFrame) - GrowlBezelPadding;
			panelTopLeft.y = screen.origin.y + GrowlBezelPadding + NSHeight(panelFrame);
			break;
		case BEZEL_POSITION_BOTTOMLEFT:
			screen = [[self screen] visibleFrame];
			panelTopLeft.x = screen.origin.x + GrowlBezelPadding;
			panelTopLeft.y = screen.origin.y + GrowlBezelPadding + NSHeight(panelFrame);
			break;
		case BEZEL_POSITION_TOPLEFT:
			screen = [[self screen] visibleFrame];
			panelTopLeft.x = screen.origin.x + GrowlBezelPadding;
			panelTopLeft.y = NSMaxY(screen) - GrowlBezelPadding;
			break;
	}
	[panel setFrameTopLeftPoint:panelTopLeft];

	// call super so everything else is set up...
	self = [super initWithWindow:panel];
	if (!self)
		return nil;
	
	// set up the transitions...
	GrowlFadingWindowTransition *fader = [[GrowlFadingWindowTransition alloc] initWithWindow:panel];
	[self addTransition:fader];
	[self setStartPercentage:0 endPercentage:100 forTransition:fader];
	[fader setAutoReverses:YES];
	[fader release];
	
	if(shrinkEnabled) {
		GrowlShrinkingWindowTransition *shrinker = [[GrowlShrinkingWindowTransition alloc] initWithWindow:panel];
		[self addTransition:shrinker];
		[self setStartPercentage:0 endPercentage:100 forTransition:shrinker];
		[shrinker setAutoReverses:YES];
		[shrinker release];
	}
	if(flipEnabled) {
		GrowlFlippingWindowTransition *flipper = [[GrowlFlippingWindowTransition alloc] initWithWindow:panel];
		[self addTransition:flipper];
		[self setStartPercentage:0 endPercentage:100 forTransition:flipper];
		[flipper setFlipsX:YES];
		[flipper setAutoReverses:YES];
		[flipper release];
	}
	return self;
}

/*- (id) initWithTitle:(NSString *)title text:(NSString *)text icon:(NSImage *)icon priority:(int)prio identifier:(NSString *)ident {
	identifier = [ident retain];

	int sizePref = 0;
	float duration = MIN_DISPLAY_TIME;
	unsigned screenNumber = 0U;
	shrinkEnabled = YES;
	flipEnabled = YES;

	READ_GROWL_PREF_INT(BEZEL_SCREEN_PREF, GrowlBezelPrefDomain, &screenNumber);
	[self setScreen:[[NSScreen screens] objectAtIndex:screenNumber]];
	
	READ_GROWL_PREF_INT(BEZEL_SIZE_PREF, GrowlBezelPrefDomain, &sizePref);
	READ_GROWL_PREF_FLOAT(BEZEL_DURATION_PREF, GrowlBezelPrefDomain, &duration);
	READ_GROWL_PREF_BOOL(BEZEL_SHRINK_PREF, GrowlBezelPrefDomain, &shrinkEnabled);
	READ_GROWL_PREF_BOOL(BEZEL_FLIP_PREF, GrowlBezelPrefDomain, &flipEnabled);

	NSRect sizeRect;
	sizeRect.origin.x = 0.0f;
	sizeRect.origin.y = 0.0f;

	if (sizePref == BEZEL_SIZE_NORMAL) {
		sizeRect.size.width = 211.0f;
		sizeRect.size.height = 206.0f;
	} else {
		sizeRect.size.width = 160.0f;
		sizeRect.size.height = 160.0f;
	}
	NSPanel *panel = [[NSPanel alloc] initWithContentRect:sizeRect
												styleMask:NSBorderlessWindowMask
												  backing:NSBackingStoreBuffered
													defer:NO];
	NSRect panelFrame = [panel frame];
	[panel setBecomesKeyOnlyIfNeeded:YES];
	[panel setHidesOnDeactivate:NO];
	[panel setBackgroundColor:[NSColor clearColor]];
	[panel setLevel:NSStatusWindowLevel];
	[panel setIgnoresMouseEvents:YES];
	[panel setSticky:YES];
	[panel setOpaque:NO];
	[panel setHasShadow:NO];
	[panel setCanHide:NO];
	[panel setOneShot:YES];
	[panel useOptimizedDrawing:YES];
	//[panel setReleasedWhenClosed:YES]; // ignored for windows owned by window controllers.
	//[panel setDelegate:self];

	contentView = [[GrowlBezelWindowView alloc] initWithFrame:panelFrame];

	//[view setTarget:self];
	//[view setAction:@selector(notificationClicked:)];
	[panel setContentView:contentView];

	[contentView setPriority:prio];
	[contentView setTitle:title];
	[self setText:text];
	[contentView setIcon:icon];
	panelFrame = [contentView frame];
	[panel setFrame:panelFrame display:NO];

	NSPoint panelTopLeft;
	int positionPref = BEZEL_POSITION_DEFAULT;
	READ_GROWL_PREF_INT(BEZEL_POSITION_PREF, GrowlBezelPrefDomain, &positionPref);
	NSRect screen;
	switch (positionPref) {
		default:
		case BEZEL_POSITION_DEFAULT:
			screen = [[self screen] frame];
			panelTopLeft.x = screen.origin.x + ceilf((NSWidth(screen) - NSWidth(panelFrame)) * 0.5f);
			panelTopLeft.y = screen.origin.y + 140.0f + NSHeight(panelFrame);
			break;
		case BEZEL_POSITION_TOPRIGHT:
			screen = [[self screen] visibleFrame];
			panelTopLeft.x = NSMaxX(screen) - NSWidth(panelFrame) - GrowlBezelPadding;
			panelTopLeft.y = NSMaxY(screen) - GrowlBezelPadding;
			break;
		case BEZEL_POSITION_BOTTOMRIGHT:
			screen = [[self screen] visibleFrame];
			panelTopLeft.x = NSMaxX(screen) - NSWidth(panelFrame) - GrowlBezelPadding;
			panelTopLeft.y = screen.origin.y + GrowlBezelPadding + NSHeight(panelFrame);
			break;
		case BEZEL_POSITION_BOTTOMLEFT:
			screen = [[self screen] visibleFrame];
			panelTopLeft.x = screen.origin.x + GrowlBezelPadding;
			panelTopLeft.y = screen.origin.y + GrowlBezelPadding + NSHeight(panelFrame);
			break;
		case BEZEL_POSITION_TOPLEFT:
			screen = [[self screen] visibleFrame];
			panelTopLeft.x = screen.origin.x + GrowlBezelPadding;
			panelTopLeft.y = NSMaxY(screen) - GrowlBezelPadding;
			break;
	}
	[panel setFrameTopLeftPoint:panelTopLeft];

	if ((self = [super initWithWindow:panel])) {
		autoFadeOut = YES;	//!sticky
		doFadeIn = NO;
		[self setDisplayDuration:duration];
		priority = prio;
		animationDuration = 0.25;
	}

	return self;
}*/

#pragma mark -

- (unsigned) depth {
	return depth;
}

- (void) setNotification: (GrowlApplicationNotification *) theNotification {
	NSLog(@"%s\n", __FUNCTION__);
	[super setNotification:theNotification];
	if (!theNotification)
		return;
	
	NSDictionary *noteDict = [notification dictionaryRepresentation];
	NSString *title = [notification title];
	NSString *text  = [notification description];
	NSImage *icon   = getObjectForKey(noteDict, GROWL_NOTIFICATION_ICON);
	int priority    = getIntegerForKey(noteDict, GROWL_NOTIFICATION_PRIORITY);
	BOOL sticky     = getBooleanForKey(noteDict, GROWL_NOTIFICATION_STICKY);
	NSString *ident = getObjectForKey(noteDict, GROWL_NOTIFICATION_IDENTIFIER);
	BOOL textHTML, titleHTML;
	
	if (title)
	titleHTML = YES;
	else {
		titleHTML = NO;
		title = [notification title];
	}
	if (text)
	textHTML = YES;
	else {
		textHTML = NO;
		text = [notification description];
	}
	
	NSPanel *panel = (NSPanel *)[self window];
	GrowlBezelWindowView *view = [[self window] contentView];
	[view setPriority:priority];
	[view setTitle:title];// isHTML:titleHTML];
	[view setText:text];// isHTML:textHTML];
	[view setIcon:icon];
	
	NSRect viewFrame = [view frame];
	[panel setFrame:viewFrame display:NO];
	NSRect screen = [[self screen] visibleFrame];
	[panel setFrameTopLeftPoint:NSMakePoint(NSMaxX(screen) - NSWidth(viewFrame) - GrowlBezelPadding,
											NSMaxY(screen) - GrowlBezelPadding - depth)];
	NSLog(@"%s %f %f %f %f\n", __FUNCTION__, [panel frame].origin.x, [panel frame].origin.y, [panel frame].size.height, [panel frame].size.width);

}

- (NSString *) identifier {
	return identifier;
}

#pragma mark -

/*- (int) priority {
	return priority;
}

- (void) setPriority:(int)newPriority {
	priority = newPriority;
	//[contentView setPriority:priority];
}

- (void) setTitle:(NSString *)title {
	//[contentView setTitle:title];
}

- (void) setText:(NSString *)text {
	// Sanity check to unify line endings
	CFIndex length = CFStringGetLength((CFStringRef)text);
	CFMutableStringRef tempText = CFStringCreateMutableCopy(kCFAllocatorDefault, length, (CFStringRef)text);
	CFStringFindAndReplace(tempText, CFSTR("\r"), CFSTR("\n"), CFRangeMake(0, length), 0);
	//[contentView setText:(NSString *)tempText];
	CFRelease(tempText);
}

- (void) setIcon:(NSImage *)icon {
	//[contentView setIcon:icon];
}

#pragma mark -

*/

- (void) dealloc {
	NSWindow *myWindow = [self window];
	[[myWindow contentView] release];
	[identifier  release];
	[myWindow    release];
	[super dealloc];
}

@end
