//
//  GrowlBrushedWindowController.m
//  Display Plugins
//
//  Created by Ingmar Stein on 12/01/2004.
//  Copyright 2004-2005 The Growl Project. All rights reserved.
//
//  Most of this is lifted from KABubbleWindowController in the Growl source

#import "GrowlBrushedWindowController.h"
#import "GrowlBrushedWindowView.h"
#import "GrowlBrushedDefines.h"
#import "GrowlDefinesInternal.h"
#import "NSGrowlAdditions.h"

static unsigned globalId = 0U;

@implementation GrowlBrushedWindowController

static const double gAdditionalLinesDisplayTime = 0.5;
static const double gMaxDisplayTime = 10.;

#pragma mark -

+ (GrowlBrushedWindowController *) notifyWithTitle:(NSString *) title text:(NSString *) text icon:(NSImage *) icon priority:(int)priority sticky:(BOOL) sticky depth:(unsigned) theDepth {
	return [[[GrowlBrushedWindowController alloc] initWithTitle:title text:text icon:icon priority:priority sticky:sticky depth:theDepth] autorelease];
}

#pragma mark Delegate Methods
/*	
	These methods are the methods that this class calls on the delegate.  In this case
	this class is the delegate for the class
*/

- (void) didFadeOut:(FadingWindowController *)sender {
	NSSize windowSize = [[self window] frame].size;
//	NSLog(@"self id: [%d]", self->identifier);

	// stop depth wrapping around
	if (windowSize.height > depth) {
		depth = 0;
	} else {
		depth -= windowSize.height;
	}

	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithUnsignedInt:identifier], @"ID",
		[NSNumber numberWithInt:depth], @"Depth",
		nil];

	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc postNotificationName:@"Glide" object:nil userInfo:dict];
	[nc postNotificationName:@"BrushedGone" object:nil userInfo:dict];
}

- (void) _glideUp:(NSNotification *)note {
	NSDictionary *userInfo = [note userInfo];
//	NSLog(@"id: %d depth: %f", [[userInfo objectForKey:@"ID"] unsignedIntValue], [[userInfo objectForKey:@"Depth"] floatValue]);
//	NSLog(@"self id: %d BrushedWindowDepth: %d", identifier, BrushedWindowDepth);
	if ([[userInfo objectForKey:@"ID"] unsignedIntValue] < identifier) {
		NSWindow *window = [self window];
		NSRect theFrame = [window frame];
		theFrame.origin.y += [[[note userInfo] objectForKey:@"Depth"] floatValue];
		// don't allow notification to fly off the top of the screen
		if (theFrame.origin.y < NSMaxY( [[self screen] visibleFrame] ) - GrowlBrushedPadding) {
			[window setFrame:theFrame display:NO animate:YES];
			NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
				[NSNumber numberWithUnsignedInt:identifier], @"ID",
				[NSValue valueWithRect:theFrame], @"Space",
				nil];
			[[NSNotificationCenter defaultCenter] postNotificationName:@"Clear Space" object:nil userInfo:dict];
		}
	}
}

- (void) _clearSpace:(NSNotification *)note {
	NSDictionary *userInfo = [note userInfo];
	unsigned i = [[userInfo objectForKey:@"ID"] unsignedIntValue];
	NSRect space = [[userInfo objectForKey:@"Space"] rectValue];
	NSWindow *window = [self window];
	NSRect theFrame = [window frame];
	/*NSLog(@"Notification %u (%f, %f, %f, %f) received clear space message from notification %u (%f, %f, %f, %f)\n",
		  identifier, i,
		  theFrame.origin.x, theFrame.origin.y, theFrame.size.width, theFrame.size.height,
		  space.origin.x, space.origin.y, space.size.width, space.size.height);*/
	if (i != identifier && NSIntersectsRect(space, theFrame)) {
		//NSLog(@"I intersect with this frame\n");
		theFrame.origin.y = space.origin.y - space.size.height;
		//NSLog(@"New origin: (%f, %f)\n", theFrame.origin.x, theFrame.origin.y);
		[window setFrame:theFrame display:NO animate:YES];
		NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
			[NSNumber numberWithUnsignedInt:identifier], @"ID",
			[NSValue valueWithRect:theFrame], @"Space",
			nil];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"Clear Space" object:nil userInfo:dict];
	}
}

#pragma mark Regularly Scheduled Coding

