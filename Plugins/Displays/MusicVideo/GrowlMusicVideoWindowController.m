//
//  GrowlMusicVideoWindowController.m
//  Display Plugins
//
//  Created by Jorge Salvador Caffarena on 09/09/04.
//  Copyright 2004 Jorge Salvador Caffarena. All rights reserved.
//

#import "GrowlMusicVideoWindowController.h"
#import "GrowlMusicVideoWindowView.h"
#import "GrowlMusicVideoPrefs.h"
#import "NSWindow+Transforms.h"
#import "GrowlSlidingWindowTransition.h"
#import "GrowlWipeWindowTransition.h"
#include "CFDictionaryAdditions.h"

@implementation GrowlMusicVideoWindowController

- (id) init {
	NSLog(@"%s\n", __FUNCTION__);
	int sizePref = MUSICVIDEO_SIZE_NORMAL;

	displayDuration = GrowlBubblesDurationPrefDefault;
	
	CFNumberRef prefsDuration = NULL;
	CFTimeInterval value = -1.0f;
	READ_GROWL_PREF_VALUE(MUSICVIDEO_DURATION_PREF, GrowlMusicVideoPrefDomain, CFNumberRef, &prefsDuration);
	if(prefsDuration) {
		CFNumberGetValue(prefsDuration, kCFNumberDoubleType, &value);
		if (value > 0.0f)
			displayDuration = value;
	}

	screenNumber = 0U;
	READ_GROWL_PREF_INT(MUSICVIDEO_SCREEN_PREF, GrowlMusicVideoPrefDomain, &screenNumber);
	[self setScreen:[[NSScreen screens] objectAtIndex:screenNumber]];

	NSRect sizeRect;
	NSRect screen = [[self screen] frame];
	READ_GROWL_PREF_INT(MUSICVIDEO_SIZE_PREF, GrowlMusicVideoPrefDomain, &sizePref);
	sizeRect.origin = screen.origin;
	sizeRect.size.width = screen.size.width;
	if (sizePref == MUSICVIDEO_SIZE_HUGE)
		sizeRect.size.height = 192.0f;
	else
		sizeRect.size.height = 96.0f;
	frameHeight = sizeRect.size.height;

	READ_GROWL_PREF_INT(MUSICVIDEO_SIZE_PREF, GrowlMusicVideoPrefDomain, &sizePref);
	NSPanel *panel = [[NSPanel alloc] initWithContentRect:sizeRect
												styleMask:NSBorderlessWindowMask
												  backing:NSBackingStoreBuffered
													defer:NO];
	NSRect panelFrame = [panel frame];
	[panel setBecomesKeyOnlyIfNeeded:YES];
	[panel setHidesOnDeactivate:NO];
	[panel setBackgroundColor:[NSColor clearColor]];
	[panel setLevel:NSStatusWindowLevel];
	[panel setIgnoresMouseEvents:YES];
	[panel setSticky:YES];
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

	[panel setFrameTopLeftPoint:NSMakePoint( 0,0)];
											
	// call super so everything else is set up...
	self = [super initWithWindow:panel];
	if (!self)
		return nil;
	
	int effect = 0;
	READ_GROWL_PREF_INT(MUSICVIDEO_EFFECT_PREF, GrowlMusicVideoPrefDomain, &effect);
	if(effect == 0) {
		//slider effect
		GrowlSlidingWindowTransition *slider = [[GrowlSlidingWindowTransition alloc] initWithWindow:panel];
		[slider setFromOrigin:NSMakePoint(NSMinX(screen),-frameHeight) toOrigin:NSMakePoint(NSMinX(screen),NSMinY(screen))];
		[self setStartPercentage:0 endPercentage:100 forTransition:slider];
		[slider setAutoReverses:YES];
		[self addTransition:slider];
		[slider release];
	} else {
		//wipe effect
		//[panel setFrameOrigin:NSMakePoint( 0, 0)];
		//GrowlWipeWindowTransition *wiper = [[GrowlWipeWindowTransition alloc] initWithWindow:panel];
		// save for scale effect [wiper setFromOrigin:NSMakePoint(0,0) toOrigin:NSMakePoint(NSMaxX(screen), frameHeight)];
		//[wiper setFromOrigin:NSMakePoint(NSMaxX(screen), 0) toOrigin:NSMakePoint(NSMaxX(screen), frameHeight)];
		//[self setStartPercentage:0 endPercentage:100 forTransition:wiper];
		//[wiper setAutoReverses:YES];
		//[self addTransition:wiper];
		//[wiper release];
	}
	return self;

}

- (void) setNotification: (GrowlApplicationNotification *) theNotification {
	NSLog(@"%s\n", __FUNCTION__);
	[super setNotification:theNotification];
	if (!theNotification)
		return;
	
	NSDictionary *noteDict = [notification dictionaryRepresentation];
	NSString *title = [notification title];
	NSString *text  = [notification description];
	NSImage *icon   = getObjectForKey(noteDict, GROWL_NOTIFICATION_ICON);
	int priority    = getIntegerForKey(noteDict, GROWL_NOTIFICATION_PRIORITY);
	BOOL sticky     = getBooleanForKey(noteDict, GROWL_NOTIFICATION_STICKY);
	NSString *ident = getObjectForKey(noteDict, GROWL_NOTIFICATION_IDENTIFIER);
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
	GrowlMusicVideoWindowView *view = [panel contentView];
	[view setPriority:priority];
	[view setTitle:title];//isHTML:titleHTML];
	[view setText:text];// isHTML:textHTML];
	[view setIcon:icon];
	//[view sizeToFit];
	
	NSRect viewFrame = [view frame];
	[panel setFrame:viewFrame display:NO];
	NSRect screen = [[self screen] visibleFrame];
	[panel setFrameTopLeftPoint:NSMakePoint(0,0)];
	NSLog(@"%s %f %f %f %f\n", __FUNCTION__, [panel frame].origin.x, [panel frame].origin.y, [panel frame].size.height, [panel frame].size.width);
}

- (unsigned) depth {
	return depth;
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
