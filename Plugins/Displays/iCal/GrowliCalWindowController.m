//
//  GrowliCalWindowController.m
//  Growl
//
//  Created by Nelson Elhage on Wed Jun 09 2004.
//  Name changed from KABubbleWindowController.m by Justin Burns on Fri Nov 05 2004.
//	Adapted for iCal by Takumi Murayama on Thu Aug 17 2006.
//  Copyright (c) 2004–2011 The Growl Project. All rights reserved.
//

#import <GrowlPlugins/GrowlNotification.h>
#import <GrowlPlugins/GrowlWindowtransition.h>
#import <GrowlPlugins/GrowlFadingWindowTransition.h>
#import "GrowliCalWindowController.h"
#import "GrowliCalWindowView.h"
#import "GrowliCalPrefsController.h"
#import "GrowliCalDefines.h"

@implementation GrowliCalWindowController

#define GrowliCalPadding				5.0

#pragma mark -

- (id) initWithNotification:(GrowlNotification *)note plugin:(GrowlDisplayPlugin *)aPlugin {
	NSDictionary *configDict = [notification configurationDict];
	screenNumber = 0U;
	if([configDict valueForKey:GrowliCalScreen]){
		screenNumber = [[configDict valueForKey:GrowliCalScreen] unsignedIntegerValue];
	}
	NSArray *screens = [NSScreen screens];
	NSUInteger screensCount = [screens count];
	if (screensCount) {
		[self setScreen:((screensCount >= (screenNumber + 1)) ? [screens objectAtIndex:screenNumber] : [screens objectAtIndex:0])];
	}

	NSTimeInterval duration = GrowliCalDurationPrefDefault;
	if([configDict valueForKey:GrowliCalDuration]){
		duration = [[configDict valueForKey:GrowliCalDuration] floatValue];
	}
	self.displayDuration = duration;

	// I tried setting the width/height to zero, since the view resizes itself later.
	// This made it ignore the alpha at the edges (using 1.0 instead). Why?
	// A window with a frame of NSZeroRect is off-screen and doesn't respect opacity even
	// if moved on screen later. -Evan
	NSPanel *panel = [[NSPanel alloc] initWithContentRect:NSMakeRect(0.0, 0.0, 270.0, 65.0)
												styleMask:NSBorderlessWindowMask | NSNonactivatingPanelMask
												  backing:NSBackingStoreBuffered
													defer:YES];
	NSRect panelFrame = [panel frame];
	[panel setBecomesKeyOnlyIfNeeded:YES];
	[panel setHidesOnDeactivate:NO];
	[panel setBackgroundColor:[NSColor clearColor]];
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
	GrowliCalWindowView *view = [[GrowliCalWindowView alloc] initWithFrame:panelFrame configurationDict:configDict];
	[view setTarget:self];
	[view setAction:@selector(notificationClicked:)];
	[panel setContentView:view];
	[view release];

	// call super so everything else is set up...
	if ((self = [super initWithWindow:panel andPlugin:aPlugin])) {
		// set up the transitions...
		GrowlFadingWindowTransition *fader = [[GrowlFadingWindowTransition alloc] initWithWindow:panel];
		[self addTransition:fader];
		[self setStartPercentage:0 endPercentage:100 forTransition:fader];
		[fader setAutoReverses:YES];
		[fader release];
	}
	
	[panel release];

	return self;
}

#pragma mark -
#pragma mark positioning methods

- (CGFloat) requiredDistanceFromExistingDisplays {
	return GrowliCalPadding;
}

@end
