//
//  GrowlSmokeWindowController.m
//  Display Plugins
//
//  Created by Matthew Walton on 11/09/2004.
//  Copyright 2004-2005 The Growl Project. All rights reserved.
//
//  Most of this is lifted from KABubbleWindowController in the Growl source

#import "GrowlSmokeWindowController.h"
#import "GrowlSmokeWindowView.h"
#import "GrowlSmokeDefines.h"
#import "GrowlDefinesInternal.h"
#import "NSWindow+Transforms.h"
#import "GrowlApplicationNotification.h"
#import "GrowlWindowTransition.h"
#import "GrowlFadingWindowTransition.h"
#include "CFDictionaryAdditions.h"

static unsigned globalId = 0U;

@implementation GrowlSmokeWindowController

static const double gAdditionalLinesDisplayTime = 0.5;
static const double gMaxDisplayTime = 10.0;
static NSMutableDictionary *notificationsByIdentifier;

- (id) init {
	unsigned screenNumber = 0U;
	READ_GROWL_PREF_INT(GrowlSmokeScreenPref, GrowlSmokePrefDomain, &screenNumber);
	[self setScreen:[[NSScreen screens] objectAtIndex:screenNumber]];

	CFNumberRef prefsDuration = NULL;
	CFTimeInterval value = -1.0f;

	displayDuration = GrowlSmokeDurationPrefDefault;
	READ_GROWL_PREF_VALUE(GrowlSmokeDurationPref, GrowlSmokePrefDomain, CFNumberRef, &prefsDuration);
	if(prefsDuration) {
		CFNumberGetValue(prefsDuration, kCFNumberDoubleType, &value);
		if (value > 0.0f)
			displayDuration = value;
	}	

	NSPanel *panel = [[NSPanel alloc] initWithContentRect:NSMakeRect(0.0f, 0.0f, GrowlSmokeNotificationWidth, 65.0f)
												styleMask:NSBorderlessWindowMask | NSNonactivatingPanelMask
												  backing:NSBackingStoreBuffered
													defer:NO];
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
	
	GrowlSmokeWindowView *view = [[GrowlSmokeWindowView alloc] initWithFrame:panelFrame];
	[view setTarget:self];
	[view setAction:@selector(notificationClicked:)];
	[view setDelegate:self];
	[view setCloseOnMouseExit:YES];
	[panel setContentView:view];

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
	
	return self;
}

- (void) dealloc {
#warning needs looking at
	//[[NSNotificationCenter defaultCenter] removeObserver:self];

	//extern unsigned smokeWindowDepth;
//	NSLog(@"smokeController deallocking");
	//if ( depth == smokeWindowDepth )
	// 	smokeWindowDepth = 0;

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
#warning commented out due to an indication that they're not being used
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
		text = [notification description];
	}
	
	NSPanel *panel = (NSPanel *)[self window];
	GrowlSmokeWindowView *view = [[self window] contentView];
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
	return NSMakePoint(NSMaxX(rect) - NSWidth(viewFrame) - GrowlSmokePadding,
					   NSMaxY(rect) - GrowlSmokePadding - NSHeight(viewFrame));
}

- (GrowlExpansionDirection) primaryExpansionDirection {
	return GrowlDownExpansionDirection;
}

- (GrowlExpansionDirection) secondaryExpansionDirection {
	return GrowlLeftExpansionDirection;
}

- (float) requiredDistanceFromExistingDisplays {
	return GrowlSmokePadding;
}

@end
