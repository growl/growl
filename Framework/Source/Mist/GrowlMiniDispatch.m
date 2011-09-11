//
//  GrowlMiniDispatch.m
//
//  Created by Rachel Blackman on 7/13/11.
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

- (void)queueWindow:(GrowlMistWindowController*)newWindow
{
   if(!queuedWindows)
      queuedWindows = [[NSMutableArray alloc] init];
   [queuedWindows addObject:newWindow];
}

- (BOOL)insertWindow:(GrowlMistWindowController*)newWindow
{
   __block CGRect screenRect = NSRectToCGRect([[NSScreen mainScreen] visibleFrame]);
	__block CGPoint upperRight = {(screenRect.origin.x + screenRect.size.width - 10), (screenRect.origin.y + screenRect.size.height - 10)};
   __block CGRect newWindowFrame = NSRectToCGRect([[newWindow window] frame]);
   newWindowFrame.origin.x = upperRight.x - newWindowFrame.size.width;
   newWindowFrame.origin.y = upperRight.y - newWindowFrame.size.height;
   
   __block NSUInteger indexToInsert = NSNotFound;
   __block NSInteger skipCount = 0;
   __block NSInteger displayed = 1;
   
   //We can insert right at the default start if there aren't any mist windows at the moment
   if([windows count] > 0)
   {
      [windows enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
         CGRect currentFrame = [[obj window] frame];
         if(skipCount > 0){
            skipCount--;
         }else if (currentFrame.origin.x > newWindowFrame.origin.x){
            /* Current is in a column to the right of the column we are looking at, 
             *  skip it and move to the next since we didn't fit at bottom of screen*/
            skipCount++;
         }else if (currentFrame.origin.x < newWindowFrame.origin.x){
            /* Current is in a column to the left of the column we are looking at
             * this should only happen if the column is empty and free*/
            *stop = YES;
            indexToInsert = idx;
         }else{
            BOOL intersect = CGRectIntersectsRect(newWindowFrame, currentFrame);
            BOOL moved = NO;
            if(intersect){
               newWindowFrame.origin.y = currentFrame.origin.y - newWindowFrame.size.height - 10;
               moved = YES;
            }
            
            /* Is current or next position off the bottom? */
            if(newWindowFrame.origin.y - 10 < 0){
               newWindowFrame.origin.x -= (newWindowFrame.size.width + 10);
               newWindowFrame.origin.y = upperRight.y - newWindowFrame.size.height;
               moved = YES;
            }
            
            /* Is it now off the screen? */
            if(newWindowFrame.origin.x < 0){
               NSLog(@"No screen real estate left, putting in queue");
               *stop = YES;
               indexToInsert = [windows count];
               displayed = -1;
            }else if(!moved){
               /* We are on the screen, we haven't moved since the test,
                * and we are not occupying the current inspection frame's space
                * We assume this is an ok place to stop, it is possibly naive */
               *stop = YES;
               indexToInsert = idx;
            }
         }
      }];
   }
   
   if(displayed < 0){
      return NO;
   }else{
      if([windows count] == 0)
         [windows addObject:newWindow];
      else if(indexToInsert >= [windows count])
         [windows addObject:newWindow];
      else
         [windows insertObject:newWindow atIndex:indexToInsert];
      [[newWindow window] setFrame:newWindowFrame display:NO];
      [newWindow fadeIn];
   }
   return YES;
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
         [obj fadeIn];
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

- (void)mistNotificationDismissed:(GrowlMistWindowController *)window
{
	[window retain];
	[windows removeObject:window];
	
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

   [self dequeueWindows];
	
	id info = window.userInfo;

	// Callback to original delegate!
	if ([[self delegate] respondsToSelector:@selector(growlNotificationWasClicked:)])
		[[self delegate] growlNotificationWasClicked:info];
	[window release];
}

- (void)closeAllNotifications:(GrowlMistWindowController *)window
{
   [windows enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      if([obj respondsToSelector:@selector(mistViewDismissed:)])
         [obj mistViewDismissed:NO];
   }];
}

@end
