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
#import "NSGrowlAdditions.h"
#import "NSWindow+Transforms.h"

@implementation GrowlBezelWindowController

#define MIN_DISPLAY_TIME 3.0
#define GrowlBezelPadding 10.0f

+ (GrowlBezelWindowController *)bezel {
	return [[[GrowlBezelWindowController alloc] init] autorelease];
}

+ (GrowlBezelWindowController *)bezelWithTitle:(NSString *)title text:(NSString *)text
		icon:(NSImage *)icon priority:(int)prio sticky:(BOOL)sticky {
	return [[[GrowlBezelWindowController alloc] initWithTitle:title text:text icon:icon priority:prio sticky:sticky] autorelease];
}

- (id)initWithTitle:(NSString *)title text:(NSString *)text icon:(NSImage *)icon priority:(int)prio sticky:(BOOL)sticky {
	int sizePref = 0;
	float duration = MIN_DISPLAY_TIME;

	READ_GROWL_PREF_INT(BEZEL_SIZE_PREF, BezelPrefDomain, &sizePref);
	READ_GROWL_PREF_FLOAT(BEZEL_DURATION_PREF, BezelPrefDomain, &duration);

	NSRect sizeRect;
	sizeRect.origin.x = sizeRect.origin.y = 0.0f;
	if (sizePref == BEZEL_SIZE_NORMAL) {
		sizeRect.size.width = 211.0f;
		sizeRect.size.height = 206.0f;
	} else {
		sizeRect.size.width = 160.0f;
		sizeRect.size.height = 160.0f;
	}
	NSPanel *panel = [[[NSPanel alloc] initWithContentRect:sizeRect
						styleMask:NSBorderlessWindowMask
						  backing:NSBackingStoreBuffered defer:NO] autorelease];
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
	[panel setReleasedWhenClosed:YES];
	[panel setDelegate:self];

	GrowlBezelWindowView *view = [[[GrowlBezelWindowView alloc] initWithFrame:panelFrame] autorelease];

	[view setTarget:self];
	[view setAction:@selector(_bezelClicked:)];
	[panel setContentView:view];
	
	[view setTitle:title];
	NSMutableString	*tempText = [NSMutableString stringWithString:text];
	// Sanity check to unify line endings
	[tempText replaceOccurrencesOfString:@"\r"
			withString:@"\n"
			options:nil
			range:NSMakeRange(0U, [tempText length])];
	[view setText:tempText];

	[view setIcon:icon];
	panelFrame = [view frame];
	[panel setFrame:panelFrame display:NO];

	NSRect screen = [[NSScreen mainScreen] visibleFrame];
	NSPoint panelTopLeft;
	int positionPref = BEZEL_POSITION_DEFAULT;
	READ_GROWL_PREF_INT(BEZEL_POSITION_PREF, BezelPrefDomain, &positionPref);
	switch (positionPref) {
		default:
		case BEZEL_POSITION_DEFAULT:
			panelTopLeft.x = screen.origin.x + ceilf((NSWidth(screen) - NSWidth(panelFrame)) * 0.5f);
			panelTopLeft.y = screen.origin.y + 140.0f + NSHeight(panelFrame);
			break;
		case BEZEL_POSITION_TOPRIGHT:
			panelTopLeft.x = NSMaxX(screen) - NSWidth(panelFrame) - GrowlBezelPadding;
			panelTopLeft.y = NSMaxY(screen) - GrowlBezelPadding;
			break;
		case BEZEL_POSITION_BOTTOMRIGHT:
			panelTopLeft.x = NSMaxX(screen) - NSWidth(panelFrame) - GrowlBezelPadding;
			panelTopLeft.y = screen.origin.y + GrowlBezelPadding + NSHeight(panelFrame);
			break;
		case BEZEL_POSITION_BOTTOMLEFT:
			panelTopLeft.x = screen.origin.x + GrowlBezelPadding;
			panelTopLeft.y = screen.origin.y + GrowlBezelPadding + NSHeight(panelFrame);
			break;
		case BEZEL_POSITION_TOPLEFT:
			panelTopLeft.x = screen.origin.x + GrowlBezelPadding;
			panelTopLeft.y = NSMaxY(screen) - GrowlBezelPadding;
			break;
	}
	[panel setFrameTopLeftPoint:panelTopLeft];

	if ( (self = [super initWithWindow:panel] ) ) {
		autoFadeOut = YES;	//!sticky
		doFadeIn = NO;
		displayTime = duration;
		priority = prio;
		scaleFactor = 1.0;
		fadeIncrement = 0.04f;
		timerInterval = 0.01;
	}

	return self;
}

- (void) dealloc {
	[target release];
	[clickContext release];
	[appName release];

	[super dealloc];
}

#pragma mark -

- (id)target {
	return target;
}

- (void)setTarget:(id)object {
	[target autorelease];
	target = [object retain];
}

#pragma mark -

- (SEL)action {
	return action;
}

- (void)setAction:(SEL)selector {
	action = selector;
}

#pragma mark -

- (int)priority {
	return priority;
}

- (void)setPriority:(int)newPriority {
	priority = newPriority;
}

#pragma mark -

- (NSString *)appName {
	return appName;
}

- (void) setAppName:(NSString *) inAppName {
	[appName autorelease];
	appName = [inAppName retain];
}

#pragma mark -

- (id) clickContext {
	return clickContext;
}

- (void) setClickContext:(id)inClickContext {
	[clickContext autorelease];
	clickContext = [inClickContext retain];
}

#pragma mark -

- (void) setFlipIn:(BOOL)flag {
	flipIn = flag;
	doFadeIn = flag;
}

- (void) setFlipOut:(BOOL)flag {
	flipOut = flag;
}

- (void) startFadeIn {
	if ( flipIn ) {
		scaleFactor = 0.05;
		[[self window] setScaleX:scaleFactor Y:1.0];
	}

	[super startFadeIn];
}

- (void) _fadeIn:(NSTimer *)timer {
	if ( flipIn ) {
		NSWindow *myWindow = [self window];
		if ( scaleFactor < 1.0 ) {
			scaleFactor += 0.05;
			[myWindow setScaleX:scaleFactor Y:1.0];
		} else {
			scaleFactor = 1.0;
			[myWindow reset];
			[self stopFadeIn];
		}
	} else {
		[super _fadeIn:timer];
	}
}

- (void) startFadeOut {
	scaleFactor = 1.0;
	[super startFadeOut];
}

- (void) _fadeOut:(NSTimer *)timer {
	NSWindow *myWindow = [self window];
	if ( flipOut ) {
		if ( scaleFactor > 0.0 ) {
			scaleFactor -= 0.05;
			[myWindow setScaleX:scaleFactor Y:1.0];
		} else {
			if ( delegate && [delegate respondsToSelector:@selector(didFadeOut:)] ) {
				[delegate didFadeOut:self];
			}
			[self stopFadeOut];
		}
	} else {
		[myWindow scaleX:0.8 Y:0.8];
		[super _fadeOut:timer];
	}
}

@end
