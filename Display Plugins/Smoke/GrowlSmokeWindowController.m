//
//  GrowlSmokeWindowController.m
//  Display Plugins
//
//  Created by Matthew Walton on 11/09/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//
//  Most of this is lifted from KABubbleWindowController in the Growl source

#import "GrowlSmokeWindowController.h"
#import "GrowlSmokeWindowView.h"
#import "GrowlSmokeDefines.h"
#import "GrowlDefines.h"
#import "NSGrowlAdditions.h"

static unsigned int globalId = 0;

@implementation GrowlSmokeWindowController

static const double gMinDisplayTime = 4.;
static const double gAdditionalLinesDisplayTime = 0.5;
static const double gMaxDisplayTime = 10.;

#pragma mark -

+ (GrowlSmokeWindowController *) notify {
	return [[[GrowlSmokeWindowController alloc] init] autorelease];
}

+ (GrowlSmokeWindowController *) notifyWithTitle:(NSString *) title text:(NSString *) text icon:(NSImage *) icon priority:(int)priority sticky:(BOOL) sticky depth:(unsigned int) depth {
	return [[[GrowlSmokeWindowController alloc] initWithTitle:title text:text icon:icon priority:priority sticky:sticky depth:depth] autorelease];
}

#pragma mark Delegate Methods
/*	
	These methods are the methods that this class calls on the delegate.  In this case
	this class is the delegate for the class
*/

- (void) didFadeOut:(id)sender {
	NSSize windowSize = [[self window] frame].size;
//	NSLog(@"self id: [%d]", self->_id);

	// stop _depth wrapping around
	if(windowSize.height > _depth) {
		_depth = 0;
	} else {
		_depth -= windowSize.height;
	}
	
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithUnsignedInt:_id], @"ID",
		[NSNumber numberWithInt:_depth], @"Depth",
		nil];

	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc postNotificationName:@"Glide" object:nil userInfo:dict];
	[nc postNotificationName:@"SmokeGone" object:nil userInfo:dict];
}

- (void) _glideUp:(NSNotification *)note {
	NSDictionary *userInfo = [note userInfo];
//	NSLog(@"id: %d depth: %f", [[userInfo objectForKey:@"ID"] unsignedIntValue], [[userInfo objectForKey:@"Depth"] floatValue]);
//	NSLog(@"self id: %d smokeWindowDepth: %d", _id, smokeWindowDepth);
	if ([[userInfo objectForKey:@"ID"] unsignedIntValue] < _id) {
		NSRect theFrame = [[self window] frame];
		theFrame.origin.y += [[[note userInfo] objectForKey:@"Depth"] floatValue];
		// don't allow notification to fly off the top of the screen
		if(theFrame.origin.y < NSMaxY( [[NSScreen mainScreen] visibleFrame] ) - GrowlSmokePadding) {
			[[self window] setFrame:theFrame display:NO animate:YES];
			NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
				[NSNumber numberWithUnsignedInt:_id], @"ID",
				[NSValue valueWithRect:theFrame], @"Space",
				nil];
			[[NSNotificationCenter defaultCenter] postNotificationName:@"Clear Space" object:nil userInfo:dict];
		}
	}
}

- (void) _clearSpace:(NSNotification *)note {
	NSDictionary *userInfo = [note userInfo];
	unsigned int i = [[userInfo objectForKey:@"ID"] unsignedIntValue];
	NSRect space = [[userInfo objectForKey:@"Space"] rectValue];
	NSRect theFrame = [[self window] frame];
	/*NSLog(@"Notification %u (%f, %f, %f, %f) received clear space message from notification %u (%f, %f, %f, %f)\n",
		  _id, i,
		  theFrame.origin.x, theFrame.origin.y, theFrame.size.width, theFrame.size.height,
		  space.origin.x, space.origin.y, space.size.width, space.size.height);*/
	if(i != _id && NSIntersectsRect(space, theFrame)) {
		//NSLog(@"I intersect with this frame\n");
		theFrame.origin.y = space.origin.y - space.size.height;
		//NSLog(@"New origin: (%f, %f)\n", theFrame.origin.x, theFrame.origin.y);
		[[self window] setFrame:theFrame display:NO animate:YES];
		NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
			[NSNumber numberWithUnsignedInt:_id], @"ID",
			[NSValue valueWithRect:theFrame], @"Space",
			nil];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"Clear Space" object:nil userInfo:dict];
	}
}

#pragma mark Regularly Scheduled Coding

- (id) initWithTitle:(NSString *) title text:(NSString *) text icon:(NSImage *) icon priority:(int) priority sticky:(BOOL) sticky depth:(unsigned int) depth {
	_id = globalId++;
	_depth = depth;

	/*[[NSNotificationCenter defaultCenter] addObserver:self 
											selector:@selector( _glideUp: ) 
												name:@"Glide"
											  object:nil];*/

	NSPanel *panel = [[[NSPanel alloc] initWithContentRect:NSMakeRect( 0.f, 0.f, GrowlSmokeNotificationWidth, 65.f ) 
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

	GrowlSmokeWindowView *view = [[[GrowlSmokeWindowView alloc] initWithFrame:panelFrame] autorelease];
	[view setTarget:self];
	[view setAction:@selector( _notificationClicked: )];
	[panel setContentView:view];
	
	[view setTitle:title];
	[view setText:text];	
    [view setPriority:priority];
    
	[view setIcon:icon];
	panelFrame = [view frame];
	[panel setFrame:panelFrame display:NO];

	NSRect screen = [[NSScreen mainScreen] visibleFrame];
	[panel setFrameTopLeftPoint:NSMakePoint( NSWidth( screen ) - NSWidth( panelFrame ) - GrowlSmokePadding, 
											 NSMaxY( screen ) - GrowlSmokePadding - depth )];

	if( (self = [super initWithWindow:panel] ) ) {
		_depth += NSHeight( panelFrame );
		_autoFadeOut = !sticky;
		_target = nil;
		_action = NULL;
		_delegate = self;

		// the visibility time for this notification should be the minimum display time plus
		// some multiple of gAdditionalLinesDisplayTime, not to exceed gMaxDisplayTime
		int rowCount = [view descriptionRowCount];
		if (rowCount <= 2) {
			rowCount = 0;
		}
		/*BOOL limitPref = YES;
		READ_GROWL_PREF_BOOL(GrowlSmokeLimitPref, GrowlSmokePrefDomain, &limitPref);
		if (!limitPref) {*/
			_displayTime = MIN (gMinDisplayTime + rowCount * gAdditionalLinesDisplayTime, 
								gMaxDisplayTime);
		/*} else {
			_displayTime = gMinDisplayTime;
		}*/

		NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
			[NSNumber numberWithUnsignedInt:_id], @"ID",
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
	//[[NSNotificationCenter defaultCenter] removeObserver:self];

	[_target release];

	//extern unsigned int smokeWindowDepth;
//	NSLog(@"smokeController deallocking");
	//if( _depth == smokeWindowDepth ) 
	// 	smokeWindowDepth = 0;

	[super dealloc];
}

#pragma mark -

- (void) _notificationClicked:(id) sender {
	if( _target && _action && [_target respondsToSelector:_action] ) {
		[_target performSelector:_action withObject:self];
	}
	[self startFadeOut];
}

#pragma mark -

- (id) target {
	return _target;
}

- (void) setTarget:(id) object {
	[_target autorelease];
	_target = [object retain];
}

#pragma mark -

- (SEL) action {
	return _action;
}

- (void) setAction:(SEL) selector {
	_action = selector;
}

#pragma mark -

- (unsigned int)depth {
	return _depth;
}
@end
