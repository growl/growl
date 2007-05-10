//
//  GrowlSmokeWindowController.m
//  Display Plugins
//
//  Created by Matthew Walton on 11/09/2004.
//  Copyright 2004-2006 The Growl Project. All rights reserved.
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

@implementation GrowlSmokeWindowController

//static const double gAdditionalLinesDisplayTime = 0.5;
//static const double gMaxDisplayTime = 10.0;

- (id) init {
	screenNumber = 0U;
	READ_GROWL_PREF_INT(GrowlSmokeScreenPref, GrowlSmokePrefDomain, &screenNumber);
	[self setScreen:[[NSScreen screens] objectAtIndex:screenNumber]];

	CFNumberRef prefsDuration = NULL;
	CFTimeInterval value = -1.0f;

	displayDuration = GrowlSmokeDurationPrefDefault;
	READ_GROWL_PREF_VALUE(GrowlSmokeDurationPref, GrowlSmokePrefDomain, CFNumberRef, &prefsDuration);
	if (prefsDuration) {
		CFNumberGetValue(prefsDuration, kCFNumberDoubleType, &value);
		if (value > 0.0f)
			displayDuration = value;
	}

	NSPanel *panel = [[NSPanel alloc] initWithContentRect:NSMakeRect(0.0f, 0.0f, GrowlSmokeNotificationWidth, 65.0f)
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

	GrowlSmokeWindowView *view = [[GrowlSmokeWindowView alloc] initWithFrame:panelFrame];
	[view setTarget:self];
	[view setAction:@selector(notificationClicked:)];
	[view setDelegate:self];
	[panel setContentView:view];
	[view release];

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
	[myWindow release];

	[super dealloc];
}

#pragma mark -
- (void) setNotification:(GrowlApplicationNotification *)theNotification {
	[super setNotification:theNotification];
	if (!theNotification)
		return;

	NSDictionary *noteDict = [notification dictionaryRepresentation];
	NSString *title = [notification title];
	NSString *text  = [notification notificationDescription];
	NSImage *icon   = getObjectForKey(noteDict, GROWL_NOTIFICATION_ICON);
	int priority    = getIntegerForKey(noteDict, GROWL_NOTIFICATION_PRIORITY);

	GrowlSmokeWindowView *view = [[self window] contentView];
	[view setPriority:priority];
	[view setTitle:title];
	[view setText:text];
	[view setIcon:icon];
	[view sizeToFit];
}

- (void) stopDisplay {
	GrowlSmokeWindowView *view = (GrowlSmokeWindowView *)[[self window] contentView];
	if ([view mouseOver])
		[view setCloseOnMouseExit:YES];
	else
		[super stopDisplay];
}

#pragma mark -
#pragma mark positioning methods

- (NSPoint) idealOriginInRect:(NSRect)rect {
	NSRect viewFrame = [[[self window] contentView] frame];
	enum GrowlPosition originatingPosition = [[GrowlPositionController sharedInstance] originPosition];
	NSPoint idealOrigin;
	
	switch(originatingPosition){
		case GrowlTopRightPosition:
			idealOrigin = NSMakePoint(NSMaxX(rect) - NSWidth(viewFrame) - GrowlSmokePadding,
									  NSMaxY(rect) - GrowlSmokePadding - NSHeight(viewFrame));
			break;
		case GrowlTopLeftPosition:
			idealOrigin = NSMakePoint(NSMinX(rect) + GrowlSmokePadding,
									  NSMaxY(rect) - GrowlSmokePadding - NSHeight(viewFrame));
			break;
		case GrowlBottomLeftPosition:
			idealOrigin = NSMakePoint(NSMinX(rect) + GrowlSmokePadding,
									  NSMinY(rect) + GrowlSmokePadding);
			break;
		case GrowlBottomRightPosition:
			idealOrigin = NSMakePoint(NSMaxX(rect) - NSWidth(viewFrame) - GrowlSmokePadding,
									  NSMinY(rect) + GrowlSmokePadding);
			break;
		default:
			idealOrigin = NSMakePoint(NSMaxX(rect) - NSWidth(viewFrame) - GrowlSmokePadding,
									  NSMaxY(rect) - GrowlSmokePadding - NSHeight(viewFrame));
			break;			
	}
	
	return idealOrigin;	
}

- (enum GrowlExpansionDirection) primaryExpansionDirection {
	enum GrowlPosition originatingPosition = [[GrowlPositionController sharedInstance] originPosition];
	enum GrowlExpansionDirection directionToExpand;
	
	switch(originatingPosition){
		case GrowlTopLeftPosition:
			directionToExpand = GrowlDownExpansionDirection;
			break;
		case GrowlTopRightPosition:
			directionToExpand = GrowlDownExpansionDirection;
			break;
		case GrowlBottomLeftPosition:
			directionToExpand = GrowlUpExpansionDirection;
			break;
		case GrowlBottomRightPosition:
			directionToExpand = GrowlUpExpansionDirection;
			break;
		default:
			directionToExpand = GrowlDownExpansionDirection;
			break;			
	}
	
	return directionToExpand;
}

- (enum GrowlExpansionDirection) secondaryExpansionDirection {
	enum GrowlPosition originatingPosition = [[GrowlPositionController sharedInstance] originPosition];
	enum GrowlExpansionDirection directionToExpand;
	
	switch(originatingPosition){
		case GrowlTopLeftPosition:
			directionToExpand = GrowlRightExpansionDirection;
			break;
		case GrowlTopRightPosition:
			directionToExpand = GrowlLeftExpansionDirection;
			break;
		case GrowlBottomLeftPosition:
			directionToExpand = GrowlRightExpansionDirection;
			break;
		case GrowlBottomRightPosition:
			directionToExpand = GrowlLeftExpansionDirection;
			break;
		default:
			directionToExpand = GrowlRightExpansionDirection;
			break;
	}
	
	return directionToExpand;
}

- (float) requiredDistanceFromExistingDisplays {
	return GrowlSmokePadding;
}

@end
