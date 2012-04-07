//
//  GrowlBubblesWindowController.m
//  Growl
//
//  Created by Nelson Elhage on Wed Jun 09 2004.
//  Name changed from KABubbleWindowController.m by Justin Burns on Fri Nov 05 2004.
//  Copyright (c) 2004–2011 The Growl Project. All rights reserved.
//

#import <GrowlPlugins/GrowlNotification.h>
#import <GrowlPlugins/GrowlWindowtransition.h>
#import <GrowlPlugins/GrowlFadingWindowTransition.h>
#import "GrowlBubblesWindowController.h"
#import "GrowlBubblesWindowView.h"
#import "GrowlBubblesPrefsController.h"
#import "GrowlBubblesDefines.h"
#import "GrowlPositionController.h"

@implementation GrowlBubblesWindowController

#define GrowlBubblesPadding				5.0

#pragma mark -

- (id) initWithNotification:(GrowlNotification *)note plugin:(GrowlDisplayPlugin *)aPlugin {
	NSDictionary *configDict = [note configurationDict];
	
	screenNumber = 0U;
	if([configDict valueForKey:GrowlBubblesScreen]){
		screenNumber = [[configDict valueForKey:GrowlBubblesScreen] unsignedIntValue];
	}
	NSArray *screens = [NSScreen screens];
	NSUInteger screensCount = [screens count];
	if (screensCount) {
		[self setScreen:((screensCount >= (screenNumber + 1)) ? [screens objectAtIndex:screenNumber] : [screens objectAtIndex:0])];
	}
	
	NSTimeInterval duration = GrowlBubblesDurationPrefDefault;
	if([configDict valueForKey:GrowlBubblesDuration]){
		duration = [[configDict valueForKey:GrowlBubblesDuration] floatValue];
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
	GrowlBubblesWindowView *view = [[GrowlBubblesWindowView alloc] initWithFrame:panelFrame configurationDict:configDict];
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
	return GrowlBubblesPadding;
}

@end
