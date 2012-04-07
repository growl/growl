//
//  GrowlBrushedWindowController.m
//  Display Plugins
//
//  Created by Ingmar Stein on 12/01/2004.
//  Copyright 2004–2011 The Growl Project. All rights reserved.
//
//  Most of this is lifted from KABubbleWindowController in the Growl source

#import <GrowlPlugins/GrowlNotification.h>
#import <GrowlPlugins/GrowlWindowtransition.h>
#import <GrowlPlugins/GrowlFadingWindowTransition.h>
#import "GrowlBrushedWindowController.h"
#import "GrowlBrushedWindowView.h"
#import "GrowlBrushedDefines.h"
#import "GrowlDefinesInternal.h"

@implementation GrowlBrushedWindowController

//static const double gAdditionalLinesDisplayTime = 0.5;

- (id) initWithNotification:(GrowlNotification *)note plugin:(GrowlDisplayPlugin *)aPlugin {
	// Read prefs...
	screenNumber = 0U;
	NSDictionary *configDict = [note configurationDict];
	if([configDict valueForKey:GrowlBrushedScreenPref]){
		screenNumber = [[configDict valueForKey:GrowlBrushedScreenPref] unsignedIntegerValue];
	}
	NSArray *screens = [NSScreen screens];
	NSUInteger screensCount = [screens count];
	if (screensCount) {
		[self setScreen:((screensCount >= (screenNumber + 1)) ? [screens objectAtIndex:screenNumber] : [screens objectAtIndex:0])];
	}
	unsigned styleMask = NSBorderlessWindowMask | NSNonactivatingPanelMask;

	BOOL aquaPref = GrowlBrushedAquaPrefDefault;
	if([configDict valueForKey:GrowlBrushedAquaPref]){
		aquaPref = [[configDict valueForKey:GrowlBrushedAquaPref] boolValue];
	}
	if (!aquaPref) {
		styleMask |= NSTexturedBackgroundWindowMask;
	}

	NSTimeInterval duration = GrowlBrushedDurationPrefDefault;
	if([configDict valueForKey:GrowlBrushedDurationPref]){
		duration = [[configDict valueForKey:GrowlBrushedDurationPref] floatValue];
	}
	self.displayDuration = duration;

	// Create window...
	NSRect windowFrame = NSMakeRect(0.0, 0.0, GrowlBrushedNotificationWidth, 65.0);
	NSPanel *panel = [[NSPanel alloc] initWithContentRect:windowFrame
												styleMask:styleMask
												  backing:NSBackingStoreBuffered
													defer:YES];
	NSRect panelFrame = [panel frame];
	[panel setBecomesKeyOnlyIfNeeded:YES];
	[panel setHidesOnDeactivate:NO];
	[panel setLevel:GrowlVisualDisplayWindowLevel];
	[panel setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces];
	[panel setAlphaValue:0.0];
	[panel setOpaque:NO];
	[panel setHasShadow:YES];
	[panel setCanHide:NO];
	[panel setOneShot:YES];
	[panel useOptimizedDrawing:YES];
	[panel setMovableByWindowBackground:NO];

	// Create the content view...
	GrowlBrushedWindowView *view = [[GrowlBrushedWindowView alloc] initWithFrame:panelFrame configurationDict:configDict];
	[view setTarget:self];
	[view setAction:@selector(notificationClicked:)];
	[panel setContentView:view];
	[view release];

	panelFrame = [view frame];
	[panel setFrame:panelFrame display:NO];

	// call super so everything else is set up...
	if ((self = [super initWithWindow:panel andPlugin:aPlugin])) {
		// set up the transitions...
		GrowlFadingWindowTransition *fader = [[GrowlFadingWindowTransition alloc] initWithWindow:panel];
		[self setStartPercentage:0 endPercentage:100 forTransition:fader];
		[fader setAutoReverses:YES];
		[self addTransition:fader];
		[fader release];
	}
	[panel release];

	return self;
}

- (CGFloat) requiredDistanceFromExistingDisplays {
	return GrowlBrushedPadding;
}


@end
