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
#import "GrowlApplicationNotification.h"
#import "GrowlWindowTransition.h"
#import "GrowlFadingWindowTransition.h"
#include "CFDictionaryAdditions.h"

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

- (void) displayWindowControllerDidFadeOut:(NSNotification *)notification {
#pragma unused(notification)
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

- (id) init {
	unsigned screenNumber = 0U;
	READ_GROWL_PREF_INT(GrowlSmokeScreenPref, GrowlSmokePrefDomain, &screenNumber);
	[self setScreen:[[NSScreen screens] objectAtIndex:screenNumber]];
	NSRect screen = [[self screen] visibleFrame];

	CFNumberRef prefsDuration = NULL;
	CFTimeInterval value = -1.0f;

	displayDuration = GrowlSmokeDurationPrefDefault;
	READ_GROWL_PREF_VALUE(GrowlSmokeDurationPref, GrowlSmokePrefDomain, CFNumberRef, &prefsDuration);
	if(prefsDuration) {
		CFNumberGetValue(prefsDuration, kCFNumberDoubleType, &value);
		if (value > 0.0f)
			displayDuration = value;
	}	

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
	[view setDelegate:self];
	[view setCloseOnMouseExit:YES];
	[panel setContentView:view];


	panelFrame = [view frame];
	[panel setFrame:panelFrame display:NO];
	[panel setFrameTopLeftPoint:NSMakePoint(NSMaxX(screen) - NSWidth(panelFrame) - GrowlSmokePadding,
											NSMaxY(screen) - GrowlSmokePadding - depth)];
	// call super so everything else is set up...
	self = [super initWithWindow:panel];
	if (!self)
		return nil;
	
	// set up the transitions...
	GrowlFadingWindowTransition *fader = [[GrowlFadingWindowTransition alloc] initWithWindow:panel];
	[self addTransition:fader];
	[self setStartPercentage:0 endPercentage:100 forTransition:fader];
	[fader setAutoReverses:YES];
	[fader release];
	
	return self;
}

/*- (id) initWithNotification:(GrowlApplicationNotification *)notification depth:(unsigned)theDepth {
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

	GrowlSmokeWindowController *oldController = [notificationsByIdentifier objectForKey:ident];
	if (oldController) {
		// coalescing
		GrowlSmokeWindowView *view = (GrowlSmokeWindowView *)[[oldController window] contentView];
		[view setPriority:priority];
		[view setTitle:title isHTML:titleHTML];
		[view setText:text isHTML:textHTML];
		[view setIcon:icon];
		[view sizeToFit];
		[self release];
		self = oldController;
		return self;
	}
	identifier = [ident retain];
	uid = globalId++;
	depth = theDepth;

	unsigned screenNumber = 0U;
	READ_GROWL_PREF_INT(GrowlSmokeScreenPref, GrowlSmokePrefDomain, &screenNumber);
	[self setScreen:[[NSScreen screens] objectAtIndex:screenNumber]];

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
	[view sizeToFit];

	panelFrame = [view frame];
	[panel setFrame:panelFrame display:NO];

	NSRect screen = [[self screen] visibleFrame];

	[panel setFrameTopLeftPoint:NSMakePoint(NSMaxX(screen) - NSWidth(panelFrame) - GrowlSmokePadding,
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
		//BOOL limitPref = YES;
		//READ_GROWL_PREF_BOOL(GrowlSmokeLimitPref, GrowlSmokePrefDomain, &limitPref);
		//if (!limitPref) {
			[self setDisplayDuration:MIN(duration + rowCount * gAdditionalLinesDisplayTime,
										 gMaxDisplayTime)];
		//} else {
		//	displayDuration = gMinDisplayTime;
		//}

		CFNumberRef idValue = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &uid);
		CFStringRef keys[2] = { CFSTR("ID"), CFSTR("Space") };
		CFTypeRef   values[2] = { idValue, [NSValue valueWithRect:[[self window] frame]] };
		CFDictionaryRef dict = CFDictionaryCreate(kCFAllocatorDefault, (const void **)keys, (const void **)values, 2, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
		CFRelease(idValue);
		//CFNotificationCenterPostNotification(CFNotificationCenterGetLocalCenter(),
											 CFSTR("Clear Space"),
											  NULL,
											  dict,
											  false);
		CFRelease(dict);
		[[NSNotificationCenter defaultCenter] addObserver:self
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
}*/

- (void) dealloc {
	//[[NSNotificationCenter defaultCenter] removeObserver:self];

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
- (void) setNotification: (GrowlApplicationNotification *) theNotification {
	[super setNotification:theNotification];
	if (!theNotification)
		return;
	
	NSDictionary *noteDict = [notification dictionaryRepresentation];
	NSString *title = [notification HTMLTitle];
	NSString *text  = [notification HTMLDescription];
	NSImage *icon   = getObjectForKey(noteDict, GROWL_NOTIFICATION_ICON);
	int priority    = getIntegerForKey(noteDict, GROWL_NOTIFICATION_PRIORITY);
#warning commented out due to an indication that they're not being used
	//BOOL sticky     = getBooleanForKey(noteDict, GROWL_NOTIFICATION_STICKY);
	//NSString *ident = getObjectForKey(noteDict, GROWL_NOTIFICATION_IDENTIFIER);
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
	GrowlSmokeWindowView *view = [[self window] contentView];
	[view setPriority:priority];
	[view setTitle:title isHTML:titleHTML];
	[view setText:text isHTML:textHTML];
	[view setIcon:icon];
	[view sizeToFit];
	
	NSRect viewFrame = [view frame];
	[panel setFrame:viewFrame display:NO];
	NSRect screen = [[self screen] visibleFrame];
	[panel setFrameTopLeftPoint:NSMakePoint(NSMaxX(screen) - NSWidth(viewFrame) - GrowlSmokePadding,
											NSMaxY(screen) - GrowlSmokePadding - depth)];
}

- (unsigned) depth {
	return depth;
}

@end
