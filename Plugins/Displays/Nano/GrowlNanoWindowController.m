//
//  GrowlNanoWindowController.m
//  Display Plugins
//
//  Created by Rudy Richter on 12/12/2005.
//  Copyright 2005-2006, The Growl Project. All rights reserved.
//


#import "GrowlNanoWindowController.h"
#import "GrowlNanoWindowView.h"
#import "GrowlNanoPrefs.h"
#import "NSWindow+Transforms.h"
#import "GrowlSlidingWindowTransition.h"
#import "GrowlWipeWindowTransition.h"
#import "GrowlApplicationNotification.h"
#include "CFDictionaryAdditions.h"

@implementation GrowlNanoWindowController

- (id) init {
	int sizePref = Nano_SIZE_NORMAL;

	//define our duration
	displayDuration = GrowlNanoDurationPrefDefault;
	CFNumberRef prefsDuration = NULL;
	CFTimeInterval value = -1.0f;
	READ_GROWL_PREF_VALUE(Nano_DURATION_PREF, GrowlNanoPrefDomain, CFNumberRef, &prefsDuration);
	if (prefsDuration) {
		CFNumberGetValue(prefsDuration, kCFNumberDoubleType, &value);
		if (value > 0.0f)
			displayDuration = value;
	}

	screenNumber = 0U;
	READ_GROWL_PREF_INT(Nano_SCREEN_PREF, GrowlNanoPrefDomain, &screenNumber);
	[self setScreen:[[NSScreen screens] objectAtIndex:screenNumber]];

	NSRect sizeRect;
	NSRect screen = [[self screen] frame];
	READ_GROWL_PREF_INT(Nano_SIZE_PREF, GrowlNanoPrefDomain, &sizePref);
	sizeRect.origin = screen.origin;
	if (sizePref == Nano_SIZE_HUGE) {
		sizeRect.size.height = 50.0f;	
		sizeRect.size.width = 270.0f;
	} else {
		sizeRect.size.height = 25.0f;
		sizeRect.size.width = 185.0f;
	}
	frameHeight = sizeRect.size.height;

	READ_GROWL_PREF_INT(Nano_SIZE_PREF, GrowlNanoPrefDomain, &sizePref);
	NSPanel *panel = [[NSPanel alloc] initWithContentRect:sizeRect
												styleMask:NSBorderlessWindowMask
												  backing:NSBackingStoreBuffered
													defer:YES];
	NSRect panelFrame = [panel frame];
	[panel setBecomesKeyOnlyIfNeeded:YES];
	[panel setHidesOnDeactivate:NO];
	[panel setBackgroundColor:[NSColor clearColor]];
	[panel setLevel:NSFloatingWindowLevel];
	[panel setIgnoresMouseEvents:YES];
	[panel setSticky:YES];
	[panel setOpaque:NO];
	[panel setHasShadow:NO];
	[panel setCanHide:NO];
	[panel setOneShot:YES];
	[panel useOptimizedDrawing:YES];
	[panel setDelegate:self];

	GrowlNanoWindowView *view = [[GrowlNanoWindowView alloc] initWithFrame:panelFrame];

	[view setTarget:self];
	[view setAction:@selector(notificationClicked:)]; // Not used for now

	[panel setContentView:view]; // retains subview
	[view release];
	
	float xPosition = NSMaxX(screen) - (NSMaxX(screen) / 4);
	float yPosition = NSMaxY(screen);
	if([NSMenu menuBarVisible])
		yPosition-=[NSMenuView menuBarHeight];
	
	[panel setFrameOrigin:NSMakePoint(xPosition, yPosition)];

	// call super so everything else is set up...
	if ((self = [super initWithWindow:panel])) {
		int effect = 0;
		READ_GROWL_PREF_INT(Nano_EFFECT_PREF, GrowlNanoPrefDomain, &effect);
		if (effect == 0) {
			//slider effect
			GrowlSlidingWindowTransition *slider = [[GrowlSlidingWindowTransition alloc] initWithWindow:panel];
			[slider setFromOrigin:NSMakePoint(xPosition, yPosition) toOrigin:NSMakePoint(xPosition, yPosition - frameHeight)];
			[self setStartPercentage:0 endPercentage:100 forTransition:slider];
			[slider setAutoReverses:YES];
			[self addTransition:slider];
			[slider release];
		} else {
			//wipe effect
			[panel setFrameOrigin:NSMakePoint(xPosition, NSMaxY(screen))];
			GrowlWipeWindowTransition *wiper = [[GrowlWipeWindowTransition alloc] initWithWindow:panel];
			[wiper setFromOrigin:NSMakePoint(xPosition, yPosition) toOrigin:NSMakePoint(xPosition, yPosition - frameHeight)];
			[self setStartPercentage:0 endPercentage:100 forTransition:wiper];
			[wiper setAutoReverses:YES];
			[self addTransition:wiper];
			[wiper release];
		}
	}
	return self;

}

- (void) setNotification: (GrowlApplicationNotification *) theNotification {
	[super setNotification:theNotification];
	if (!theNotification)
		return;

	NSDictionary *noteDict = [notification dictionaryRepresentation];
	NSString *title = [notification title];
	NSString *text  = [notification notificationDescription];
	NSImage *icon   = getObjectForKey(noteDict, GROWL_NOTIFICATION_ICON);
	int prio        = getIntegerForKey(noteDict, GROWL_NOTIFICATION_PRIORITY);
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
	GrowlNanoWindowView *view = [panel contentView];
	[view setPriority:prio];
	[view setTitle:title];//isHTML:titleHTML];
	[view setText:text];// isHTML:textHTML];
	[view setIcon:icon];
	//[view sizeToFit];

	NSRect viewFrame = [view frame];
	[panel setFrame:viewFrame display:NO];
	NSRect screen = [[self screen] visibleFrame];
	[panel setFrameOrigin:NSMakePoint( NSMinX(screen), NSMaxY(screen))];
}

- (unsigned) depth {
	return depth;
}

- (void) setDisplayMode:(BOOL)mode {
#pragma unused(mode)
}

#pragma mark -

- (void) dealloc {
	NSWindow *myWindow = [self window];
	[[myWindow contentView] release];
	[identifier  release];
	[myWindow    release];
	[super dealloc];
}

#pragma mark Accessors

- (NSString *) identifier {
	return identifier;
}

@end
