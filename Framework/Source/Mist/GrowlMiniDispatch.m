//
//  GrowlMiniDispatch.m
//
//  Created by Rachel Blackman on 7/13/11.
//

#import "GrowlMiniDispatch.h"
#import "GrowlMistWindowController.h"
#import "GrowlPositionController.h"
#import "GrowlPositioningDefines.h"

@implementation GrowlMiniDispatch

@synthesize delegate;
@synthesize positionController;

- (id)init {
	self = [super init];
	if (self) {
		windows = [[NSMutableSet alloc] init];
		GrowlPositionController *controller = [[GrowlPositionController alloc] initWithScreenFrame:[[NSScreen mainScreen] visibleFrame]];
		self.positionController = controller;
		[controller release];
	
		__block GrowlMiniDispatch *blockSelf = self;
		void (^screenChangeBlock)(NSNotification*) = ^(NSNotification *note){
			CGRect newRect = [[NSScreen mainScreen] visibleFrame];
			CGRect currentRect = [blockSelf.positionController screenFrame];
			if(!CGRectEqualToRect(newRect, currentRect))
			{
				if([blockSelf.positionController isFrameFree:[blockSelf.positionController screenFrame]])
					[blockSelf.positionController setScreenFrame:newRect];
				else{
					[blockSelf.positionController setUpdateFrame:YES];
					[blockSelf.positionController setNewFrame:newRect];
				}
			}
		};
		
		[[NSNotificationCenter defaultCenter] addObserverForName:NSApplicationDidChangeScreenParametersNotification
																		  object:nil
																			queue:[NSOperationQueue mainQueue]
																	 usingBlock:screenChangeBlock];
	}
	return self;
}

- (void)dealloc {
	[windows release];
	[positionController release]; positionController = nil;
	[queuedWindows release]; queuedWindows = nil;
	[super dealloc];
}

- (void)queueWindow:(GrowlMistWindowController*)newWindow
{
	if(!queuedWindows)
		queuedWindows = [[NSMutableArray alloc] init];
	[queuedWindows addObject:newWindow];
}

- (BOOL)insertWindow:(GrowlMistWindowController*)newWindow
{	
	CGSize displaySize = [newWindow window].frame.size;
	displaySize.width += 10.0f;
	displaySize.height += 10.0f;
	CGRect found = [positionController canFindSpotForSize:displaySize
												  startingInPosition:GrowlTopRightCorner];
	if(!CGRectEqualToRect(found, CGRectZero)){
		[positionController occupyRect:found];
		[[newWindow window] setFrameOrigin:found.origin];
		[windows addObject:newWindow];
		[newWindow fadeIn];
		return YES;
	}else{
		return NO;
	}
}

- (void)dequeueWindows
{
	if(!queuedWindows)
		return;
	
	NSMutableArray *toRemove = [NSMutableArray array];
	
	//We display them in order of receipt, if there is a note it can't display right now, we break and will catch it when there is space
	[queuedWindows enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		if([self insertWindow:obj]){
			[toRemove addObject:obj];
		}else
			*stop = YES;
	}];
	
	//Mutable arrays don't like being mutated while being enumerated
	if([toRemove count] > 0)
		[queuedWindows removeObjectsInArray:toRemove];
	
	if([queuedWindows count] == 0){
		[queuedWindows release];
		queuedWindows = nil;
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
	
	if(![self insertWindow:mistWindow])
		[self queueWindow:mistWindow];
	[mistWindow release];
}

- (void)clearWindowFrame:(GrowlMistWindowController*)window {
	CGRect padded = [window window].frame;
	padded.size.width += 10.0f;
	padded.size.height += 10.0f;
	[positionController vacateRect:padded];
	
	if([positionController updateFrame] && [positionController isFrameFree:[positionController screenFrame]]){
		[positionController setUpdateFrame:NO];
		[positionController setScreenFrame:[positionController newFrame]];
	}
}

- (void)mistNotificationDismissed:(GrowlMistWindowController *)window
{
	[window retain];
	[windows removeObject:window];
	[self clearWindowFrame:window];
	
	[self dequeueWindows];
	
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
	[self clearWindowFrame:window];
	
	[self dequeueWindows];
	
	id info = window.userInfo;
	
	// Callback to original delegate!
	if ([[self delegate] respondsToSelector:@selector(growlNotificationWasClicked:)])
		[[self delegate] growlNotificationWasClicked:info];
	[window release];
}

- (void)closeAllNotifications:(GrowlMistWindowController *)window
{
	[windows enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
		if([obj respondsToSelector:@selector(mistViewDismissed:)])
			[obj mistViewDismissed:YES];
	}];
}

@end
