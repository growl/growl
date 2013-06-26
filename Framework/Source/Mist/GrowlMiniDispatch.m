//
//  GrowlMiniDispatch.m
//
//  Created by Rachel Blackman on 7/13/11.
//

#import "GrowlMiniDispatch.h"
#import "GrowlMistWindowController.h"
#import "GrowlPositionController.h"
#import "GrowlPositioningDefines.h"

#import "GrowlDefines.h"
#import "GrowlDefinesInternal.h"
#import "GrowlApplicationBridge.h"
#import "GrowlApplicationBridge_Private.h"
#import "GrowlNote.h"
#import "GrowlNote_Private.h"

@implementation GrowlMiniDispatch

@synthesize windowDictionary;
@synthesize positionController;

+ (GrowlMiniDispatch*)sharedDispatch {
   static GrowlMiniDispatch *_sharedDispatch = nil;
   static dispatch_once_t onceToken;
   dispatch_once(&onceToken, ^{
      _sharedDispatch = [[GrowlMiniDispatch alloc] init];
   });
   return _sharedDispatch;
}

- (id)init {
	self = [super init];
	if (self) {
      self.windowDictionary = [NSMutableDictionary dictionary];
      
      if(NSClassFromString(@"NSUserNotificationCenter")){
         [[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:self];
      }else{
         GrowlPositionController *controller = [[GrowlPositionController alloc] initWithScreenFrame:[[NSScreen mainScreen] visibleFrame]];
         self.positionController = controller;
         [controller release];
      }
	
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
   [windowDictionary release]; windowDictionary = nil;
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
		[windowDictionary setObject:newWindow forKey:[newWindow uuid]];
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

+ (BOOL)copyNotificationCenter {
   BOOL useNotificationCenter = (NSClassFromString(@"NSUserNotificationCenter") != nil);
   BOOL alwaysCopyNC = NO;
   
   // Do we have notification center disabled?  (Only valid if it hasn't been turned on directly in Growl.)
   if (![[GrowlApplicationBridge sharedBridge] useNotificationCenterAlways]) {
      if (useNotificationCenter && [[NSUserDefaults standardUserDefaults] valueForKey:GROWL_FRAMEWORK_NOTIFICATIONCENTER_ENABLE])
         useNotificationCenter = [[NSUserDefaults standardUserDefaults] boolForKey:GROWL_FRAMEWORK_NOTIFICATIONCENTER_ENABLE];
   }
   
   // If we have notification center set to always-on, we must send.
   if (useNotificationCenter && ([[GrowlApplicationBridge sharedBridge] useNotificationCenterAlways]
                                 || [[NSUserDefaults standardUserDefaults] valueForKey:GROWL_FRAMEWORK_NOTIFICATIONCENTER_ALWAYS])) {
      alwaysCopyNC = ([[GrowlApplicationBridge sharedBridge] useNotificationCenterAlways] ||
                      ![[NSUserDefaults standardUserDefaults] boolForKey:GROWL_FRAMEWORK_NOTIFICATIONCENTER_ALWAYS]);
   }
   return alwaysCopyNC;
}
- (BOOL)displayNotification:(GrowlNote *)note force:(BOOL)force {
   BOOL result = [windowDictionary objectForKey:note.noteUUID] != nil;
   if(!result && NSClassFromString(@"NSUserNotificationCenter") != nil){
      result = [self sendNoteToApple:note force:force];
   }
   if(!result){
      result = [self sendNoteToMist:note force:force];
   }
   return result;
}

- (BOOL)sendNoteToMist:(GrowlNote*)note force:(BOOL)force {
   NSDictionary *noteDict = [note noteDictionary];
   
   if(!force){
      BOOL defaultOnly = YES;
      if([[NSUserDefaults standardUserDefaults] valueForKey:GROWL_FRAMEWORK_MIST_DEFAULT_ONLY])
         defaultOnly = [[[NSUserDefaults standardUserDefaults] valueForKey:GROWL_FRAMEWORK_MIST_DEFAULT_ONLY] boolValue];
      
      if (![[GrowlApplicationBridge sharedBridge] isNotificationDefaultEnabled:noteDict] && defaultOnly)
         return NO;
   }
   
   dispatch_async(dispatch_get_main_queue(), ^{
      NSString *title = [noteDict objectForKey:GROWL_NOTIFICATION_TITLE];
      NSString *text = [noteDict objectForKey:GROWL_NOTIFICATION_DESCRIPTION];
      BOOL sticky = [[noteDict objectForKey:GROWL_NOTIFICATION_STICKY] boolValue];
      NSImage *image = nil;
      
      NSData	*iconData = [noteDict objectForKey:GROWL_NOTIFICATION_ICON_DATA];
      if (!iconData)
         iconData = [noteDict objectForKey:GROWL_NOTIFICATION_APP_ICON_DATA];
      
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
                                                                                                      uuid:[note noteUUID]
                                                                                                  delegate:self];
      
      if(![self insertWindow:mistWindow])
         [self queueWindow:mistWindow];
      [mistWindow release];
   });
   return YES;
}

- (BOOL)sendNoteToApple:(GrowlNote*)note force:(BOOL)force {
   // If we're not on 10.8, there's no point in doing this.
   if (!NSClassFromString(@"NSUserNotificationCenter"))
      return NO;
   
   NSDictionary *dict = note.noteDictionary;
   
   if(!force){
      BOOL defaultOnly = YES;
      if([[NSUserDefaults standardUserDefaults] valueForKey:GROWL_FRAMEWORK_NOTIFICATIONCENTER_DEFAULT_ONLY])
         defaultOnly = [[[NSUserDefaults standardUserDefaults] valueForKey:GROWL_FRAMEWORK_NOTIFICATIONCENTER_DEFAULT_ONLY] boolValue];
      
      if (![[GrowlApplicationBridge sharedBridge] isNotificationDefaultEnabled:dict] && defaultOnly)
         return NO;
   }
   
   dispatch_async(dispatch_get_main_queue(), ^{
      NSMutableDictionary *notificationDict = [[@{GROWL_NOTIFICATION_INTERNAL_ID: note.noteUUID} mutableCopy] autorelease];
      if ([dict objectForKey:GROWL_NOTIFICATION_CLICK_CONTEXT])
         [notificationDict setObject:[dict objectForKey:GROWL_NOTIFICATION_CLICK_CONTEXT] forKey:GROWL_NOTIFICATION_CLICK_CONTEXT];
      
      NSUserNotification *appleNotification = [[NSUserNotification alloc] init];
      appleNotification.title = [dict objectForKey:GROWL_NOTIFICATION_TITLE];
      appleNotification.informativeText = [dict objectForKey:GROWL_NOTIFICATION_DESCRIPTION];
      appleNotification.userInfo = notificationDict;
      appleNotification.hasActionButton = NO;
      
      if ([dict objectForKey:GROWL_NOTIFICATION_BUTTONTITLE_ACTION]) {
         appleNotification.hasActionButton = YES;
         appleNotification.actionButtonTitle = [dict objectForKey:GROWL_NOTIFICATION_BUTTONTITLE_ACTION];
      }
      
      if ([dict objectForKey:GROWL_NOTIFICATION_BUTTONTITLE_CANCEL])
         appleNotification.otherButtonTitle = [dict objectForKey:GROWL_NOTIFICATION_BUTTONTITLE_CANCEL];
      
      [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:appleNotification];
      [windowDictionary setObject:appleNotification forKey:note.noteUUID];
      
      [appleNotification release];
   });
   
   return YES;
}

- (void)cancelNotification:(GrowlNote*)note {
   dispatch_async(dispatch_get_main_queue(), ^{
      id toCancel = [windowDictionary objectForKey:note.noteUUID];
      if([toCancel isKindOfClass:[NSUserNotification class]]){
         NSUserNotification *notification = (NSUserNotification*)toCancel;
         [[NSUserNotificationCenter defaultUserNotificationCenter] removeDeliveredNotification:notification];
      }else if([toCancel isKindOfClass:[GrowlMistWindowController class]]){
         if([toCancel respondsToSelector:@selector(mistViewDismissed:)])
            [toCancel mistViewDismissed:YES];
      }
      [windowDictionary removeObjectForKey:note.noteUUID];
   });
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

- (void)mistWindow:(GrowlMistWindowController*)window statusUpdate:(GrowlNoteStatus)status {
   [window retain];
	[windowDictionary removeObjectForKey:[window uuid]];
	[self clearWindowFrame:window];
	
	[self dequeueWindows];
	
   GrowlNote *note = [[GrowlApplicationBridge sharedBridge] noteForUUID:[window uuid]];
   [note handleStatusUpdate:status];
	[window release];
}
- (void)mistNotificationDismissed:(GrowlMistWindowController *)window
{
   [self mistWindow:window statusUpdate:GrowlNoteTimedOut];
}

- (void)mistNotificationClicked:(GrowlMistWindowController *)window
{
   [self mistWindow:window statusUpdate:GrowlNoteClicked];
}

- (void)closeAllNotifications:(GrowlMistWindowController *)window
{
   [windowDictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
      //For now this should only be called by GrowlMistWindowController
      if([obj isKindOfClass:[GrowlMistWindowController class]]){
         if([obj respondsToSelector:@selector(mistViewDismissed:)])
            [obj mistViewDismissed:YES];
      }
   }];
}

#pragma mark NSUserNotificationCenter delegate methods;


- (void)userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification
{
   NSString *uuid = [[notification userInfo] objectForKey:GROWL_NOTIFICATION_INTERNAL_ID];
   GrowlNote *note = [[[GrowlApplicationBridge sharedBridge] noteForUUID:uuid] retain];
   [windowDictionary removeObjectForKey:uuid];
   
   if(notification.activationType == NSUserNotificationActivationTypeActionButtonClicked) {
      [note handleStatusUpdate:GrowlNoteActionClicked];
   }else if (notification.activationType == NSUserNotificationActivationTypeContentsClicked) {
      [note handleStatusUpdate:GrowlNoteClicked];
   }else {
      [note handleStatusUpdate:GrowlNoteTimedOut];
   }
   // Remove the notification, so it doesn't sit around forever.
   [center removeDeliveredNotification:notification];
   [note release];
}

- (void)expireNotification:(NSDictionary *)dict
{
   NSUserNotification *notification = [dict objectForKey:@"notification"];
   NSUserNotificationCenter *center = [dict objectForKey:@"center"];
   
   NSString *uuid = [[notification userInfo] objectForKey:GROWL_NOTIFICATION_INTERNAL_ID];
   GrowlNote *note = [[GrowlApplicationBridge sharedBridge] noteForUUID:uuid];
   [center removeDeliveredNotification:notification];
   
   [windowDictionary removeObjectForKey:uuid];
   [note handleStatusUpdate:GrowlNoteTimedOut];
}

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didDeliverNotification:(NSUserNotification *)notification
{
   // If we're not sticky, let's wait about 60 seconds and then remove the notification.
   if (![[[notification userInfo] objectForKey:GROWL_NOTIFICATION_STICKY] boolValue]) {
      // (This should probably be made nicer down the road, but right now this works for a first testing cut.)
      
      // Make sure we're using the same center, though this should always be the default.
      NSDictionary *dict = [[NSDictionary alloc] initWithObjectsAndKeys:notification,@"notification",center,@"center",nil];
      
      NSInteger lifetime = 120;
      if ([[NSUserDefaults standardUserDefaults] valueForKey:GROWL_FRAMEWORK_NOTIFICATIONCENTER_DURATION]) {
         lifetime = [[NSUserDefaults standardUserDefaults] integerForKey:GROWL_FRAMEWORK_NOTIFICATIONCENTER_DURATION];
      }
      
      // If the duration is set to 0, we never manually expire notifications
      if (lifetime) {
         [self performSelector:@selector(expireNotification:) withObject:dict afterDelay:lifetime];
      }
      
      [dict release];
   }
}

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification
{
   // This will be called if the notification is being omitted.  This happens in
   // two cases: first, if the application is already focused, and second if
   // the computer is in a DND mode.  For now, we're going to just return YES to
   // mimic Growl behavior; the program can sort out when/if it wants to show
   // notifications.  Down the road, we may want to make this logic fancier.
   
   return YES;
}

@end
