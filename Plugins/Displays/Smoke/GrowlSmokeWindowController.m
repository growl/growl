//
//  GrowlSmokeWindowController.m
//  Display Plugins
//
//  Created by Matthew Walton on 11/09/2004.
//  Copyright 2004-2005 The Growl Project. All rights reserved.
//
//  Most of this is lifted from KABubbleWindowController in the Growl source

#import "GrowlSmokeWindowController.h"
#import "GrowlSmokeWindowView.h"
#import "GrowlSmokeDefines.h"
#import "GrowlDefinesInternal.h"
#import "NSWindow+Transforms.h"
#import "NSDictionaryAdditions.h"

static unsigned globalId = 0U;

@implementation GrowlSmokeWindowController

static const double gAdditionalLinesDisplayTime = 0.5;
static const double gMaxDisplayTime = 10.0;
static NSMutableDictionary *notificationsByIdentifier;

#pragma mark Delegate Methods
/*
	These methods are the methods that this class calls on the delegate.  In this case
	this class is the delegate for the class
*/

- (void) displayWindowControllerDidFadeOut:(GrowlDisplayFadingWindowController *)sender {
#pragma unused(sender)
	NSSize windowSize = [[self window] frame].size;
//	NSLog(@"self id: [%d]", self->uid);

	// stop depth wrapping around
	if (windowSize.height > depth)
		depth = 0U;
	else
		depth -= windowSize.height;

	NSNumber *idValue = [[NSNumber alloc] initWithUnsignedInt:uid];
	NSNumber *depthValue = [[NSNumber alloc] initWithUnsignedInt:depth];
	NSDictionary *dict = [[NSDictionary alloc] initWithObjectsAndKeys:
		idValue,    @"ID",
		depthValue, @"Depth",
		nil];
	[idValue    release];
	[depthValue release];

	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc postNotificationName:@"SmokeGone" object:nil userInfo:dict];
	[dict release];
}

- (void) clearSpace:(NSNotification *)note {
	NSDictionary *userInfo = [note userInfo];
	unsigned i = [[userInfo objectForKey:@"ID"] unsignedIntValue];
	NSRect space = [[userInfo objectForKey:@"Space"] rectValue];
	NSWindow *window = [self window];
	NSRect theFrame = [window frame];
	/*NSLog(@"Notification %u (%f, %f, %f, %f) received clear space message from notification %u (%f, %f, %f, %f)\n",
		  uid, i,
		  theFrame.origin.x, theFrame.origin.y, theFrame.size.width, theFrame.size.height,
		  space.origin.x, space.origin.y, space.size.width, space.size.height);*/
	if (i != uid && NSIntersectsRect(space, theFrame)) {
		//NSLog(@"I intersect with this frame\n");
		theFrame.origin.y = space.origin.y - space.size.height - GrowlSmokePadding;
		//NSLog(@"New origin: (%f, %f)\n", theFrame.origin.x, theFrame.origin.y);
		[window setFrame:theFrame display:NO animate:YES];
		NSNumber *idValue = [[NSNumber alloc] initWithUnsignedInt:uid];
		NSDictionary *dict = [[NSDictionary alloc] initWithObjectsAndKeys:
			idValue, @"ID",
			[NSValue valueWithRect:theFrame], @"Space",
			nil];
		[idValue release];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"Clear Space" object:nil userInfo:dict];
		[dict release];
	}
}

#pragma mark Regularly Scheduled Coding

