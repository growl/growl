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

static unsigned bubbleWindowDepth = 0;

@implementation GrowlBubblesWindowController

#define MIN_DISPLAY_TIME 4.0
#define ADDITIONAL_LINES_DISPLAY_TIME 0.5
#define MAX_DISPLAY_TIME 10.0
#define GrowlBubblesPadding 10.f

#pragma mark -

+ (GrowlBubblesWindowController *) bubble {
	return [[[GrowlBubblesWindowController alloc] init] autorelease];
}

+ (GrowlBubblesWindowController *) bubbleWithTitle:(NSString *) title text:(NSString *) text icon:(NSImage *) icon priority:(int)priority sticky:(BOOL) sticky {
	return [[[GrowlBubblesWindowController alloc] initWithTitle:title text:text icon:icon priority:(int)priority sticky:sticky] autorelease];
}

#pragma mark Regularly Scheduled Coding

- (id) initWithTitle:(NSString *) title text:(NSString *) text icon:(NSImage *) icon priority:(int)priority sticky:(BOOL) sticky {
	extern unsigned bubbleWindowDepth;

	NSPanel *panel = [[[NSPanel alloc] initWithContentRect:NSMakeRect( 0.f, 0.f, 270.f, 65.f ) 
												 styleMask:NSBorderlessWindowMask | NSNonactivatingPanelMask
												   backing:NSBackingStoreBuffered defer:NO] autorelease];
	NSRect panelFrame = [panel frame];
	[panel setBecomesKeyOnlyIfNeeded:YES];
	[panel setHidesOnDeactivate:NO];
	[panel setBackgroundColor:[NSColor clearColor]];
	[panel setLevel:NSStatusWindowLevel];
	[panel setSticky:YES];
	[panel setAlphaValue:0.f];
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
		if ( (NSMaxY([panel frame]) - NSHeight([panel frame]) - [NSMenuView menuBarHeight]) < 0 ) {
			depth = bubbleWindowDepth = 0;
		} else {
			depth = bubbleWindowDepth += NSHeight( panelFrame );
		}
		autoFadeOut = !sticky;
		target = nil;
		action = NULL;
		
		// the visibility time for this bubble should be the minimum display time plus
		// some multiple of ADDITIONAL_LINES_DISPLAY_TIME, not to exceed MAX_DISPLAY_TIME
		int rowCount = [view descriptionRowCount];
		if (rowCount <= 2) {
			rowCount = 0;
		}
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

	extern unsigned bubbleWindowDepth;
	if ( depth == bubbleWindowDepth ) {
		bubbleWindowDepth = 0;
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
@end
