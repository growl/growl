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
#import "GrowlApplicationNotification.h"
#import "NSWindow+Transforms.h"
#include "CFDictionaryAdditions.h"

static unsigned globalId = 0U;

@implementation GrowlBrushedWindowController

static const double gAdditionalLinesDisplayTime = 0.5;
static const double gMaxDisplayTime = 10.0;
static NSMutableDictionary *notificationsByIdentifier;

#pragma mark Delegate Methods
/*
	These methods are the methods that this class calls on the delegate.  In this case
	this class is the delegate for the class
*/

- (void) displayWindowControllerDidFadeOut:(NSNotification *)notification {
#pragma unused(notification)
	NSSize windowSize = [[self window] frame].size;
//	NSLog(@"self id: [%d]", self->uid);

	// stop depth wrapping around
	if (windowSize.height > depth)
		depth = 0U;
	else
		depth -= windowSize.height;

	CFNumberRef idValue = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &uid);
	CFNumberRef depthValue = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &depth);
	CFStringRef keys[2] = { CFSTR("ID"), CFSTR("Depth") };
	CFTypeRef   values[2] = { idValue, depthValue };
	CFDictionaryRef dict = CFDictionaryCreate(kCFAllocatorDefault, (const void **)keys, (const void **)values, 2, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
	CFRelease(idValue);
	CFRelease(depthValue);

	CFNotificationCenterPostNotification(CFNotificationCenterGetLocalCenter(),
										 CFSTR("BrushedGone"),
										 /*object*/ NULL,
										 /*userInfo*/ dict,
										 /*deliverImmediately*/ false);
	CFRelease(dict);
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
		theFrame.origin.y = space.origin.y - space.size.height - GrowlBrushedPadding;
		//NSLog(@"New origin: (%f, %f)\n", theFrame.origin.x, theFrame.origin.y);
		[window setFrame:theFrame display:NO animate:YES];
		CFNumberRef idValue = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &uid);
		CFStringRef keys[2] = { CFSTR("ID"), CFSTR("Space") };
		CFTypeRef   values[2] = { idValue, [NSValue valueWithRect:theFrame] };
		CFDictionaryRef dict = CFDictionaryCreate(kCFAllocatorDefault, (const void **)keys, (const void **)values, 2, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
		CFRelease(idValue);
		CFNotificationCenterPostNotification(CFNotificationCenterGetLocalCenter(),
											 CFSTR("Clear Space"),
											 /*object*/ NULL,
											 /*userInfo*/ dict,
											 /*deliverImmediately*/ false);
		CFRelease(dict);
	}
}

#pragma mark Regularly Scheduled Coding

- (id) init;
{
	// Read prefs...
	screenNumber = 0U;
	READ_GROWL_PREF_INT(GrowlBrushedScreenPref, GrowlBrushedPrefDomain, &screenNumber);
	[self setScreen:[[NSScreen screens] objectAtIndex:screenNumber]];
	NSRect screen = [[self screen] visibleFrame];
	unsigned styleMask = NSBorderlessWindowMask | NSNonactivatingPanelMask;
	displayDuration = GrowlBrushedDurationPrefDefault * 10.0f; /* not sure why this is coming back like this */
	READ_GROWL_PREF_FLOAT(GrowlBrushedDurationPref, GrowlBrushedPrefDomain, &displayDuration);
	
	// Create window...
	NSRect windowFrame = NSMakeRect(0.0f, 0.0f, GrowlBrushedNotificationWidth, 65.0f);
	NSPanel *panel = [[NSPanel alloc] initWithContentRect:windowFrame										
												styleMask:styleMask
												  backing:NSBackingStoreBuffered
													defer:NO];
	NSRect panelFrame = [panel frame];
	[panel setBecomesKeyOnlyIfNeeded:YES];
	[panel setHidesOnDeactivate:NO];
	[panel setLevel:NSStatusWindowLevel];
	[panel setSticky:YES];
	[panel setAlphaValue:1.0f];	/// this is wrong
	[panel setOpaque:NO];
	[panel setHasShadow:YES];
	[panel setCanHide:NO];
	[panel setOneShot:YES];
	[panel useOptimizedDrawing:YES];
	[panel setMovableByWindowBackground:NO];
	//[panel setReleasedWhenClosed:YES]; // ignored for windows owned by window controllers.
	//[panel setDelegate:self];
	
	// Create the content view...
	GrowlBrushedWindowView *view = [[GrowlBrushedWindowView alloc] initWithFrame:panelFrame];
	[view setTarget:self];
	[view setAction:@selector(notificationClicked:)];
	[panel setContentView:view];
	
	panelFrame = [view frame];
	[panel setFrame:panelFrame display:NO];
	[panel setFrameTopLeftPoint:NSMakePoint(NSMaxX(screen) - NSWidth(panelFrame) - GrowlBrushedPadding,
											NSMaxY(screen) - GrowlBrushedPadding - depth)];
	
	return [super initWithWindow:panel];
}

