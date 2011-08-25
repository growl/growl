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
#import "GrowlFadingWindowTransition.h"
#import "GrowlFlippingWindowTransition.h"
#import "GrowlShrinkingWindowTransition.h"
#import "GrowlWindowTransition.h"
#import "GrowlNotification.h"

@implementation GrowlBezelWindowController

#define MIN_DISPLAY_TIME 3.0
#define GrowlBezelPadding 10.0

- (id) init {
	int sizePref = 0;
	screenNumber = 0U;
	shrinkEnabled = NO;
	flipEnabled = NO;

	CFNumberRef prefsDuration = NULL;
	READ_GROWL_PREF_VALUE(GrowlBezelDuration, GrowlBezelPrefDomain, CFNumberRef, &prefsDuration);
	[self setDisplayDuration:(prefsDuration ?
							  [(NSNumber *)prefsDuration doubleValue] :
							  MIN_DISPLAY_TIME)];
	if (prefsDuration) CFRelease(prefsDuration);

	READ_GROWL_PREF_INT(BEZEL_SCREEN_PREF, GrowlBezelPrefDomain, &screenNumber);
	NSArray *screens = [NSScreen screens];
	NSUInteger screensCount = [screens count];
	if (screensCount) {
		[self setScreen:((screensCount >= (screenNumber + 1)) ? [screens objectAtIndex:screenNumber] : [screens objectAtIndex:0])];
	}

	READ_GROWL_PREF_INT(BEZEL_SIZE_PREF, GrowlBezelPrefDomain, &sizePref);
	READ_GROWL_PREF_BOOL(BEZEL_SHRINK_PREF, GrowlBezelPrefDomain, &shrinkEnabled);
	READ_GROWL_PREF_BOOL(BEZEL_FLIP_PREF, GrowlBezelPrefDomain, &flipEnabled);

	NSRect sizeRect;
	sizeRect.origin.x = 0.0;
	sizeRect.origin.y = 0.0;

	if (sizePref == BEZEL_SIZE_NORMAL) {
		sizeRect.size.width = 211.0;
		sizeRect.size.height = 206.0;
	} else {
		sizeRect.size.width = 160.0;
		sizeRect.size.height = 160.0;
	}
	NSPanel *panel = [[NSPanel alloc] initWithContentRect:sizeRect
												styleMask:NSBorderlessWindowMask
												  backing:NSBackingStoreBuffered
													defer:YES];
	NSRect panelFrame = [panel frame];
	[panel setBecomesKeyOnlyIfNeeded:YES];
	[panel setHidesOnDeactivate:NO];
	[panel setBackgroundColor:[NSColor clearColor]];
	[panel setLevel:GrowlVisualDisplayWindowLevel];
	[panel setIgnoresMouseEvents:YES];
	[panel setSticky:YES];
	[panel setOpaque:NO];
	[panel setHasShadow:NO];
	[panel setCanHide:NO];
	[panel setOneShot:YES];
	[panel useOptimizedDrawing:YES];
	[panel setAlphaValue:0.0];
	[panel setDelegate:self];

	GrowlBezelWindowView *view = [[GrowlBezelWindowView alloc] initWithFrame:panelFrame];
	[view setTarget:self];
	[view setAction:@selector(notificationClicked:)];
	[panel setContentView:view];
	[view release];

	panelFrame = [[panel contentView] frame];
	[panel setFrame:panelFrame display:NO];

	// call super so everything else is set up...
	if ((self = [super initWithWindow:panel])) {
		// set up the transitions...
		/*GrowlRipplingWindowTransition *ripple = [[GrowlRipplingWindowTransition alloc] initWithWindow:panel];
		[self addTransition:ripple];
		[self setStartPercentage:0 endPercentage:100 forTransition:ripple];
		[ripple setAutoReverses:NO];
		[ripple release];
		[panel setAlphaValue:1.0];
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
		
		[self setIgnoresOtherNotifications:YES];
	}
	[panel release];

	return self;
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
			result.x = rect.origin.x + GrowlCGFloatCeiling((NSWidth(rect) - NSWidth(viewFrame)) * 0.5);
			result.y = rect.origin.y + 140.0;
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

- (CGFloat) requiredDistanceFromExistingDisplays {
	return GrowlBezelPadding;
}

- (BOOL) requiresPositioning {
	return NO;
}

@end
