//
//  GrowlMusicVideoWindowController.m
//  Display Plugins
//
//  Created by Jorge Salvador Caffarena on 09/09/04.
//  Copyright 2004 Jorge Salvador Caffarena. All rights reserved.
//

#import <GrowlPlugins/GrowlFadingWindowTransition.h>
#import <GrowlPlugins/GrowlSlidingWindowTransition.h>
#import <GrowlPlugins/GrowlWipeWindowTransition.h>
#import <GrowlPlugins/GrowlNotification.h>
#import "GrowlMusicVideoWindowController.h"
#import "GrowlMusicVideoWindowView.h"
#import "GrowlMusicVideoPrefs.h"

@implementation GrowlMusicVideoWindowController

- (id) initWithNotification:(GrowlNotification *)note plugin:(GrowlDisplayPlugin *)aPlugin {
	NSDictionary *configDict = [note configurationDict];
	

	screenNumber = 0U;
	if([configDict valueForKey:MUSICVIDEO_SCREEN_PREF]){
		screenNumber = [[configDict valueForKey:MUSICVIDEO_SIZE_PREF] unsignedIntValue];
	}
	NSArray *screens = [NSScreen screens];
	NSUInteger screensCount = [screens count];
	if (screensCount) {
		[self setScreen:((screensCount >= (screenNumber + 1)) ? [screens objectAtIndex:screenNumber] : [screens objectAtIndex:0])];
	}
	
	NSRect sizeRect;
	NSRect screen = [[self screen] frame];
	int sizePref = MUSICVIDEO_SIZE_NORMAL;
	if([configDict valueForKey:MUSICVIDEO_SIZE_PREF]){
		sizePref = [[configDict valueForKey:MUSICVIDEO_SIZE_PREF] intValue];
	}
	sizeRect.origin = screen.origin;
	sizeRect.size.width = screen.size.width;
	if (sizePref == MUSICVIDEO_SIZE_HUGE)
		sizeRect.size.height = 192.0;
	else
		sizeRect.size.height = 96.0;
	frameHeight = sizeRect.size.height;

	NSPanel *panel = [[NSPanel alloc] initWithContentRect:sizeRect
												styleMask:NSBorderlessWindowMask
												  backing:NSBackingStoreBuffered
													defer:YES];
	NSRect panelFrame = [panel frame];
	[panel setBecomesKeyOnlyIfNeeded:YES];
	[panel setHidesOnDeactivate:NO];
	[panel setBackgroundColor:[NSColor clearColor]];
	[panel setLevel:GrowlVisualDisplayWindowLevel];
	[panel setIgnoresMouseEvents:YES];
	[panel setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces];
	[panel setOpaque:NO];
	[panel setHasShadow:NO];
	[panel setCanHide:NO];
	[panel setOneShot:YES];
	[panel useOptimizedDrawing:YES];
	[panel setDelegate:self];

	GrowlMusicVideoWindowView *view = [[GrowlMusicVideoWindowView alloc] initWithFrame:panelFrame];

	[view setTarget:self];
	[view setAction:@selector(notificationClicked:)]; // Not used for now

	[panel setContentView:view]; // retains subview
	[view release];

	[panel setFrameTopLeftPoint:screen.origin];

	// call super so everything else is set up...
	if ((self = [super initWithWindow:panel andPlugin:aPlugin])) {
		
		NSTimeInterval duration = GrowlMusicVideoDurationPrefDefault;
		if([configDict valueForKey:MUSICVIDEO_DURATION_PREF]){
			duration = [[configDict valueForKey:MUSICVIDEO_DURATION_PREF] floatValue];
		}
		self.displayDuration = duration;
		
		//The default duration for transitions is far too long for the music video effect.
		[self setTransitionDuration:0.3];

		MusicVideoEffectType effect = MUSICVIDEO_EFFECT_SLIDE;
		if([configDict valueForKey:MUSICVIDEO_EFFECT_PREF]){
			effect = [[configDict valueForKey:MUSICVIDEO_EFFECT_PREF] intValue];
		}
		switch (effect)
		{
			case MUSICVIDEO_EFFECT_SLIDE:
			{
				//slider effect
				GrowlSlidingWindowTransition *slider = [[GrowlSlidingWindowTransition alloc] initWithWindow:panel];
				[slider setFromOrigin:NSMakePoint(NSMinX(screen),NSMinY(screen)-frameHeight) toOrigin:NSMakePoint(NSMinX(screen),NSMinY(screen))];
				[self setStartPercentage:0 endPercentage:100 forTransition:slider];
				[slider setAutoReverses:YES];
				[self addTransition:slider];
				[slider release];
				break;
			}
			case MUSICVIDEO_EFFECT_FADING:
			{
				GrowlFadingWindowTransition *fader = [[GrowlFadingWindowTransition alloc] initWithWindow:panel];
				[self addTransition:fader];
				[self setStartPercentage:0 endPercentage:100 forTransition:fader];
				[fader setAutoReverses:YES];
				[fader release];
				
				// I am adding in a sliding transition from screen,screen to screen,screen to make sure the window is properly positioned during the animation - swr
				GrowlSlidingWindowTransition *slider = [[GrowlSlidingWindowTransition alloc] initWithWindow:panel];
				[slider setFromOrigin:NSMakePoint(NSMinX(screen),NSMinY(screen)) toOrigin:NSMakePoint(NSMinX(screen),NSMinY(screen))];
				[self setStartPercentage:0 endPercentage:100 forTransition:slider];
				[slider setAutoReverses:YES];
				[self addTransition:slider];
				[slider release];
				break;
			}
			case MUSICVIDEO_EFFECT_WIPE:
			{
				NSLog(@"Wipe not implemented");
				//wipe effect
				//[panel setFrameOrigin:NSMakePoint( 0, 0)];
				//GrowlWipeWindowTransition *wiper = [[GrowlWipeWindowTransition alloc] initWithWindow:panel];
				// save for scale effect [wiper setFromOrigin:NSMakePoint(0,0) toOrigin:NSMakePoint(NSMaxX(screen), frameHeight)];
				//[wiper setFromOrigin:NSMakePoint(NSMaxX(screen), 0) toOrigin:NSMakePoint(NSMaxX(screen), frameHeight)];
				//[self setStartPercentage:0 endPercentage:100 forTransition:wiper];
				//[wiper setAutoReverses:YES];
				//[self addTransition:wiper];
				//[wiper release];
				break;
			}
		}
	}
	
	[panel release];
	
	return self;

}

@end
