//
//  GrowlBezelWindowController.m
//  Display Plugins
//
//  Created by Jorge Salvador Caffarena on 09/09/04.
//  Copyright 2004 Jorge Salvador Caffarena. All rights reserved.
//

#import "GrowlBezelWindowController.h"
#import "GrowlBezelWindowView.h"
#import "NSGrowlAdditions.h"

@implementation GrowlBezelWindowController

#define MIN_DISPLAY_TIME 3.0
#define GrowlBezelPadding 10.0f

+ (GrowlBezelWindowController *)bezel {
	return [[[GrowlBezelWindowController alloc] init] autorelease];
}

+ (GrowlBezelWindowController *)bezelWithTitle:(NSString *)title text:(NSString *)text
		icon:(NSImage *)icon priority:(int)prio sticky:(BOOL)sticky {
	return [[[GrowlBezelWindowController alloc] initWithTitle:title text:text icon:icon priority:prio sticky:sticky] autorelease];
}

- (id)initWithTitle:(NSString *)title text:(NSString *)text icon:(NSImage *)icon priority:(int)prio sticky:(BOOL)sticky {
	int sizePref = 0;
	READ_GROWL_PREF_INT(BEZEL_SIZE_PREF, BezelPrefDomain, &sizePref);
	NSRect sizeRect;
	sizeRect.origin.x = sizeRect.origin.y = 0.0f;
	if (sizePref == BEZEL_SIZE_NORMAL) {
		sizeRect.size.width = 211.0f;
		sizeRect.size.height = 206.0f;
	} else {
		sizeRect.size.width = 160.0f;
		sizeRect.size.height = 160.0f;
	}
	NSPanel *panel = [[[NSPanel alloc] initWithContentRect:sizeRect
						styleMask:NSBorderlessWindowMask
						  backing:NSBackingStoreBuffered defer:NO] autorelease];
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
	[panel setReleasedWhenClosed:YES];
	[panel setDelegate:self];
	
	GrowlBezelWindowView *view = [[[GrowlBezelWindowView alloc] initWithFrame:panelFrame] autorelease];
	
	[view setTarget:self];
	[view setAction:@selector(_bezelClicked:)]; // Not used for now
	[panel setContentView:view];
	
	[view setTitle:title];
	NSMutableString	*tempText = [NSMutableString stringWithString:text];
	// Sanity check to unify line endings
	[tempText setString:text];
	[tempText replaceOccurrencesOfString:@"\r"
			withString:@"\n"
			options:nil
			range:NSMakeRange(0U, [tempText length])];
	[view setText:tempText];

	[view setIcon:icon];
	panelFrame = [view frame];
	[panel setFrame:panelFrame display:NO];
	
	NSRect screen = [[NSScreen mainScreen] visibleFrame];
	NSPoint panelTopLeft;
	int positionPref = 0;
	READ_GROWL_PREF_INT(BEZEL_POSITION_PREF, BezelPrefDomain, &positionPref);
	switch (positionPref) {
		default:
		case BEZEL_POSITION_DEFAULT:
			panelTopLeft = NSMakePoint(ceilf((NSWidth(screen) * 0.5f) -(NSWidth(panelFrame) * 0.5f)),
				140.0f + NSHeight(panelFrame));
			break;
		case BEZEL_POSITION_TOPRIGHT:
			panelTopLeft = NSMakePoint( NSWidth( screen ) - NSWidth( panelFrame ) - GrowlBezelPadding,
				NSMaxY ( screen ) - GrowlBezelPadding );
			break;
		case BEZEL_POSITION_BOTTOMRIGHT:
			panelTopLeft = NSMakePoint(NSWidth( screen ) - NSWidth( panelFrame ) - GrowlBezelPadding,
				GrowlBezelPadding + NSHeight(panelFrame));
			break;
		case BEZEL_POSITION_BOTTOMLEFT:
			panelTopLeft = NSMakePoint(GrowlBezelPadding,
				GrowlBezelPadding + NSHeight(panelFrame));
			break;
		case BEZEL_POSITION_TOPLEFT:
			panelTopLeft = NSMakePoint(GrowlBezelPadding,
				NSMaxY ( screen ) - GrowlBezelPadding );
			break;
	}
	[panel setFrameTopLeftPoint:panelTopLeft];

	if ( (self = [super initWithWindow:panel] ) ) {
		autoFadeOut = YES;	//!sticky
		doFadeIn = NO;
		target = nil;
		action = NULL;
		displayTime = MIN_DISPLAY_TIME;
		priority = prio;
	}

	return self;
}

- (void) dealloc {
	[target release];

	[super dealloc];
}

- (void) _bezelClicked:(id)sender {
	if ( target && action && [target respondsToSelector:action] ) {
		[target performSelector:action withObject:self];
	}
	[self startFadeOut];
}

- (id)target {
	return target;
}

- (void)setTarget:(id)object {
	[target autorelease];
	target = [object retain];
}

- (SEL)action {
	return action;
}

- (void)setAction:(SEL)selector {
	action = selector;
}

- (int)priority {
	return priority;
}

- (void)setPriority:(int)newPriority {
	priority = newPriority;
}
@end
