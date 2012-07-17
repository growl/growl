//
//  GrowlNanoWindowController.m
//  Display Plugins
//
//  Created by Rudy Richter on 12/12/2005.
//  Copyright 2005-2011, The Growl Project, LLC. All rights reserved.
//


#import <GrowlPlugins/GrowlSlidingWindowTransition.h>
#import <GrowlPlugins/GrowlWipeWindowTransition.h>
#import <GrowlPlugins/GrowlFadingWindowTransition.h>
#import <GrowlPlugins/NSScreen+GrowlScreenAdditions.h>
#import "GrowlNanoWindowController.h"
#import "GrowlNanoWindowView.h"
#import "GrowlNanoPrefs.h"

#import <GrowlPlugins/GrowlNotification.h>

@implementation GrowlNanoWindowController

- (id) initWithNotification:(GrowlNotification *)note plugin:(GrowlDisplayPlugin *)aPlugin {
	NSDictionary *configDict = [note configurationDict];
	//define our duration
	
	NSTimeInterval duration = GrowlNanoDurationPrefDefault;
	if([configDict valueForKey:Nano_DURATION_PREF]){
		duration = [[configDict valueForKey:Nano_DURATION_PREF] floatValue];
	}
	self.displayDuration = duration;

	screenNumber = 0U;
	if([configDict valueForKey:Nano_SCREEN_PREF]){
		screenNumber = [[configDict valueForKey:Nano_SCREEN_PREF] unsignedIntValue];
	}
	NSArray *screens = [NSScreen screens];
	NSUInteger screensCount = [screens count];
	if (screensCount) {
		[self setScreen:((screensCount >= (screenNumber + 1)) ? [screens objectAtIndex:screenNumber] : [screens objectAtIndex:0])];
	}
				 
	NSRect sizeRect;
	NSRect screen = [[self screen] frame];
	int sizePref = Nano_SIZE_NORMAL;
	if([configDict valueForKey:Nano_SIZE_PREF]){
		sizePref = [[configDict valueForKey:Nano_SIZE_PREF] intValue];
	}
	sizeRect.origin = screen.origin;
	if (sizePref == Nano_SIZE_HUGE) {
		sizeRect.size.height = 50.0;	
		sizeRect.size.width = 270.0;
	} else {
		sizeRect.size.height = 25.0;
		sizeRect.size.width = 185.0;
	}
	frameHeight = sizeRect.size.height;

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
	[panel setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces];
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

	// call super so everything else is set up...
	if ((self = [super initWithWindow:panel andPlugin:aPlugin])) {
		NanoEffectType effect = Nano_EFFECT_SLIDE;
		if([configDict valueForKey:Nano_EFFECT_PREF]){
			effect = [[configDict valueForKey:Nano_EFFECT_PREF] intValue];
		}
		
		self.notification = note;
		[panel setFrameOrigin:[self idealOriginInRect:screen]];
		CGFloat xPosition = panel.frame.origin.x;
		CGFloat yPosition = panel.frame.origin.y;	
		
		switch (effect) {
			case Nano_EFFECT_SLIDE:
			{
				//slider effect
				GrowlSlidingWindowTransition *slider = [[GrowlSlidingWindowTransition alloc] initWithWindow:panel];
				[slider setFromOrigin:panel.frame.origin toOrigin:NSMakePoint(xPosition, yPosition - frameHeight)];
				[slider setAutoReverses:YES];
				[self addTransition:slider];
				[self setStartPercentage:0 endPercentage:100 forTransition:slider];
				
				[slider release];
				
				break;
			}
			case Nano_EFFECT_WIPE:
			{
				//wipe effect
				[panel setFrameOrigin:NSMakePoint(xPosition, NSMaxY(screen))];
				GrowlWipeWindowTransition *wiper = [[GrowlWipeWindowTransition alloc] initWithWindow:panel];
				[wiper setFromOrigin:panel.frame.origin toOrigin:NSMakePoint(xPosition, yPosition - frameHeight)];
				[wiper setAutoReverses:YES];
				[self addTransition:wiper];
				[self setStartPercentage:0 endPercentage:100 forTransition:wiper];
				
				[wiper release];
				
				NSLog(@"Wipe not implemented");
				break;
			}
			case Nano_EFFECT_FADE:
			{
				[panel setAlphaValue:0.0];
				[panel setFrameOrigin:NSMakePoint(xPosition, yPosition - frameHeight)];
				
				GrowlFadingWindowTransition *fader = [[GrowlFadingWindowTransition alloc] initWithWindow:panel];
				[self addTransition:fader];
				[self setStartPercentage:0 endPercentage:100 forTransition:fader];
				[fader setAutoReverses:YES];
				[fader release];
				break;
			}
		}
	}
	
	[panel release];
	
	return self;
}


-(CGPoint)idealOriginInRect:(CGRect)rect {
	NanoPosition position = Nano_POSITION_DEFAULT;
	if([[self configurationDict] valueForKey:Nano_POSITION_PREF]){
		position = (unsigned int)[[[self configurationDict] valueForKey:Nano_POSITION_PREF] unsignedIntegerValue];
	}

	CGFloat xPosition;
	switch (position) {
		case Nano_POSITION_RIGHT:
			xPosition = NSMaxX(rect) - ([self window].frame.size.width + 50.0f);
			break;
		case Nano_POSITION_LEFT:
			xPosition = NSMinX(rect) + 50.0f;
			break;
		case Nano_POSITION_CENTER:
			xPosition = NSMinX(rect) + (rect.size.width / 2.0f) - ([self window].frame.size.width / 2.0);
			break;
	} 
	CGFloat yPosition = NSMaxY(rect);
	
	if([self screen] == [NSScreen mainScreen] && [NSMenu menuBarVisible])
		yPosition -= [[NSApp mainMenu] menuBarHeight];
	
	return CGPointMake(xPosition, yPosition);
}

-(NSString*)displayQueueKey {
	NanoPosition position = Nano_POSITION_DEFAULT;
	if([[self configurationDict] valueForKey:Nano_POSITION_PREF]){
		position = (unsigned int)[[[self configurationDict] valueForKey:Nano_POSITION_PREF] unsignedIntegerValue];
	}
	return [NSString stringWithFormat:@"nano-%@-%u", [[self screen] screenIDString], position];
}

@end
