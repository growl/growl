//
//  GrowlMiniDispatch.m
//  SmokeLite
//
//  Created by Rachel Blackman on 7/13/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "GrowlMiniDispatch.h"
#import "GrowlMistWindowController.h"

@implementation GrowlMiniDispatch

@synthesize delegate;

- (id)init {
	self = [super init];
	if (self) {
		windows = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void)dealloc {
	[windows release];
	[super dealloc];
}

- (void)animationDidEnd:(NSAnimation *)animation {
	[repositionAnimation release];
	repositionAnimation = nil;
}

- (void)animationDidStop:(NSAnimation *)animation {
	
}

- (void)repositionAllWindows {
	// Calculate positions of all windows.
	
	NSRect screenRect = [[NSScreen mainScreen] visibleFrame];
	NSPoint upperRight = NSMakePoint((screenRect.origin.x + screenRect.size.width - 10), (screenRect.origin.y + screenRect.size.height - 10));
	
	NSMutableArray *animations = [NSMutableArray array];
	
	BOOL hasSelected = NO;
	GrowlMistWindowController *windowWalk;
	
	for (windowWalk in windows) {
		if (windowWalk.selected)
			hasSelected = YES;
	}
	
	if (hasSelected) {
		[self performSelector:@selector(repositionAllWindows) withObject:nil afterDelay:1];
		return;
	}

	
	for (windowWalk in windows) {
		NSRect windowFrame = [[windowWalk window] frame];
		NSRect newWindowFrame = windowFrame;
		newWindowFrame.origin.x = upperRight.x - newWindowFrame.size.width;
		newWindowFrame.origin.y = upperRight.y - newWindowFrame.size.height;
		
		if (!NSContainsRect(screenRect, newWindowFrame)) {
			// Scoot up and over!
			newWindowFrame.origin.y = screenRect.origin.y + screenRect.size.height - 10;
			newWindowFrame.origin.x -= newWindowFrame.size.width + 10;
		}
		
		upperRight.x = newWindowFrame.origin.x + newWindowFrame.size.width;
		upperRight.y = newWindowFrame.origin.y - 10;

		if (!NSEqualRects(windowFrame, newWindowFrame)) {
			if (windowWalk.visible) {
				// Scoot us to the new position
				NSDictionary *animDict = [NSDictionary dictionaryWithObjectsAndKeys:
												[windowWalk window], NSViewAnimationTargetKey,
												[NSValue valueWithRect:newWindowFrame], NSViewAnimationEndFrameKey,
										  nil];
				[animations addObject:animDict];
			}
			else {
				// We haven't appeared yet, just push us.
				[[windowWalk window] setFrame:newWindowFrame display:NO];
			}
		}
	}
	
	if ([animations count]) {
		if (repositionAnimation) {
			[repositionAnimation stopAnimation];
			[repositionAnimation release];
			repositionAnimation = nil;
		}
		
		repositionAnimation = [[NSViewAnimation alloc] initWithViewAnimations:animations];
		[repositionAnimation setDelegate:self];
		[repositionAnimation setDuration:0.3];
		[repositionAnimation setAnimationBlockingMode:NSAnimationNonblocking];
		[repositionAnimation setFrameRate:0.0];
		[repositionAnimation startAnimation];
	}
}

- (void)displayNotification:(NSDictionary *)notification {
	NSString *title = [notification objectForKey:GROWL_NOTIFICATION_TITLE];
	NSString *text = [notification objectForKey:GROWL_NOTIFICATION_DESCRIPTION];
	BOOL sticky = [[notification objectForKey:GROWL_NOTIFICATION_STICKY] boolValue];
	NSDictionary *userInfo = [notification objectForKey:GROWL_NOTIFICATION_CLICK_CONTEXT];
    NSImage *image = nil;

    NSData	*iconData = [notification objectForKey:GROWL_NOTIFICATION_ICON_DATA];
    if (!iconData)
        iconData = [notification objectForKey:GROWL_NOTIFICATION_APP_ICON_DATA];

    if (!iconData) {
        image = [NSApp applicationIconImage];
    }
    else if ([iconData isKindOfClass:[NSImage class]]) {
        image = (NSImage *)iconData;
    }
    else {
        image = [[[NSImage alloc] initWithData:iconData] autorelease];
    }
	
	GrowlMistWindowController *mistWindow = [[GrowlMistWindowController alloc] initWithNotificationTitle:title 
																									text:text
																								   image:image 
																								  sticky:sticky 
																								userInfo:userInfo 
																								delegate:self];
	
	[windows addObject:mistWindow];
	[self repositionAllWindows];
	[mistWindow fadeIn];
	[mistWindow release];
}

- (void)mistNotificationDismissed:(GrowlMistWindowController *)window
{
	[window retain];
	[windows removeObject:window];
	
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(repositionAllWindows) object:nil];
	[self performSelector:@selector(repositionAllWindows) withObject:nil afterDelay:0.5];
	
	id info = window.userInfo;
	
	// Callback to original delegate!
	if ([[self delegate] respondsToSelector:@selector(growlNotificationTimedOut:)])
		[[self delegate] growlNotificationTimedOut:info];
	[window release];
}

- (void)mistNotificationClicked:(GrowlMistWindowController *)window
{
	[window retain];
	[windows removeObject:window];

	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(repositionAllWindows) object:nil];
	[self performSelector:@selector(repositionAllWindows) withObject:nil afterDelay:0.5];
	
	id info = window.userInfo;

	// Callback to original delegate!
	if ([[self delegate] respondsToSelector:@selector(growlNotificationWasClicked:)])
		[[self delegate] growlNotificationWasClicked:info];
	[window release];
}


@end