- (id) initWithDictionary:(NSDictionary *)noteDict depth:(unsigned)theDepth {
	NSString *title = [noteDict objectForKey: GROWL_NOTIFICATION_TITLE_HTML];
	NSString *text  = [noteDict objectForKey: GROWL_NOTIFICATION_DESCRIPTION_HTML];
	NSImage *icon   = [noteDict objectForKey: GROWL_NOTIFICATION_ICON];
	int priority    = [noteDict integerForKey:GROWL_NOTIFICATION_PRIORITY];
	BOOL sticky     = [noteDict boolForKey:   GROWL_NOTIFICATION_STICKY];
	NSString *ident = [noteDict objectForKey: GROWL_NOTIFICATION_IDENTIFIER];
	BOOL textHTML, titleHTML;

	if (title)
		titleHTML = YES;
	else {
		titleHTML = NO;
		title = [noteDict objectForKey:GROWL_NOTIFICATION_TITLE];
	}
	if (text)
		textHTML = YES;
	else {
		textHTML = NO;
		text = [noteDict objectForKey:GROWL_NOTIFICATION_DESCRIPTION];
	}

	GrowlSmokeWindowController *oldController = [notificationsByIdentifier objectForKey:ident];
	if (oldController) {
		// coalescing
		GrowlSmokeWindowView *view = (GrowlSmokeWindowView *)[[oldController window] contentView];
		[view setPriority:priority];
		[view setTitle:title isHTML:titleHTML];
		[view setText:text isHTML:textHTML];
		[view setIcon:icon];
		[self release];
		self = oldController;
		return self;
	}
	identifier = [ident retain];
	uid = globalId++;
	depth = theDepth;

	screenNumber = 0U;
	READ_GROWL_PREF_INT(GrowlSmokeScreenPref, GrowlSmokePrefDomain, &screenNumber);

	NSPanel *panel = [[NSPanel alloc] initWithContentRect:NSMakeRect(0.0f, 0.0f, GrowlSmokeNotificationWidth, 65.0f)
												styleMask:NSBorderlessWindowMask | NSNonactivatingPanelMask
												  backing:NSBackingStoreBuffered
													defer:NO];
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
	[panel setOneShot:YES];
	[panel useOptimizedDrawing:YES];
	//[panel setReleasedWhenClosed:YES]; // ignored for windows owned by window controllers.
	//[panel setDelegate:self];

	GrowlSmokeWindowView *view = [[GrowlSmokeWindowView alloc] initWithFrame:panelFrame];
	[view setTarget:self];
	[view setAction:@selector(notificationClicked:)];
	[panel setContentView:view];

	[view setPriority:priority];
	[view setTitle:title isHTML:titleHTML];
	[view setText:text isHTML:textHTML];
	[view setIcon:icon];

	panelFrame = [view frame];
	[panel setFrame:panelFrame display:NO];

	NSRect screen = [[self screen] visibleFrame];

	[panel setFrameTopLeftPoint:NSMakePoint(NSMaxX(screen) - NSWidth( panelFrame ) - GrowlSmokePadding,
											NSMaxY(screen) - GrowlSmokePadding - depth)];

	if ((self = [super initWithWindow:panel])) {
		depth += NSHeight(panelFrame);
		autoFadeOut = !sticky;
		[self setDelegate:self];

		// the visibility time for this notification should be the minimum display time plus
		// some multiple of gAdditionalLinesDisplayTime, not to exceed gMaxDisplayTime
		int rowCount = [view descriptionRowCount];
		if (rowCount <= 2)
			rowCount = 0;
		float duration = GrowlSmokeDurationPrefDefault;
		READ_GROWL_PREF_FLOAT(GrowlSmokeDurationPref, GrowlSmokePrefDomain, &duration);
		/*BOOL limitPref = YES;
		READ_GROWL_PREF_BOOL(GrowlSmokeLimitPref, GrowlSmokePrefDomain, &limitPref);
		if (!limitPref) {*/
			displayDuration = MIN (duration + rowCount * gAdditionalLinesDisplayTime,
								gMaxDisplayTime);
		/*} else {
			displayDuration = gMinDisplayTime;
		}*/

		NSNumber *idValue = [[NSNumber alloc] initWithUnsignedInt:uid];
		NSDictionary *dict = [[NSDictionary alloc] initWithObjectsAndKeys:
			idValue, @"ID",
			[NSValue valueWithRect:[[self window] frame]], @"Space",
			nil];
		[idValue release];
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		[nc postNotificationName:@"Clear Space" object:nil userInfo:dict];
		[dict release];
		[nc addObserver:self
			   selector:@selector(clearSpace:)
				   name:@"Clear Space"
				 object:nil];

		if (identifier) {
			if (!notificationsByIdentifier)
				notificationsByIdentifier = [[NSMutableDictionary alloc] init];
			[notificationsByIdentifier setObject:self forKey:identifier];
		}
	}
	return self;
}

- (void) startFadeOut {
	GrowlSmokeWindowView *view = (GrowlSmokeWindowView *)[[self window] contentView];
	if ([view mouseOver]) {
		[view setCloseOnMouseExit:YES];
	} else {
		if (identifier) {
			[notificationsByIdentifier removeObjectForKey:identifier];
			if (![notificationsByIdentifier count]) {
				[notificationsByIdentifier release];
				notificationsByIdentifier = nil;
			}
		}
		[super startFadeOut];
	}
}

- (void) setProgress:(NSNumber *)value {
	[(GrowlSmokeWindowView *)[[self window] contentView] setProgress:value];
}

- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	//extern unsigned smokeWindowDepth;
//	NSLog(@"smokeController deallocking");
	//if ( depth == smokeWindowDepth )
	// 	smokeWindowDepth = 0;

	NSWindow *myWindow = [self window];
	[[myWindow contentView] release];
	[myWindow release];
	[identifier release];

	[super dealloc];
}

#pragma mark -

- (unsigned) depth {
	return depth;
}

@end