- (id) initWithNotification:(GrowlApplicationNotification *)notification depth:(unsigned)theDepth {

/*	if ((self = [super initWithWindow:panel])) {
		depth += NSHeight(panelFrame);
		//autoFadeOut = !sticky;
		[self setDelegate:self];

		// the visibility time for this notification should be the minimum display time plus
		// some multiple of gAdditionalLinesDisplayTime, not to exceed gMaxDisplayTime
		int rowCount = [view descriptionRowCount];
		if (rowCount <= 2)
			rowCount = 0;
		float duration = GrowlBrushedDurationPrefDefault;
		READ_GROWL_PREF_FLOAT(GrowlBrushedDurationPref, GrowlBrushedPrefDomain, &duration);
		/*BOOL limitPref = YES;
		READ_GROWL_PREF_BOOL(GrowlBrushedLimitPref, GrowlBrushedPrefDomain, &limitPref);
		if (!limitPref) {
			[self setDisplayDuration:MIN(duration + rowCount * gAdditionalLinesDisplayTime,
										 gMaxDisplayTime)];


		CFNumberRef idValue = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &uid);
		CFStringRef keys[2] = { CFSTR("ID"), CFSTR("Space") };
		CFTypeRef   values[2] = { idValue, [NSValue valueWithRect:[[self window] frame]] };
		CFDictionaryRef dict = CFDictionaryCreate(kCFAllocatorDefault, (const void **)keys, (const void **)values, 2, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
		CFRelease(idValue);
		CFNotificationCenterPostNotification(CFNotificationCenterGetLocalCenter(),
											 CFSTR("Clear Space"),
											 /*object NULL,
											 /*userInfo dict,
											 /*deliverImmediately false);
		CFRelease(dict);
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(clearSpace:)
													 name:@"Clear Space"
												   object:nil];
	}*/
	return self;
}

- (void) startFadeOut {
	GrowlBrushedWindowView *view = (GrowlBrushedWindowView *)[[self window] contentView];
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

- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	//extern unsigned BrushedWindowDepth;
	//if ( depth == brushedWindowDepth )
	// 	brushedWindowDepth = 0;

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

- (void) setNotification: (GrowlApplicationNotification *) theNotification {
	[super setNotification:theNotification];
	if (!theNotification)
		return;
	
	NSDictionary *noteDict = [notification dictionaryRepresentation];
	NSString *title = [notification HTMLTitle];
	NSString *text  = [notification HTMLDescription];
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
	GrowlBrushedWindowView *view = [[self window] contentView];
	[view setPriority:priority];
	[view setTitle:title isHTML:titleHTML];
	[view setText:text isHTML:textHTML];
	[view setIcon:icon];
	[view sizeToFit];
	
	NSRect viewFrame = [view frame];
	[panel setFrame:viewFrame display:NO];
	NSRect screen = [[self screen] visibleFrame];
	[panel setFrameTopLeftPoint:NSMakePoint(NSMaxX(screen) - NSWidth(viewFrame) - GrowlBrushedPadding,
											NSMaxY(screen) - GrowlBrushedPadding - depth)];
}

@end
