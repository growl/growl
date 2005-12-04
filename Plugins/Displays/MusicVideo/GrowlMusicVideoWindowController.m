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
	//[panel setReleasedWhenClosed:YES]; // ignored for windows owned by window controllers.
	[panel setDelegate:self];

		GrowlMusicVideoWindowView *view = [[GrowlMusicVideoWindowView alloc] initWithFrame:panelFrame];

	[view setTarget:self];
	[view setAction:@selector(notificationClicked:)]; // Not used for now
	[view setNeedsDisplay:YES];

	[panel setContentView:view]; // retains subview
	//[subview release];

	//[subview setPriority:prio];
	//[subview setTitle:title];
	//[self setText:text];
	//[subview setIcon:icon];
	
	NSRect viewFrame = [view frame];
	[panel setFrameTopLeftPoint:NSMakePoint(NSMaxX(screen) + NSWidth(viewFrame),
											NSMaxY(screen) - depth)];
	return ([super initWithWindow:panel]);
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
	GrowlMusicVideoWindowView *view = [[self window] contentView];
	[view setPriority:priority];
	[view setTitle:title];//isHTML:titleHTML];
	[view setText:text];// isHTML:textHTML];
	[view setIcon:icon];
	//[view sizeToFit];
	
	NSRect viewFrame = [view frame];
	[panel setFrame:viewFrame display:NO];
	NSRect screen = [[self screen] visibleFrame];
	//frameY = -frameHeight;
	//[subview translateOriginToPoint:NSMakePoint(0.0f, frameY)];
	//[panel setFrameTopLeftPoint:NSMakePoint(NSMaxX(screen) - NSWidth(viewFrame),
	//										NSMaxY(screen) - depth)];
	[panel setFrameTopLeftPoint:NSMakePoint(NSMaxX(screen) - NSWidth(viewFrame) - 0,
											NSMaxY(screen) - 0 - depth)];

	NSLog(@"%s %f %f %f %f\n", __FUNCTION__, [panel frame].origin.x, [panel frame].origin.y, [panel frame].size.height, [panel frame].size.width);

}

- (unsigned) depth {
	return depth;
}

/*
- (id) initWithTitle:(NSString *)title text:(NSString *)text icon:(NSImage *)icon priority:(int)prio identifier:(NSString *)ident {
	identifier = [ident retain];

	int sizePref = MUSICVIDEO_SIZE_NORMAL;
	float duration = MUSICVIDEO_DEFAULT_DURATION;

	unsigned screenNumber = 0U;
	READ_GROWL_PREF_INT(MUSICVIDEO_SCREEN_PREF, MusicVideoPrefDomain, &screenNumber);
	[self setScreen:[[NSScreen screens] objectAtIndex:screenNumber]];

	NSRect sizeRect;
	NSRect screen = [[self screen] frame];
	READ_GROWL_PREF_INT(MUSICVIDEO_SIZE_PREF, MusicVideoPrefDomain, &sizePref);
	sizeRect.origin = screen.origin;
	sizeRect.size.width = screen.size.width;
	if (sizePref == MUSICVIDEO_SIZE_HUGE)
		sizeRect.size.height = 192.0f;
	else
		sizeRect.size.height = 96.0f;
	frameHeight = sizeRect.size.height;
	READ_GROWL_PREF_FLOAT(MUSICVIDEO_DURATION_PREF, MusicVideoPrefDomain, &duration);
	READ_GROWL_PREF_INT(MUSICVIDEO_SIZE_PREF, MusicVideoPrefDomain, &sizePref);
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
	//[panel setReleasedWhenClosed:YES]; // ignored for windows owned by window controllers.
	//[panel setDelegate:self];

	subview = [[GrowlMusicVideoWindowView alloc] initWithFrame:panelFrame];

	[subview setTarget:self];
	[subview setAction:@selector(notificationClicked:)]; // Not used for now

	[panel setContentView:subview]; // retains subview
	[subview release];

	[subview setPriority:prio];
	[subview setTitle:title];
	[self setText:text];
	[subview setIcon:icon];

	frameY = -frameHeight;
	[subview translateOriginToPoint:NSMakePoint(0.0f, frameY)];

	if ((self = [super initWithWindow:panel])) {
		autoFadeOut = YES;
		[self setDisplayDuration:duration];
		priority = prio;
		animationDuration = 0.25;
	}

	return self;
}*/

#pragma mark -
#pragma mark Fading

/*- (void) stopFadeIn {
	if (!doFadeIn) {
		[subview translateOriginToPoint:NSMakePoint(0.0f, -frameY)];
		frameY = 0.0f;
		[subview setNeedsDisplay:YES];
	}
	[super stopFadeIn];
}

- (void) fadeInAnimation:(double)progress {
	float oldY = frameY;
	frameY = frameHeight * (progress - 1.0f);
	[subview translateOriginToPoint:NSMakePoint(0.0f, frameY - oldY)];
	NSRect dirtyRect = [subview bounds];
	dirtyRect.size.height = ceilf(dirtyRect.size.height+frameY);
	[subview setNeedsDisplayInRect:dirtyRect];
}

- (void) fadeOutAnimation:(double)progress {
	float oldY = frameY;
	frameY = -frameHeight * progress;
	[subview translateOriginToPoint:NSMakePoint(0.0f, frameY - oldY)];
	NSRect dirtyRect = [subview bounds];
	dirtyRect.size.height = ceilf(dirtyRect.size.height+oldY);
	[subview setNeedsDisplayInRect:dirtyRect];
}*/

#pragma mark -

- (void) dealloc {
	[identifier    release];
	[[self window] release];
	[super dealloc];
}

#pragma mark Accessors

- (NSString *) identifier {
	return identifier;
}

#pragma mark -

/*- (int) priority {
	return priority;
}

- (void) setPriority:(int)newPriority {
	priority = newPriority;
	[subview setPriority:priority];
}

- (void) setTitle:(NSString *)title {
	[subview setTitle:title];
}

- (void) setText:(NSString *)text {
	// Sanity check to unify line endings
	NSMutableString	*tempText = [[NSMutableString alloc] initWithString:text];
	[tempText replaceOccurrencesOfString:@"\r"
							  withString:@"\n"
								 options:nil
								   range:NSMakeRange(0U, [tempText length])];
	[subview setText:tempText];
	[tempText release];
}

- (void) setIcon:(NSImage *)icon {
	[subview setIcon:icon];
}*/

@end