- (id) initWithTitle:(NSString *) title text:(NSString *) text icon:(NSImage *) icon priority:(int) priority sticky:(BOOL) sticky depth:(unsigned) theDepth {
	identifier = globalId++;
	depth = theDepth;
	unsigned styleMask = NSBorderlessWindowMask | NSNonactivatingPanelMask;

	BOOL aquaPref = GrowlBrushedAquaPrefDefault;
	READ_GROWL_PREF_BOOL(GrowlBrushedAquaPref, GrowlBrushedPrefDomain, &aquaPref);
	if (!aquaPref) {
		styleMask |= NSTexturedBackgroundWindowMask;
	}

	screenNumber = 0U;
	READ_GROWL_PREF_INT(GrowlBrushedScreenPref, GrowlBrushedPrefDomain, &screenNumber);

	/*[[NSNotificationCenter defaultCenter] addObserver:self 
											selector:@selector( _glideUp: ) 
												name:@"Glide"
											  object:nil];*/

	NSPanel *panel = [[NSPanel alloc] initWithContentRect:NSMakeRect( 0.0f, 0.0f, GrowlBrushedNotificationWidth, 65.0f ) 
												styleMask:styleMask
												  backing:NSBackingStoreBuffered
													defer:NO];
	NSRect panelFrame = [panel frame];
	[panel setBecomesKeyOnlyIfNeeded:YES];
	[panel setHidesOnDeactivate:NO];
	[panel setLevel:NSStatusWindowLevel];
	[panel setSticky:YES];
	[panel setAlphaValue:0.0f];
	[panel setOpaque:NO];
	[panel setHasShadow:YES];
	[panel setCanHide:NO];
	[panel setOneShot:YES];
	[panel setMovableByWindowBackground:NO];
	//[panel setReleasedWhenClosed:YES]; // ignored for windows owned by window controllers.
	//[panel setDelegate:self];

	GrowlBrushedWindowView *view = [[GrowlBrushedWindowView alloc] initWithFrame:panelFrame];
	[view setTarget:self];
	[view setAction:@selector(_notificationClicked:)];
	[panel setContentView:view];

	[view setTitle:title];
	[view setText:text];
    [view setPriority:priority];

	[view setIcon:icon];
	panelFrame = [view frame];
	[panel setFrame:panelFrame display:NO];

	NSRect screen = [[self screen] visibleFrame];

	[panel setFrameTopLeftPoint:NSMakePoint(NSMaxX(screen) - NSWidth( panelFrame ) - GrowlBrushedPadding,
											NSMaxY(screen) - GrowlBrushedPadding - depth)];

	if ((self = [super initWithWindow:panel])) {
		depth += NSHeight( panelFrame );
		autoFadeOut = !sticky;
		delegate = self;

		// the visibility time for this notification should be the minimum display time plus
		// some multiple of gAdditionalLinesDisplayTime, not to exceed gMaxDisplayTime
		int rowCount = [view descriptionRowCount];
		if (rowCount <= 2) {
			rowCount = 0;
		}
		float duration = GrowlBrushedDurationPrefDefault;
		READ_GROWL_PREF_FLOAT(GrowlBrushedDurationPref, GrowlBrushedPrefDomain, &duration);
		/*BOOL limitPref = YES;
		READ_GROWL_PREF_BOOL(GrowlBrushedLimitPref, GrowlBrushedPrefDomain, &limitPref);
		if (!limitPref) {*/
			displayTime = MIN (duration + rowCount * gAdditionalLinesDisplayTime, 
							   gMaxDisplayTime);
		/*} else {
			displayTime = gMinDisplayTime;
		}*/

		NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
			[NSNumber numberWithUnsignedInt:identifier], @"ID",
			[NSValue valueWithRect:[[self window] frame]], @"Space",
			nil];
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		[nc postNotificationName:@"Clear Space" object:nil userInfo:dict];
		[nc addObserver:self 
			   selector:@selector( _clearSpace: ) 
				   name:@"Clear Space"
				 object:nil];
	}
	return self;
}

- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	//extern unsigned BrushedWindowDepth;
//	NSLog(@"BrushedController deallocking");
	//if ( depth == brushedWindowDepth ) 
	// 	brushedWindowDepth = 0;

	NSWindow *myWindow = [self window];
	[[myWindow contentView] release];
	[myWindow release];

	[super dealloc];
}

#pragma mark -

- (unsigned)depth {
	return depth;
}
@end
