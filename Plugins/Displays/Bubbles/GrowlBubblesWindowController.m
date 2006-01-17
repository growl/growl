//
//  GrowlBubblesWindowController.m
//  Growl
//
//  Created by Nelson Elhage on Wed Jun 09 2004.
//  Name changed from KABubbleWindowController.m by Justin Burns on Fri Nov 05 2004.
//  Copyright (c) 2004-2005 The Growl Project. All rights reserved.
//

#import "GrowlBubblesWindowController.h"
#import "GrowlBubblesWindowView.h"
#import "GrowlBubblesPrefsController.h"
#import "GrowlBubblesDefines.h"
#import "GrowlApplicationNotification.h"
#import "NSWindow+Transforms.h"
#include "CFDictionaryAdditions.h"
#import "GrowlWindowTransition.h"
#import "GrowlFadingWindowTransition.h"

@implementation GrowlBubblesWindowController

#define MIN_DISPLAY_TIME				4.0
#define ADDITIONAL_LINES_DISPLAY_TIME	0.5
#define MAX_DISPLAY_TIME				10.0
#define GrowlBubblesPadding				5.0f

#pragma mark -

- (id) init {
	screenNumber = 0U;
	READ_GROWL_PREF_INT(GrowlBubblesScreen, GrowlBubblesPrefDomain, &screenNumber);
	[self setScreen:[[NSScreen screens] objectAtIndex:screenNumber]];

	displayDuration = GrowlBubblesDurationPrefDefault;
	CFNumberRef prefsDuration = NULL;
	CFTimeInterval value = -1.0f;
	READ_GROWL_PREF_VALUE(GrowlBubblesDuration, GrowlBubblesPrefDomain, CFNumberRef, &prefsDuration);
	if (prefsDuration) {
		CFNumberGetValue(prefsDuration, kCFNumberDoubleType, &value);
		//NSLog(@"%lf\n", value);
		if (value > 0.0f)
			displayDuration = value;
	}
	// I tried setting the width/height to zero, since the view resizes itself later.
	// This made it ignore the alpha at the edges (using 1.0 instead). Why?
	// A window with a frame of NSZeroRect is off-screen and doesn't respect opacity even
	// if moved on screen later. -Evan
	NSPanel *panel = [[NSPanel alloc] initWithContentRect:NSMakeRect(0.0f, 0.0f, 270.0f, 65.0f)
												styleMask:NSBorderlessWindowMask | NSNonactivatingPanelMask
												  backing:NSBackingStoreBuffered
													defer:YES];
	NSRect panelFrame = [panel frame];
	[panel setBecomesKeyOnlyIfNeeded:YES];
	[panel setHidesOnDeactivate:NO];
	[panel setBackgroundColor:[NSColor clearColor]];
	[panel setLevel:NSStatusWindowLevel];
	[panel setSticky:YES];
	[panel setAlphaValue:0.0f];
	[panel setOpaque:NO];
	[panel setHasShadow:YES];
	[panel setCanHide:NO];
	[panel setOneShot:YES];
	[panel useOptimizedDrawing:YES];
	[panel setMovableByWindowBackground:NO];

	// Create the content view...
	GrowlBubblesWindowView *view = [[GrowlBubblesWindowView alloc] initWithFrame:panelFrame];
	[view setTarget:self];
	[view setAction:@selector(notificationClicked:)];
	[view setDelegate:self];
	[view setCloseOnMouseExit:YES];
	[panel setContentView:view];

	// call super so everything else is set up...
	if ((self = [super initWithWindow:panel])) {
		// set up the transitions...
		GrowlFadingWindowTransition *fader = [[GrowlFadingWindowTransition alloc] initWithWindow:panel];
		[self addTransition:fader];
		[self setStartPercentage:0 endPercentage:100 forTransition:fader];
		[fader setAutoReverses:YES];
		[fader release];
	}

	return self;
}

- (void) dealloc {
	NSWindow *myWindow = [self window];
	[[myWindow contentView] release];
	[myWindow release];
	[identifier release];

	[super dealloc];
}

#pragma mark -

- (void) setNotification: (GrowlApplicationNotification *) theNotification {
	[super setNotification:theNotification];
	if (!theNotification)
		return;

	NSDictionary *noteDict = [notification dictionaryRepresentation];
	NSString *title = [notification HTMLTitle];
	NSString *text  = [notification HTMLDescription];
	NSImage *icon   = getObjectForKey(noteDict, GROWL_NOTIFICATION_ICON);
	int priority    = getIntegerForKey(noteDict, GROWL_NOTIFICATION_PRIORITY);
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
	GrowlBubblesWindowView *view = [[self window] contentView];
	[view setPriority:priority];
	[view setTitle:title isHTML:titleHTML];
	[view setText:text isHTML:textHTML];
	[view setIcon:icon];
	[view sizeToFit];
	[panel setFrame:[view frame] display:NO];
}

#pragma mark -
#pragma mark positioning methods

- (NSPoint) idealOriginInRect:(NSRect)rect {
	NSRect viewFrame = [[[self window] contentView] frame];
	return NSMakePoint(NSMaxX(rect) - NSWidth(viewFrame) - GrowlBubblesPadding,
					   NSMaxY(rect) - GrowlBubblesPadding - NSHeight(viewFrame));
}

- (GrowlExpansionDirection) primaryExpansionDirection {
	return GrowlDownExpansionDirection;
}

- (GrowlExpansionDirection) secondaryExpansionDirection {
	return GrowlLeftExpansionDirection;
}

- (float) requiredDistanceFromExistingDisplays {
	return GrowlBubblesPadding;
}

@end
