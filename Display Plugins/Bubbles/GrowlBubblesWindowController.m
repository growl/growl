//
//  GrowlBubblesWindowController.m
//  Growl
//
//  Created by Nelson Elhage on Wed Jun 09 2004.
//  Name changed from KABubbleWindowController.m by Justin Burns on Fri Nov 05 2004.
//  Copyright (c) 2004 Nelson Elhage. All rights reserved.
//

#import "GrowlBubblesWindowController.h"
#import "GrowlBubblesWindowView.h"
#import "NSGrowlAdditions.h"
#import "GrowlBubblesDefines.h"

static unsigned bubbleWindowDepth = 0U;

@implementation GrowlBubblesWindowController

#define MIN_DISPLAY_TIME 4.0
#define ADDITIONAL_LINES_DISPLAY_TIME 0.5
#define MAX_DISPLAY_TIME 10.0
#define GrowlBubblesPadding 10.0f

#pragma mark -

+ (GrowlBubblesWindowController *) bubble {
	return [[[GrowlBubblesWindowController alloc] init] autorelease];
}

+ (GrowlBubblesWindowController *) bubbleWithTitle:(NSString *) title text:(NSString *) text icon:(NSImage *) icon priority:(int)priority sticky:(BOOL) sticky{
	return [[[GrowlBubblesWindowController alloc] initWithTitle:title text:text icon:icon priority:(int)priority sticky:sticky] autorelease];
}

#pragma mark Regularly Scheduled Coding

- (id) initWithTitle:(NSString *) title text:(NSString *) text icon:(NSImage *) icon priority:(int)priority sticky:(BOOL) sticky {

	#warning View is bleeding into the controller here; these hardcoded pixels dont belong.
	// I tried setting the width/height to zero, since the view resizes itself later.
	// This made it ignore the alpha at the edges (using 1.0 instead). Why?
	// A window with a frame of NSZeroRect is off-screen and doesn't respect opacity even if moved on screen later. -Evan
	NSPanel *panel = [[[NSPanel alloc] initWithContentRect:NSMakeRect( 0.0f, 0.0f, 270.0f, 65.0f ) 
												 styleMask:NSBorderlessWindowMask | NSNonactivatingPanelMask
												   backing:NSBackingStoreBuffered defer:NO] autorelease];
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
	[panel setReleasedWhenClosed:YES];
	[panel setDelegate:self];

	GrowlBubblesWindowView *view = [[[GrowlBubblesWindowView alloc] initWithFrame:panelFrame] autorelease];
	[view setTarget:self];
	[view setAction:@selector( _bubbleClicked: )];
	[panel setContentView:view];
	
	[view setTitle:title];
	[view setText:text];
	[view setPriority:priority];
	
	[view setIcon:icon];
	panelFrame = [view frame];
	[panel setFrame:panelFrame display:NO];
	
	NSRect screen = [[NSScreen mainScreen] visibleFrame];
	[panel setFrameTopLeftPoint:NSMakePoint( NSWidth( screen ) - NSWidth( panelFrame ) - GrowlBubblesPadding, 
											 NSMaxY( screen ) - GrowlBubblesPadding - ( bubbleWindowDepth ) )];
	
	if ( (self = [super initWithWindow:panel] ) ) {
		#warning this is some temporary code to to stop notifications from spilling off the bottom of the visible screen area
		// It actually doesn't even stop _this_ notification from spilling off the bottom; just the next one.
		if ( NSMinY(panelFrame) < 0.0f ) {
			depth = bubbleWindowDepth = 0U;
		} else {
			depth = bubbleWindowDepth += NSHeight( panelFrame );
		}
		autoFadeOut = !sticky;
		target = nil;
		action = NULL;
		clickContext = nil;
		appName = nil;

		// the visibility time for this bubble should be the minimum display time plus
		// some multiple of ADDITIONAL_LINES_DISPLAY_TIME, not to exceed MAX_DISPLAY_TIME
		int rowCount = MIN ([view descriptionRowCount], 0) - 2;
		BOOL limitPref = YES;
		READ_GROWL_PREF_BOOL(KALimitPref, GrowlBubblesPrefDomain, &limitPref);
		if (!limitPref) {
			displayTime = MIN (MIN_DISPLAY_TIME + rowCount * ADDITIONAL_LINES_DISPLAY_TIME, 
							   MAX_DISPLAY_TIME);
		} else {
			displayTime = MIN_DISPLAY_TIME;
		}
	}

	return self;
}

- (void) dealloc {
	[target release];
	[clickContext release];
	[appName release];

	if ( depth == bubbleWindowDepth ) {
		bubbleWindowDepth = 0U;
	}

	[super dealloc];
}

#pragma mark -

- (void) _bubbleClicked:(id) sender {
	if ( target && action && [target respondsToSelector:action] ) {
		[target performSelector:action withObject:self];
	}
	[self startFadeOut];
}

#pragma mark -

- (id) target {
	return target;
}

- (void) setTarget:(id) object {
	[target autorelease];
	target = [object retain];
}

#pragma mark -

- (SEL) action {
	return action;
}

- (void) setAction:(SEL) selector {
	action = selector;
}

#pragma mark -

- (NSString *)appName {
	return appName;
}

- (void) setAppName:(NSString *) inAppName {
	[appName autorelease];
	appName = [inAppName retain];
}

#pragma mark -

- (id) clickContext {
	return clickContext;
}

- (void) setClickContext:(id)inClickContext {
	[clickContext autorelease];
	clickContext = [inClickContext retain];
}

@end
