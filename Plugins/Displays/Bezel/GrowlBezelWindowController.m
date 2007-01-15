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
#import "GrowlRipplingWindowTransition.h"
#import "GrowlWindowTransition.h"
#import "GrowlApplicationNotification.h"

@implementation GrowlBezelWindowController

#define MIN_DISPLAY_TIME 3.0
#define GrowlBezelPadding 10.0f

- (id) init {
	int sizePref = 0;
	screenNumber = 0U;
	shrinkEnabled = NO;
	flipEnabled = NO;

	displayDuration = MIN_DISPLAY_TIME;

	CFNumberRef prefsDuration = NULL;
	CFTimeInterval value = -1.0f;
	READ_GROWL_PREF_VALUE(GrowlBezelDuration, GrowlBezelPrefDomain, CFNumberRef, &prefsDuration);
	if (prefsDuration) {
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
													defer:YES];
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

	// call super so everything else is set up...
	if ((self = [super initWithWindow:panel])) {
		// set up the transitions...
		/*GrowlRipplingWindowTransition *ripple = [[GrowlRipplingWindowTransition alloc] initWithWindow:panel];
		[self addTransition:ripple];
		[self setStartPercentage:0 endPercentage:100 forTransition:ripple];
		[ripple setAutoReverses:NO];
		[ripple release];
		[panel setAlphaValue:1.0f];
		*/
		GrowlFadingWindowTransition *fader = [[GrowlFadingWindowTransition alloc] initWithWindow:panel];
		[self addTransition:fader];
		[self setStartPercentage:0 endPercentage:100 forTransition:fader];
		[fader setAutoReverses:YES];
		[fader release];

		if (shrinkEnabled) {
			GrowlShrinkingWindowTransition *shrinker = [[GrowlShrinkingWindowTransition alloc] initWithWindow:panel];
			[self addTransition:shrinker];
			[self setStartPercentage:0 endPercentage:80 forTransition:shrinker];
			[shrinker setAutoReverses:YES];
			[shrinker release];
		}
		if (flipEnabled) {
			GrowlFlippingWindowTransition *flipper = [[GrowlFlippingWindowTransition alloc] initWithWindow:panel];
			[self addTransition:flipper];
			[self setStartPercentage:0 endPercentage:100 forTransition:flipper];
			[flipper setFlipsX:YES];
			[flipper setAutoReverses:YES];
			[flipper release];
		}
	}
	return self;
}

#pragma mark -

- (void) setNotification: (GrowlApplicationNotification *) theNotification {
	[super setNotification:theNotification];
	if (!theNotification)
		return;

	NSDictionary *noteDict = [notification dictionaryRepresentation];
	NSString *title = [notification title];
	NSString *text  = [notification notificationDescription];
	NSImage *icon   = getObjectForKey(noteDict, GROWL_NOTIFICATION_ICON);
	int myPriority  = getIntegerForKey(noteDict, GROWL_NOTIFICATION_PRIORITY);
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
		text = [notification notificationDescription];
	}

	NSPanel *panel = (NSPanel *)[self window];
	GrowlBezelWindowView *view = [[self window] contentView];
	[view setPriority:myPriority];
	[view setTitle:title];// isHTML:titleHTML];
	[view setText:text];// isHTML:textHTML];
	[view setIcon:icon];
	[panel setFrame:[view frame] display:NO];
}

- (NSString *) identifier {
	return identifier;
}

#pragma mark -

- (void) dealloc {
	NSWindow *myWindow = [self window];
	[[myWindow contentView] release];
	[identifier  release];
	[myWindow    release];
	[super dealloc];
}


#pragma mark -
#pragma mark positioning methods

- (NSPoint) idealOriginInRect:(NSRect)rect {
	NSRect viewFrame = [[[self window] contentView] frame];

	NSPoint result;
	int positionPref = BEZEL_POSITION_DEFAULT;
	READ_GROWL_PREF_INT(BEZEL_POSITION_PREF, GrowlBezelPrefDomain, &positionPref);
	switch (positionPref) {
		default:
		case BEZEL_POSITION_DEFAULT:
			result.x = rect.origin.x + ceilf((NSWidth(rect) - NSWidth(viewFrame)) * 0.5f);
			result.y = rect.origin.y + 140.0f;
			break;
		case BEZEL_POSITION_TOPRIGHT:
			result.x = NSMaxX(rect) - NSWidth(viewFrame) - GrowlBezelPadding;
			result.y = NSMaxY(rect) - GrowlBezelPadding - NSHeight(viewFrame);
			break;
		case BEZEL_POSITION_BOTTOMRIGHT:
			result.x = NSMaxX(rect) - NSWidth(viewFrame) - GrowlBezelPadding;
			result.y = rect.origin.y + GrowlBezelPadding;
			break;
		case BEZEL_POSITION_BOTTOMLEFT:
			result.x = rect.origin.x + GrowlBezelPadding;
			result.y = rect.origin.y + GrowlBezelPadding;
			break;
		case BEZEL_POSITION_TOPLEFT:
			result.x = rect.origin.x + GrowlBezelPadding;
			result.y = NSMaxY(rect) - GrowlBezelPadding - NSHeight(viewFrame);
			break;
	}
	return result;
}

- (enum GrowlExpansionDirection) primaryExpansionDirection {
	return GrowlNoExpansionDirection;
}

- (enum GrowlExpansionDirection) secondaryExpansionDirection {
	return GrowlNoExpansionDirection;
}

- (float) requiredDistanceFromExistingDisplays {
	return GrowlBezelPadding;
}

- (BOOL) requiresPositioning {
	return NO;
}

@end
