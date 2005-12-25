//
//  GrowlBrushedWindowController.m
//  Display Plugins
//
//  Created by Ingmar Stein on 12/01/2004.
//  Copyright 2004-2005 The Growl Project. All rights reserved.
//
//  Most of this is lifted from KABubbleWindowController in the Growl source

#import "GrowlBrushedWindowController.h"
#import "GrowlBrushedWindowView.h"
#import "GrowlBrushedDefines.h"
#import "GrowlDefinesInternal.h"
#import "GrowlApplicationNotification.h"
#import "NSWindow+Transforms.h"
#import "GrowlWindowTransition.h"
#import "GrowlFadingWindowTransition.h"
#include "CFDictionaryAdditions.h"

@implementation GrowlBrushedWindowController

static const double gAdditionalLinesDisplayTime = 0.5;

- (id) init {
	// Read prefs...
	screenNumber = 0U;
	READ_GROWL_PREF_INT(GrowlBrushedScreenPref, GrowlBrushedPrefDomain, &screenNumber);
	[self setScreen:[[NSScreen screens] objectAtIndex:screenNumber]];
	NSRect screen = [[self screen] visibleFrame];
	unsigned styleMask = NSBorderlessWindowMask | NSNonactivatingPanelMask;
	
	BOOL aquaPref = GrowlBrushedAquaPrefDefault;
	READ_GROWL_PREF_BOOL(GrowlBrushedAquaPref, GrowlBrushedPrefDomain, &aquaPref);
	if (!aquaPref) {
		styleMask |= NSTexturedBackgroundWindowMask;
	}

	CFNumberRef prefsDuration = NULL;
	CFTimeInterval value = -1.0f;

	displayDuration = GrowlBrushedDurationPrefDefault;
	READ_GROWL_PREF_VALUE(GrowlBrushedDurationPref, GrowlBrushedPrefDomain, CFNumberRef, &prefsDuration);
	if(prefsDuration) {
		CFNumberGetValue(prefsDuration, kCFNumberDoubleType, &value);
		if (value > 0.0f)
			displayDuration = value;
	}	
	
	// Create window...
	NSRect windowFrame = NSMakeRect(0.0f, 0.0f, GrowlBrushedNotificationWidth, 65.0f);
	NSPanel *panel = [[NSPanel alloc] initWithContentRect:windowFrame										
												styleMask:styleMask
												  backing:NSBackingStoreBuffered
													defer:NO];
	NSRect panelFrame = [panel frame];
	[panel setBecomesKeyOnlyIfNeeded:YES];
	[panel setHidesOnDeactivate:NO];
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
	GrowlBrushedWindowView *view = [[GrowlBrushedWindowView alloc] initWithFrame:panelFrame];
	[view setTarget:self];
	[view setAction:@selector(notificationClicked:)];
	[view setDelegate:self];
	[view setCloseOnMouseExit:YES];
	[panel setContentView:view];
	
	panelFrame = [view frame];
	[panel setFrame:panelFrame display:NO];
	[panel setFrameTopLeftPoint:NSMakePoint(NSMaxX(screen) - NSWidth(panelFrame) - GrowlBrushedPadding,
											NSMaxY(screen) - GrowlBrushedPadding - depth)];
	
	// call super so everything else is set up...
	self = [super initWithWindow:panel];
	if (!self)
		return nil;
	
	// set up the transitions...
	GrowlFadingWindowTransition *fader = [[GrowlFadingWindowTransition alloc] initWithWindow:panel];
	[self setStartPercentage:0 endPercentage:100 forTransition:fader];
	[fader setAutoReverses:YES];
	[self addTransition:fader];
	[fader release];
	
	return self;
}

- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	//extern unsigned BrushedWindowDepth;
	//if ( depth == brushedWindowDepth )
	// 	brushedWindowDepth = 0;

	NSWindow *myWindow = [self window];
	[[myWindow contentView] release];
	[myWindow release];
	[identifier release];

	[super dealloc];
}

#pragma mark -

- (unsigned) depth {
	return depth;
}

- (void) setNotification: (GrowlApplicationNotification *) theNotification {
	[super setNotification:theNotification];
	if (!theNotification)
		return;
	
	NSDictionary *noteDict = [notification dictionaryRepresentation];
	NSString *title = [notification HTMLTitle];
	NSString *text  = [notification HTMLDescription];
	NSImage *icon   = getObjectForKey(noteDict, GROWL_NOTIFICATION_ICON);
	int priority    = getIntegerForKey(noteDict, GROWL_NOTIFICATION_PRIORITY);
#warning commented out due to an indication that they are not being used
	//BOOL sticky     = getBooleanForKey(noteDict, GROWL_NOTIFICATION_STICKY);
	//NSString *ident = getObjectForKey(noteDict, GROWL_NOTIFICATION_IDENTIFIER);
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
	GrowlBrushedWindowView *view = [[self window] contentView];
	[view setPriority:priority];
	[view setTitle:title isHTML:titleHTML];
	[view setText:text isHTML:textHTML];
	[view setIcon:icon];
	[view sizeToFit];
	
	NSRect viewFrame = [view frame];
	[panel setFrame:viewFrame display:NO];
	NSRect screen = [[self screen] visibleFrame];
	[panel setFrameTopLeftPoint:NSMakePoint(NSMaxX(screen) - NSWidth(viewFrame) - GrowlBrushedPadding,
											NSMaxY(screen) - GrowlBrushedPadding - depth)];
}

- (NSPoint) idealOriginInRect:(NSRect)rect {
	NSRect viewFrame = [[[self window] contentView] frame];
	return NSMakePoint(NSMaxX(rect) - NSWidth(viewFrame) - GrowlBrushedPadding,
					   NSMaxY(rect) - GrowlBrushedPadding - NSHeight(viewFrame));
}

- (GrowlExpansionDirection) primaryExpansionDirection {
	return GrowlDownExpansionDirection;
}

- (GrowlExpansionDirection) secondaryExpansionDirection {
	return GrowlLeftExpansionDirection;
}

- (float) requiredDistanceFromExistingDisplays {
	return GrowlBrushedPadding;
}


@end
