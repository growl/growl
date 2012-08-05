//
//  GrowlApplicationBridge.m
//  Growl
//
//  Created by Evan Schoenberg on Wed Jun 16 2004.
//  Copyright 2004-2006 The Growl Project. All rights reserved.
//

#import "GrowlApplicationBridge.h"
#include "CFURLAdditions.h"
#import "GrowlDefinesInternal.h"
#import "GrowlPathUtilities.h"
#import "GrowlProcessUtilities.h"
#import "GrowlImageAdditions.h"
#if !GROWLHELPERAPP
#import "GrowlMiniDispatch.h"
#endif

#import "GrowlApplicationBridgeRegistrationAttempt.h"
#import "GrowlApplicationBridgeNotificationAttempt.h"
#import "GrowlGNTPRegistrationAttempt.h"
#import "GrowlGNTPNotificationAttempt.h"
#import "GrowlXPCCommunicationAttempt.h"
#import "GrowlXPCRegistrationAttempt.h"
#import "GrowlXPCNotificationAttempt.h"

#import <ApplicationServices/ApplicationServices.h>

// Enable/disable Mist entirely
#define GROWL_FRAMEWORK_MIST_ENABLE @"com.growl.growlframework.mist.enabled"

// Enable Mist only for defaults
#define GROWL_FRAMEWORK_MIST_DEFAULT_ONLY @"com.growl.growlframework.mist.defaultonly"

// Enable/disable Apple Notification Center entirely
#define GROWL_FRAMEWORK_NOTIFICATIONCENTER_ENABLE @"com.growl.growlframework.nsusernotification.enabled"

// Enable Apple Notification Center only for defaults
#define GROWL_FRAMEWORK_NOTIFICATIONCENTER_DEFAULT_ONLY @"com.growl.growlframework.nsusernotification.defaultonly"

// Always CC Notification Center on all notices
#define GROWL_FRAMEWORK_NOTIFICATIONCENTER_ALWAYS @"com.growl.growlframework.nsusernotification.always"

// Set a lifetime, in seconds, for Apple notification center notices to live. 0 means
// they only will go away if removed by the user.  Default is 120 seconds.
#define GROWL_FRAMEWORK_NOTIFICATIONCENTER_DURATION @"com.growl.growlframework.nsusernotification.lifetime"

// This may not be the best solution. Rather not use __has_feature(arc). 
#ifdef __clang_major__ 
#if __clang_major__ > 2
#define AUTORELEASEPOOL_START @autoreleasepool {
#define AUTORELEASEPOOL_END }
#endif
#else
#define AUTORELEASEPOOL_START NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
#define AUTORELEASEPOOL_END [pool drain];
#endif

@interface GrowlApplicationBridge (PRIVATE)

/*!	@method	_applicationNameForGrowlSearchingRegistrationDictionary:
 *	@abstract Obtain the name of the current application.
 *	@param regDict	The dictionary to search, or <code>nil</code> not to.
 *	@result	The name of the current application.
 *	@discussion	Does not call +bestRegistrationDictionary, and is therefore safe to call from it.
 */
+ (NSString *) _applicationNameForGrowlSearchingRegistrationDictionary:(NSDictionary *)regDict;
/*!	@method	_applicationNameForGrowlSearchingRegistrationDictionary:
 *	@abstract Obtain the icon of the current application.
 *	@param regDict	The dictionary to search, or <code>nil</code> not to.
 *	@result	The icon of the current application, in IconFamily format (same as is used in 'icns' resources and .icns files).
 *	@discussion	Does not call +bestRegistrationDictionary, and is therefore safe to call from it.
 */
+ (NSData *) _applicationIconDataForGrowlSearchingRegistrationDictionary:(NSDictionary *)regDict;

+ (BOOL) _growlIsReachableUpdateCache:(BOOL)update;
+ (void) _checkSandbox;
+ (void) _fireMiniDispatch:(NSDictionary*)growlDict;
+ (void) _fireAppleNotificationCenter:(NSDictionary*)growlDict;

+ (void) _growlNotificationCenterOn:(NSNotification *)notification;
+ (void) _growlNotificationCenterOff:(NSNotification *)notification;

@end

@class GrowlAppleNotificationDelegate;

static NSDictionary *cachedRegistrationDictionary = nil;
static NSString	*appName = nil;
static NSData	*appIconData = nil;

#if !GROWLHELPERAPP
static GrowlMiniDispatch *miniDispatch = nil;
#endif

#if !GROWLHELPERAPP && defined(MAC_OS_X_VERSION_10_8) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_8
static GrowlAppleNotificationDelegate *appleNotificationDelegate = nil;
#endif

static id<GrowlApplicationBridgeDelegate> delegate = nil;
static BOOL		growlLaunched = NO;

static BOOL registeredWithGrowl = NO;
//Do not touch the attempts variable directly! Use the +attempts method every time, to ensure that the array exists.
static NSMutableArray *_attempts = nil;

//used primarily by GIP, but could be useful elsewhere.
static BOOL		registerWhenGrowlIsReady = NO;

static BOOL    attemptingToRegister = NO;

static BOOL    sandboxed = NO;
static BOOL    networkClient = NO;
static BOOL    hasGNTP = NO;

static BOOL    shouldUseBuiltInNotifications = YES;
static BOOL    shouldUseNotificationCenterAlways = NO;

static dispatch_queue_t notificationQueue_Queue;

static struct {
    unsigned int growlNotificationWasClicked : 1;
    unsigned int growlNotificationTimedOut : 1;
    unsigned int registrationDictionaryForGrowl : 1;
    unsigned int applicationNameForGrowl : 1;
    unsigned int applicationIconForGrowl : 1;
    unsigned int applicationIconDataForGrowl : 1;
    unsigned int growlIsReady : 1;
    unsigned int hasNetworkClientEntitlement : 1;
} _delegateRespondsTo;

#pragma mark -

#if defined(MAC_OS_X_VERSION_10_8) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_8

// Obnoxiously, the Mountain Lion notification center requires an
// instanced class as a delegate or will not work.  So, here we are
// with this.
@interface GrowlAppleNotificationDelegate : NSObject <NSUserNotificationCenterDelegate> {
   NSMutableArray       *pendingNotifications;
}
@end

@implementation GrowlAppleNotificationDelegate

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification
{
   AUTORELEASEPOOL_START
   // Toss the click context back to the hosting app.
   if([[GrowlApplicationBridge growlDelegate] respondsToSelector:@selector(growlNotificationWasClicked:)])
      [[GrowlApplicationBridge growlDelegate] growlNotificationWasClicked:[[notification userInfo] objectForKey:GROWL_NOTIFICATION_CLICK_CONTEXT]];
   // Remove the notification, so it doesn't sit around forever.
   [center removeDeliveredNotification:notification];
   AUTORELEASEPOOL_END
}

- (void)expireNotification:(NSDictionary *)dict
{
   NSUserNotification *notification = [dict objectForKey:@"notification"];
   NSUserNotificationCenter *center = [dict objectForKey:@"center"];
   
   // Remove the notification
   [center removeDeliveredNotification:notification];
   
   // Send the 'timed out' call to the hosting application
   if([[GrowlApplicationBridge growlDelegate] respondsToSelector:@selector(growlNotificationTimedOut:)])
      [[GrowlApplicationBridge growlDelegate] growlNotificationTimedOut:[[notification userInfo] objectForKey:GROWL_NOTIFICATION_CLICK_CONTEXT]];
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

- (void)dealloc
{
   [[NSUserNotificationCenter defaultUserNotificationCenter] removeAllDeliveredNotifications];
   [super dealloc];
}

@end

#endif // MAC_OS_X_VERSION_10_8

#pragma mark -

@implementation GrowlApplicationBridge

+ (NSMutableArray *) queuedNotes {
	static NSMutableArray *queuedGrowlNotifications = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		queuedGrowlNotifications = [[NSMutableArray alloc] init];
		notificationQueue_Queue = dispatch_queue_create("com.growl.growlframework.notequeue_queue", 0);
	});
	return queuedGrowlNotifications;
}

+ (void) queueNote:(NSDictionary*)note {
	NSMutableArray *queue = [self queuedNotes];
	dispatch_async(notificationQueue_Queue, ^{
		[queue addObject:note];
	});
}

+ (NSMutableArray *) attempts {
	if (!_attempts)
		_attempts = [[NSMutableArray alloc] init];
	return _attempts;
}

+ (void) setGrowlDelegate:(id<GrowlApplicationBridgeDelegate>)inDelegate {
	NSDistributedNotificationCenter *NSDNC = [NSDistributedNotificationCenter defaultCenter];

	if (inDelegate != delegate) {
		[delegate autorelease];
		delegate = [inDelegate retain];
	} 
    
    _delegateRespondsTo.growlNotificationWasClicked = [delegate respondsToSelector:@selector(growlNotificationWasClicked:)];
    _delegateRespondsTo.growlNotificationTimedOut = [delegate respondsToSelector:@selector(growlNotificationTimedOut:)];
    _delegateRespondsTo.registrationDictionaryForGrowl = [delegate respondsToSelector:@selector(registrationDictionaryForGrowl)];
    _delegateRespondsTo.applicationNameForGrowl = [delegate respondsToSelector:@selector(applicationNameForGrowl)];
    _delegateRespondsTo.applicationIconForGrowl = [delegate respondsToSelector:@selector(applicationIconForGrowl)];
    _delegateRespondsTo.applicationIconDataForGrowl = [delegate respondsToSelector:@selector(applicationIconDataForGrowl)];
    _delegateRespondsTo.growlIsReady = [delegate respondsToSelector:@selector(growlIsReady)];
    _delegateRespondsTo.hasNetworkClientEntitlement = [delegate respondsToSelector:@selector(hasNetworkClientEntitlement)];
    
	[cachedRegistrationDictionary release];
	cachedRegistrationDictionary = [[self bestRegistrationDictionary] retain];

	//Cache the appName from the delegate or the process name
	[appName autorelease];
	appName = [[self _applicationNameForGrowlSearchingRegistrationDictionary:cachedRegistrationDictionary] retain];
	if (!appName) {
		NSLog(@"%@", @"GrowlApplicationBridge: Cannot register because the application name was not supplied and could not be determined");
		return;
	}

	/* Cache the appIconData from the delegate if it responds to the
	 * applicationIconDataForGrowl selector, or the application if not
	 */
	[appIconData autorelease];
	appIconData = [[self _applicationIconDataForGrowlSearchingRegistrationDictionary:cachedRegistrationDictionary] retain];

	//Add the observer for GROWL_IS_READY which will be triggered later if all goes well
	[NSDNC addObserver:self
			  selector:@selector(_growlIsReady:)
				  name:GROWL_IS_READY
				object:nil];
   
   [NSDNC addObserver:self
             selector:@selector(_growlNotificationCenterOn:)
                 name:GROWL_DISTRIBUTED_NOTIFICATION_NOTIFICATIONCENTER_ON
               object:nil];

   [NSDNC addObserver:self
             selector:@selector(_growlNotificationCenterOff:)
                 name:GROWL_DISTRIBUTED_NOTIFICATION_NOTIFICATIONCENTER_OFF
               object:nil];
   
	/* Watch for notification clicks if our delegate responds to the
	 * growlNotificationWasClicked: selector. Notifications will come in on a
	 * unique notification name based on our app name, pid and
	 * GROWL_DISTRIBUTED_NOTIFICATION_CLICKED_SUFFIX.
	 */
	int pid = [[NSProcessInfo processInfo] processIdentifier];
	NSString *growlNotificationClickedName = [[NSString alloc] initWithFormat:@"%@-%d-%@",
		appName, pid, GROWL_DISTRIBUTED_NOTIFICATION_CLICKED_SUFFIX];
	if (_delegateRespondsTo.growlNotificationWasClicked)
		[NSDNC addObserver:self
				  selector:@selector(growlNotificationWasClicked:)
					  name:growlNotificationClickedName
					object:nil];
	else
		[NSDNC removeObserver:self
						 name:growlNotificationClickedName
					   object:nil];
	[growlNotificationClickedName release];
	
	/* We also look for notifications which arne't pid-specific but which are for our application */
	growlNotificationClickedName = [[NSString alloc] initWithFormat:@"%@-%@",
									appName, GROWL_DISTRIBUTED_NOTIFICATION_CLICKED_SUFFIX];
	if (_delegateRespondsTo.growlNotificationWasClicked)
		[NSDNC addObserver:self
				  selector:@selector(growlNotificationWasClicked:)
					  name:growlNotificationClickedName
					object:nil];
	else
		[NSDNC removeObserver:self
						 name:growlNotificationClickedName
					   object:nil];
	[growlNotificationClickedName release];

	NSString *growlNotificationTimedOutName = [[NSString alloc] initWithFormat:@"%@-%d-%@",
		appName, pid, GROWL_DISTRIBUTED_NOTIFICATION_TIMED_OUT_SUFFIX];
	if (_delegateRespondsTo.growlNotificationTimedOut)
		[NSDNC addObserver:self
				  selector:@selector(growlNotificationTimedOut:)
					  name:growlNotificationTimedOutName
					object:nil];
	else
		[NSDNC removeObserver:self
						 name:growlNotificationTimedOutName
					   object:nil];
	[growlNotificationTimedOutName release];
	
	/* We also look for notifications which arne't pid-specific but which are for our application */
	growlNotificationTimedOutName = [[NSString alloc] initWithFormat:@"%@-%@",
									 appName, GROWL_DISTRIBUTED_NOTIFICATION_TIMED_OUT_SUFFIX];
	if (_delegateRespondsTo.growlNotificationTimedOut)
		[NSDNC addObserver:self
				  selector:@selector(growlNotificationTimedOut:)
					  name:growlNotificationTimedOutName
					object:nil];
	else
		[NSDNC removeObserver:self
						 name:growlNotificationTimedOutName
					   object:nil];
	[growlNotificationTimedOutName release];

	[self reregisterGrowlNotifications];

   // Query if we're using Notification Center directly, via the Big Magic Switch.
   //
   // Sadly, this will generate an update to everyone else, but there's
   // not a lot of way around that.
   //
   [NSDNC postNotificationName:GROWL_DISTRIBUTED_NOTIFICATION_NOTIFICATIONCENTER_QUERY
                        object:nil
                      userInfo:nil deliverImmediately:YES];
}

+ (NSObject<GrowlApplicationBridgeDelegate> *) growlDelegate {
	return delegate;
}

#pragma mark -

+ (void) notifyWithTitle:(NSString *)title
			 description:(NSString *)description
		notificationName:(NSString *)notifName
				iconData:(NSData *)iconData
				priority:(int)priority
				isSticky:(BOOL)isSticky
			clickContext:(id)clickContext
{
	[GrowlApplicationBridge notifyWithTitle:title
								description:description
						   notificationName:notifName
								   iconData:iconData
								   priority:priority
								   isSticky:isSticky
							   clickContext:clickContext
								 identifier:nil];
}

/* Send a notification to Growl for display.
 * title, description, and notifName are required.
 * All other id parameters may be nil to accept defaults.
 * priority is 0 by default; isSticky is NO by default.
 */
+ (void) notifyWithTitle:(NSString *)title
			 description:(NSString *)description
		notificationName:(NSString *)notifName
				iconData:(NSData *)iconData
				priority:(int)priority
				isSticky:(BOOL)isSticky
			clickContext:(id)clickContext
			  identifier:(NSString *)identifier
{
	NSParameterAssert(notifName);	//Notification name is required.
	NSParameterAssert(title || description);	//At least one of title or description is required.

	// Build our noteDict from all passed parameters
	NSMutableDictionary *noteDict = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
		notifName,	 GROWL_NOTIFICATION_NAME,
		nil];

	if (title)			[noteDict setObject:title forKey:GROWL_NOTIFICATION_TITLE];
	if (description)	[noteDict setObject:description forKey:GROWL_NOTIFICATION_DESCRIPTION];
	if (iconData)		[noteDict setObject:iconData forKey:GROWL_NOTIFICATION_ICON_DATA];
	if (clickContext)	[noteDict setObject:clickContext forKey:GROWL_NOTIFICATION_CLICK_CONTEXT];
	if (priority)		[noteDict setObject:[NSNumber numberWithInteger:priority] forKey:GROWL_NOTIFICATION_PRIORITY];
	if (isSticky)		[noteDict setObject:[NSNumber numberWithBool:isSticky] forKey:GROWL_NOTIFICATION_STICKY];
	if (identifier)   [noteDict setObject:identifier forKey:GROWL_NOTIFICATION_IDENTIFIER];

   BOOL useNotificationCenter = (NSClassFromString(@"NSUserNotificationCenter") != nil);
   
   // Do we have notification center disabled?
   if (useNotificationCenter && !shouldUseNotificationCenterAlways) {
      if ([[NSUserDefaults standardUserDefaults] valueForKey:GROWL_FRAMEWORK_NOTIFICATIONCENTER_ENABLE]) {
         useNotificationCenter = [[NSUserDefaults standardUserDefaults] boolForKey:GROWL_FRAMEWORK_NOTIFICATIONCENTER_ENABLE];
      }
   }
   
   // If we have notification center on, we must set this accordingly.
   //
   // Ideally, this would be set by the notification center delivery callback, but as we
   // are not guaranteed instant delivery, by that point the GNTP packet may already
   // have been built.  As such, we need to set it here instead.
   //
   if (useNotificationCenter && (shouldUseNotificationCenterAlways || [[NSUserDefaults standardUserDefaults] valueForKey:GROWL_FRAMEWORK_NOTIFICATIONCENTER_ALWAYS])) {
      if (![[NSUserDefaults standardUserDefaults] boolForKey:GROWL_FRAMEWORK_NOTIFICATIONCENTER_ALWAYS]) {
         [noteDict setObject:[NSNumber numberWithBool:YES] forKey:GROWL_NOTIFICATION_ALREADY_SHOWN];
      }
   }
   
	[self notifyWithDictionary:noteDict];
	[noteDict release];
}

+ (void) notifyWithDictionary:(NSDictionary *)userInfo
{
   // Are we on Mountain Lion?
   BOOL useNotificationCenter = (NSClassFromString(@"NSUserNotificationCenter") != nil);
   BOOL alwaysCopyNC = NO;
   
   // Do we have notification center disabled?  (Only valid if it hasn't been turned on directly in Growl.)
   if (!shouldUseNotificationCenterAlways) {
      if (useNotificationCenter && [[NSUserDefaults standardUserDefaults] valueForKey:GROWL_FRAMEWORK_NOTIFICATIONCENTER_ENABLE])
         useNotificationCenter = [[NSUserDefaults standardUserDefaults] boolForKey:GROWL_FRAMEWORK_NOTIFICATIONCENTER_ENABLE];
   }
   
   // If we have notification center set to always-on, we must send.
   if (useNotificationCenter && (shouldUseNotificationCenterAlways || [[NSUserDefaults standardUserDefaults] valueForKey:GROWL_FRAMEWORK_NOTIFICATIONCENTER_ALWAYS])) {
      alwaysCopyNC = shouldUseNotificationCenterAlways || ![[NSUserDefaults standardUserDefaults] boolForKey:GROWL_FRAMEWORK_NOTIFICATIONCENTER_ALWAYS];
      if (alwaysCopyNC) {
         [self _fireAppleNotificationCenter:userInfo];
      }
   }
   
   //All the cases where growl is reachable *should* be covered now
	if (registeredWithGrowl && [self _growlIsReachableUpdateCache:NO]) {
		userInfo = [self notificationDictionaryByFillingInDictionary:userInfo];

		GrowlCommunicationAttempt *firstAttempt = nil;
		GrowlApplicationBridgeNotificationAttempt *secondAttempt = nil;

      if(hasGNTP){
         //These should be the only way we get marked as having gntp
         if([GrowlXPCCommunicationAttempt canCreateConnection])
            firstAttempt = [[[GrowlXPCNotificationAttempt alloc] initWithDictionary:userInfo] autorelease];
         else if(networkClient)
            firstAttempt = [[[GrowlGNTPNotificationAttempt alloc] initWithDictionary:userInfo] autorelease];
         
         if(firstAttempt){
            firstAttempt.delegate = (id <GrowlCommunicationAttemptDelegate>)self;
            [[self attempts] addObject:firstAttempt];
         }
      }
      
      if(!sandboxed){
         secondAttempt = [[[GrowlApplicationBridgeNotificationAttempt alloc] initWithDictionary:userInfo] autorelease];
         secondAttempt.delegate = (id <GrowlCommunicationAttemptDelegate>)self;
         [[self attempts] addObject:secondAttempt];
     
         if(firstAttempt)
            firstAttempt.nextAttempt = secondAttempt;
         else
            firstAttempt = secondAttempt;
      }
      
      //We should always have a first attempt if Growl is reachable
      if(firstAttempt)
         [firstAttempt begin];
   }else{ 
      if ([self _growlIsReachableUpdateCache:NO])
      {
         [self queueNote:userInfo];
         
         if(!attemptingToRegister)
            [self registerWithDictionary:nil];
      } else {
         // If we do the always-send-to-notification-center, we don't need a fallback.
         if (!alwaysCopyNC) {
            if (useNotificationCenter) {
               [GrowlApplicationBridge _fireAppleNotificationCenter:userInfo];
            }
            else if([GrowlApplicationBridge isMistEnabled]){
               dispatch_async(dispatch_get_main_queue(), ^(void) {
                  [GrowlApplicationBridge _fireMiniDispatch:userInfo];
               });
            }
         }
      }
   }
}

+ (BOOL)isNotificationDefaultEnabled:(NSDictionary*)growlDict
{
   NSDictionary *regDict = [self bestRegistrationDictionary];
   //Sanity check, shouldn't happen, just in case
   if(!regDict)
      return NO;
   
   BOOL result = NO;
   id defaultNotes = [regDict valueForKey:GROWL_NOTIFICATIONS_DEFAULT];
   NSString *name = [growlDict valueForKey:GROWL_NOTIFICATION_NAME];
   NSUInteger indexInAll = [[regDict valueForKey:GROWL_NOTIFICATIONS_ALL] indexOfObject:name];
   
   //If its not in all notes, its definitely not a default note
   if(indexInAll != NSNotFound) 
   {
      //If its an index set, see if the index of the name in all notes is in the set
      if([defaultNotes isKindOfClass:[NSIndexSet class]]) 
      {
         if([defaultNotes containsIndex:indexInAll])
            result = YES;
      } //If its an array, it should be either an array of indexes, or an array of names, if there arent any notes, its not there
      else if([defaultNotes isKindOfClass:[NSArray class]] && [defaultNotes count] > 0) 
      {
         //If first one is a number, its a numeric index array of defaults, if its a string, its an array of notification names
         if([[defaultNotes objectAtIndex:0] isKindOfClass:[NSNumber class]]) 
         {
            if([defaultNotes containsObject:[NSNumber numberWithUnsignedInteger:indexInAll]])
               result = YES;
         }
         else if([[defaultNotes objectAtIndex:0] isKindOfClass:[NSString class]]) 
         {
            if([defaultNotes containsObject:name])
               result = YES;
         }
      }
   }
   return result;
}

+ (BOOL)isMistEnabled
{
    BOOL result = shouldUseBuiltInNotifications;
    
    //did the user set the global default to indicate they don't want them
    if([[NSUserDefaults standardUserDefaults] valueForKey:GROWL_FRAMEWORK_MIST_ENABLE])
       result = [[[NSUserDefaults standardUserDefaults] valueForKey:GROWL_FRAMEWORK_MIST_ENABLE] boolValue];
    
    //If growl is reachable, mist wont be used
    if([self _growlIsReachableUpdateCache:NO])
       result = NO;
    
    //If on Mountain Lion, Mist won't be used.
    if (NSClassFromString(@"NSUserNotificationCenter"))
       result = NO;

    return result;
}

+ (void)setShouldUseBuiltInNotifications:(BOOL)should
{
    shouldUseBuiltInNotifications = should;
}

+ (BOOL)shouldUseBuiltInNotifications
{
    return shouldUseBuiltInNotifications;
}

+ (void) _fireMiniDispatch:(NSDictionary*)growlDict
{
   BOOL defaultOnly = YES;
   if([[NSUserDefaults standardUserDefaults] valueForKey:GROWL_FRAMEWORK_MIST_DEFAULT_ONLY])
      defaultOnly = [[[NSUserDefaults standardUserDefaults] valueForKey:GROWL_FRAMEWORK_MIST_DEFAULT_ONLY] boolValue];
   
   if (![self isNotificationDefaultEnabled:growlDict] && defaultOnly)
      return;
   
   if (!miniDispatch) {
      miniDispatch = [[GrowlMiniDispatch alloc] init];
      miniDispatch.delegate = [GrowlApplicationBridge growlDelegate];
   }
   [miniDispatch displayNotification:growlDict];
}

+ (void) _fireAppleNotificationCenter:(NSDictionary *)growlDict
{
#if defined(MAC_OS_X_VERSION_10_8) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_8
   BOOL defaultOnly = YES;
   if([[NSUserDefaults standardUserDefaults] valueForKey:GROWL_FRAMEWORK_NOTIFICATIONCENTER_DEFAULT_ONLY])
      defaultOnly = [[[NSUserDefaults standardUserDefaults] valueForKey:GROWL_FRAMEWORK_NOTIFICATIONCENTER_DEFAULT_ONLY] boolValue];

   if (![self isNotificationDefaultEnabled:growlDict] && defaultOnly)
      return;

   // If we're not on 10.8, there's no point in doing this.
   if (!NSClassFromString(@"NSUserNotificationCenter"))
      return;

   NSMutableDictionary *notificationDict = [[[NSMutableDictionary alloc] init] autorelease];
   if ([growlDict objectForKey:GROWL_NOTIFICATION_CLICK_CONTEXT])
      [notificationDict setObject:[growlDict objectForKey:GROWL_NOTIFICATION_CLICK_CONTEXT] forKey:GROWL_NOTIFICATION_CLICK_CONTEXT];
   if ([growlDict objectForKey:GROWL_NOTIFICATION_STICKY])
      [notificationDict setObject:[growlDict objectForKey:GROWL_NOTIFICATION_STICKY] forKey:GROWL_NOTIFICATION_STICKY];
   
   NSUserNotification *appleNotification = [[NSUserNotification alloc] init];
   appleNotification.title = [growlDict objectForKey:GROWL_NOTIFICATION_TITLE];
   appleNotification.informativeText = [growlDict objectForKey:GROWL_NOTIFICATION_DESCRIPTION];
   appleNotification.userInfo = notificationDict;
   
   // If we ever add support for action buttons in Growl (please), we'll want to add those here.
   if (!appleNotificationDelegate) {
      appleNotificationDelegate = [[GrowlAppleNotificationDelegate alloc] init];
   }
   
   [[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:appleNotificationDelegate];
   [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:appleNotification];
   [appleNotification release];
#endif
}

#pragma mark -


+ (BOOL) isGrowlInstalled {
   static BOOL warned = NO;
   if(warned){
      warned = YES;
      NSLog(@"+[GrowlApplicationBridge isGrowlInstalled] is deprecated, returns yes always now.  This warning will only show once");
   }
	return YES;
}


+ (BOOL) isGrowlRunning {
	return Growl_HelperAppIsRunning();
}

#pragma mark -

+ (BOOL) registerWithDictionary:(NSDictionary *)regDict {
   if(attemptingToRegister){
      NSLog(@"Attempting to register while an attempt is already running");
   }
   
   //Will register when growl is running and ready
   if(![self _growlIsReachableUpdateCache:NO]){
      registerWhenGrowlIsReady = YES;
      return NO;
   }
   
	if (regDict)
		regDict = [self registrationDictionaryByFillingInDictionary:regDict];
	else
		regDict = [self bestRegistrationDictionary];
	
	if(!regDict){
		NSLog(@"Cannot register without a registration dictionary!");
		return NO;
	}

   attemptingToRegister = YES;
   
      
   
	[cachedRegistrationDictionary release];
	cachedRegistrationDictionary = [regDict retain];

	GrowlCommunicationAttempt *firstAttempt = nil;
   GrowlApplicationBridgeRegistrationAttempt *secondAttempt = nil;
   
   if(hasGNTP){
      //These should be the only way we get marked as having gntp
      if([GrowlXPCCommunicationAttempt canCreateConnection])
         firstAttempt = [[[GrowlXPCRegistrationAttempt alloc] initWithDictionary:regDict] autorelease];
      else if(networkClient)
         firstAttempt = [[[GrowlGNTPRegistrationAttempt alloc] initWithDictionary:regDict] autorelease];
      
      if(firstAttempt){
         firstAttempt.delegate = (id <GrowlCommunicationAttemptDelegate>)self;
         [[self attempts] addObject:firstAttempt];
      }
   }

   if(!sandboxed){
      secondAttempt = [[[GrowlApplicationBridgeRegistrationAttempt alloc] initWithDictionary:regDict] autorelease];
      secondAttempt.applicationName = [self _applicationNameForGrowlSearchingRegistrationDictionary:regDict];
      secondAttempt.delegate = (id <GrowlCommunicationAttemptDelegate>)self;
      [[self attempts] addObject:secondAttempt];
      if(firstAttempt)
         firstAttempt.nextAttempt = secondAttempt;
      else
         firstAttempt = secondAttempt;
   }

	[firstAttempt begin];

	return YES;
}

+ (void) reregisterGrowlNotifications {
   registeredWithGrowl = NO;
	[self registerWithDictionary:nil];
}

+ (void) setWillRegisterWhenGrowlIsReady:(BOOL)flag {
	registerWhenGrowlIsReady = flag;
}
+ (BOOL) willRegisterWhenGrowlIsReady {
	return registerWhenGrowlIsReady;
}

#pragma mark -

+ (NSDictionary *) registrationDictionaryFromDelegate {
	NSDictionary *regDict = nil;

	if (delegate && _delegateRespondsTo.registrationDictionaryForGrowl)
		regDict = [delegate registrationDictionaryForGrowl];

	return regDict;
}

+ (NSDictionary *) registrationDictionaryFromBundle:(NSBundle *)bundle {
	if (!bundle) bundle = [NSBundle mainBundle];

	NSDictionary *regDict = nil;

	NSString *regDictPath = [bundle pathForResource:@"Growl Registration Ticket" ofType:GROWL_REG_DICT_EXTENSION];
	if (regDictPath) {
		regDict = [NSDictionary dictionaryWithContentsOfFile:regDictPath];
		if (!regDict)
			NSLog(@"GrowlApplicationBridge: The bundle at %@ contains a registration dictionary, but it is not a valid property list. Please tell this application's developer.", [bundle bundlePath]);
	}

	return regDict;
}

+ (NSDictionary *) bestRegistrationDictionary {
	NSDictionary *registrationDictionary = [self registrationDictionaryFromDelegate];
	if (!registrationDictionary) {
		registrationDictionary = [self registrationDictionaryFromBundle:nil];
		if (!registrationDictionary)
			NSLog(@"GrowlApplicationBridge: The Growl delegate did not supply a registration dictionary, and the app bundle at %@ does not have one. Please tell this application's developer.", [[NSBundle mainBundle] bundlePath]);
	}

	return [self registrationDictionaryByFillingInDictionary:registrationDictionary];
}

#pragma mark -

+ (NSDictionary *) registrationDictionaryByFillingInDictionary:(NSDictionary *)regDict {
	return [self registrationDictionaryByFillingInDictionary:regDict restrictToKeys:nil];
}

+ (NSDictionary *) registrationDictionaryByFillingInDictionary:(NSDictionary *)regDict restrictToKeys:(NSSet *)keys {
	if (!regDict) return nil;

	NSMutableDictionary *mRegDict = [regDict mutableCopy];

	if ((!keys) || [keys containsObject:GROWL_APP_NAME]) {
		if (![mRegDict objectForKey:GROWL_APP_NAME]) {
			if (!appName)
				appName = [[self _applicationNameForGrowlSearchingRegistrationDictionary:regDict] retain];

			[mRegDict setObject:appName
			             forKey:GROWL_APP_NAME];
		}
	}

	if ((!keys) || [keys containsObject:GROWL_APP_ICON_DATA]) {
		if (![mRegDict objectForKey:GROWL_APP_ICON_DATA]) {
			if (!appIconData)
				appIconData = [[self _applicationIconDataForGrowlSearchingRegistrationDictionary:regDict] retain];
			if (appIconData)
				[mRegDict setObject:appIconData forKey:GROWL_APP_ICON_DATA];
		}
	}

	if ((!keys) || [keys containsObject:GROWL_APP_LOCATION]) {
		if (![mRegDict objectForKey:GROWL_APP_LOCATION]) {
			NSURL *myURL = [[NSBundle mainBundle] bundleURL];
			if (myURL) {
				NSDictionary *file_data = dockDescriptionWithURL(myURL);
				if (file_data) {
					NSDictionary *location = [[NSDictionary alloc] initWithObjectsAndKeys:file_data, @"file-data", nil];
					[mRegDict setObject:location forKey:GROWL_APP_LOCATION];
					[location release];
				} else {
					[mRegDict removeObjectForKey:GROWL_APP_LOCATION];
				}
			}
		}
	}

	if ((!keys) || [keys containsObject:GROWL_NOTIFICATIONS_DEFAULT]) {
		if (![mRegDict objectForKey:GROWL_NOTIFICATIONS_DEFAULT]) {
			NSArray *all = [mRegDict objectForKey:GROWL_NOTIFICATIONS_ALL];
			if (all)
				[mRegDict setObject:all forKey:GROWL_NOTIFICATIONS_DEFAULT];
		}
	}

	if ((!keys) || [keys containsObject:GROWL_APP_ID])
		if (![mRegDict objectForKey:GROWL_APP_ID])
			[mRegDict setObject:(NSString *)CFBundleGetIdentifier(CFBundleGetMainBundle()) forKey:GROWL_APP_ID];

	return [mRegDict autorelease];
}

+ (NSDictionary *) notificationDictionaryByFillingInDictionary:(NSDictionary *)notifDict {
	NSMutableDictionary *mNotifDict = [notifDict mutableCopy];

	if (![mNotifDict objectForKey:GROWL_APP_NAME]) {
		if (!appName)
			appName = [[self _applicationNameForGrowlSearchingRegistrationDictionary:cachedRegistrationDictionary] retain];

		if (appName) {
			[mNotifDict setObject:appName
			               forKey:GROWL_APP_NAME];
		}
	}

	if (![mNotifDict objectForKey:GROWL_APP_ICON_DATA]) {
		if (!appIconData)
			appIconData = [[self _applicationIconDataForGrowlSearchingRegistrationDictionary:cachedRegistrationDictionary] retain];

		if (appIconData) {
			[mNotifDict setObject:appIconData
			               forKey:GROWL_APP_ICON_DATA];
		}
	}

	//Only include the PID when there's a click context. We do this because NSDNC imposes a 15-MiB limit on the serialized notification, and we wouldn't want to overrun it because of a 4-byte PID.
	if ([mNotifDict objectForKey:GROWL_NOTIFICATION_CLICK_CONTEXT] && ![mNotifDict objectForKey:GROWL_APP_PID]) {
		NSNumber *pidNum = [[NSNumber alloc] initWithInt:[[NSProcessInfo processInfo] processIdentifier]];

		[mNotifDict setObject:pidNum
		               forKey:GROWL_APP_PID];

		[pidNum release];
	}

	return [mNotifDict autorelease];
}

+ (NSDictionary *) frameworkInfoDictionary {
	return (NSDictionary *)CFBundleGetInfoDictionary(CFBundleGetBundleWithIdentifier(CFSTR("com.growl.growlframework")));
}

#pragma mark -
#pragma mark Growl URL scheme

+ (BOOL) isGrowlURLSchemeAvailable {
   NSURL *growlURLScheme = [[NSWorkspace sharedWorkspace] URLForApplicationToOpenURL:[NSURL URLWithString:@"growl://"]];

   if(growlURLScheme)
      return YES;
   return NO;
}

+ (BOOL) openGrowlPreferences:(BOOL)showApp {
   if(showApp && !appName){
      NSLog(@"Attempt to show application setting without having set the Delegate first");
      return NO;
   }
   NSString *appString = showApp ? [NSString stringWithFormat:@"/applications/%@", appName] : @"";
   NSString *urlString = [[NSString stringWithFormat:@"growl://preferences%@", appString] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
   NSURL *url = [NSURL URLWithString:urlString];
   return [[NSWorkspace sharedWorkspace] openURL:url];
}

#pragma mark -
#pragma mark Private methods

+ (NSString *) _applicationNameForGrowlSearchingRegistrationDictionary:(NSDictionary *)regDict {
	NSString *applicationNameForGrowl = nil;

	if (delegate && _delegateRespondsTo.applicationNameForGrowl)
		applicationNameForGrowl = [delegate applicationNameForGrowl];

	if (!applicationNameForGrowl) {
		applicationNameForGrowl = [regDict objectForKey:GROWL_APP_NAME];

		if (!applicationNameForGrowl)
			applicationNameForGrowl = [[NSProcessInfo processInfo] processName];
	}

	return applicationNameForGrowl;
}
+ (NSData *) _applicationIconDataForGrowlSearchingRegistrationDictionary:(NSDictionary *)regDict {
	NSData *iconData = nil;

	if (delegate) {
		if (_delegateRespondsTo.applicationIconForGrowl)
			iconData = (NSData *)[delegate applicationIconForGrowl];
		else if (_delegateRespondsTo.applicationIconDataForGrowl)
			iconData = [delegate applicationIconDataForGrowl];
	}

	if (!iconData)
		iconData = [regDict objectForKey:GROWL_APP_ICON_DATA];

	if (iconData && [iconData isKindOfClass:[NSImage class]])
		iconData = [(NSImage *)iconData PNGRepresentation];

	if (!iconData) {
		NSString *path = [[NSBundle mainBundle] bundlePath];
		iconData = [[[NSWorkspace sharedWorkspace] iconForFile:path] PNGRepresentation];
	}

	return iconData;
}

/*Selector called when a growl notification is clicked.  This should never be
 *	called manually, and the calling observer should only be registered if the
 *	delegate responds to growlNotificationWasClicked:.
 */
+ (void) growlNotificationWasClicked:(NSNotification *)notification {
    AUTORELEASEPOOL_START
        [delegate growlNotificationWasClicked:
         [[notification userInfo] objectForKey:GROWL_KEY_CLICKED_CONTEXT]];
    AUTORELEASEPOOL_END
}
+ (void) growlNotificationTimedOut:(NSNotification *)notification {
	AUTORELEASEPOOL_START
        [delegate growlNotificationTimedOut:
         [[notification userInfo] objectForKey:GROWL_KEY_CLICKED_CONTEXT]];
    AUTORELEASEPOOL_END
}

#pragma mark -

+ (void) _emptyQueue
{
	NSMutableArray *queue = [self queuedNotes];
	dispatch_async(notificationQueue_Queue, ^{
		if([queue count]){
			[queue enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
				if([obj isKindOfClass:[NSDictionary class]])
					[self notifyWithDictionary:obj];
			}];
			[queue removeAllObjects];
		}
	});
}

+ (void) _growlIsReady:(NSNotification *)notification {
    AUTORELEASEPOOL_START
        //We may have gotten a new version of growl
        [self _growlIsReachableUpdateCache:YES];
        //Growl has now launched; we may get here with (growlLaunched == NO) when the user first installs
        growlLaunched = YES;
        
        //Inform our delegate if it is interested
        if (_delegateRespondsTo.growlIsReady)
            [delegate growlIsReady];
        
        //Post a notification locally
        [[NSNotificationCenter defaultCenter] postNotificationName:GROWL_IS_READY
                                                            object:nil
                                                          userInfo:nil];
        
        //Stop observing for GROWL_IS_READY
        [[NSDistributedNotificationCenter defaultCenter] removeObserver:self
                                                                   name:GROWL_IS_READY
                                                                 object:nil];
        
        //register (fixes #102: this is necessary if we got here by Growl having just been installed)
        if (registerWhenGrowlIsReady) {
            [self reregisterGrowlNotifications];
            registerWhenGrowlIsReady = NO;
        } else {
            registeredWithGrowl = YES;
            [self _emptyQueue];
        }
    AUTORELEASEPOOL_END
}

+ (void) _growlNotificationCenterOn:(NSNotification *)notification
{
   shouldUseNotificationCenterAlways = YES;
}

+ (void) _growlNotificationCenterOff:(NSNotification *)notification
{
   shouldUseNotificationCenterAlways = NO;
}

+ (BOOL) _growlIsReachableUpdateCache:(BOOL)update
{
   static BOOL _cached = NO;
   static BOOL _reachable = NO;
   
   BOOL running = [self isGrowlRunning];
   
   //No sense in running version checks repeatedly, but if growl relaunched, we will recheck
   if(_cached && !update){
      if(running)
         return _reachable;
      else
         return NO;
   }
   
   //We dont say _cached = YES here because we haven't done the other checks yet
   if(!running)
      return NO;
   
   [self _checkSandbox];

   //This is a bit of a hack, we check for Growl 1.2.2 and lower by seeing if the running helper app is inside Growl.prefpane
    NSString *runningPath = nil;
    NSArray *runningApplications = [NSRunningApplication runningApplicationsWithBundleIdentifier:GROWL_HELPERAPP_BUNDLE_IDENTIFIER];
    if(runningApplications && [runningApplications count])
        runningPath = [[[runningApplications objectAtIndex:0] bundleURL] absoluteString];
   NSString *prefPaneSubpath = @"Growl.prefpane/Contents/Resources";
   
    if(runningPath) {
        if([runningPath rangeOfString:prefPaneSubpath options:NSCaseInsensitiveSearch].location != NSNotFound){
            hasGNTP = NO;
            _reachable = !sandboxed;
            if(!_reachable)
                NSLog(@"%@ could not reach Growl, You are running Growl version 1.2.2 or older, and %@ is sandboxed", appName, appName);
        }else{
            //If we are running 1.3+, and we are sandboxed, do we have network client, or an XPC?
            hasGNTP = YES;
            if(sandboxed){
                if(networkClient || [GrowlXPCCommunicationAttempt canCreateConnection]){
                    _reachable = YES;
                }else{
                    NSLog(@"%@ could not reach Growl, %@ is sandboxed and does not have the ability to talk to Growl, contact the developer to resolve this", appName, appName);
                    _reachable = NO;
                }
            }else
                _reachable = YES;
        }
    }
    else {
        NSLog(@"%@ could not reach Growl, it is likely that if you're reading this message that Growl quit at the exact moment necessary to make this possible.", appName);
        _reachable = NO;
    }
    _cached = YES;
    return _reachable;
}

+ (void) _checkSandbox
{
   static BOOL checked = NO;
   
   //Sandboxing is not going to change on us while we are running
   if(checked)
      return;
   
   checked = YES;
   
   if(xpc_connection_create == NULL){
      sandboxed = NO;
      networkClient = NO; //Growl.app 1.3+ is required to be a network client, Growl.app 1.3+ requires 10.7+
      return;
   }

   //This is a hacky way of detecting sandboxing, and whether we have network client on the main app is up to app developers
   NSString *homeDirectory = NSHomeDirectory();
   NSString *suffix = [NSString stringWithFormat:@"Containers/%@/Data", [[NSBundle mainBundle] bundleIdentifier]];
   if([homeDirectory hasSuffix:suffix]){
      sandboxed = YES;
      if(delegate && _delegateRespondsTo.hasNetworkClientEntitlement)
         networkClient = [delegate hasNetworkClientEntitlement];
      else
         networkClient = NO;
   }else{
      sandboxed = NO;
      networkClient = YES;
   }
   
      
   return;
}

#pragma mark GrowlCommunicationAttemptDelegate protocol conformance

+ (void) attemptDidSucceed:(GrowlCommunicationAttempt *)attempt {
	if (attempt.attemptType == GrowlCommunicationAttemptTypeRegister) {
		registeredWithGrowl = YES;
      attemptingToRegister = NO;
      
      [self _emptyQueue];
	}
}
+ (void) attemptDidFail:(GrowlCommunicationAttempt *)attempt {
   if(attempt.nextAttempt == nil){
      //NSLog(@"Failed all attempts at %@", attempt.attemptType == GrowlCommunicationAttemptTypeNotify ? @"notifying" : @"registering");
      if(attempt.attemptType == GrowlCommunicationAttemptTypeRegister){
         attemptingToRegister = NO;
			
			/* If we have queued notes and we failed to register, 
			 * send them to Apple's notification center or to 
          * Mist.
          *
			 * Regardless, remove all dicts from the queue. 
			 * If we cant register, we probably can't send the notes to Growl.
			 */
         
         BOOL useNotificationCenter = (NSClassFromString(@"NSUserNotificationCenter") != nil);
         if (useNotificationCenter) {
            // If we don't have the global 'always use' on, we check the user defaults.
            if (!shouldUseNotificationCenterAlways) {
               if ([[NSUserDefaults standardUserDefaults] valueForKey:GROWL_FRAMEWORK_NOTIFICATIONCENTER_ENABLE])
                  useNotificationCenter = [[NSUserDefaults standardUserDefaults] boolForKey:GROWL_FRAMEWORK_NOTIFICATIONCENTER_ENABLE];
            }
         }

         // If we always send to notification center, we don't need a fallback display as we've already done that.
         BOOL needsFallback = YES;
         if (useNotificationCenter && [[NSUserDefaults standardUserDefaults] valueForKey:GROWL_FRAMEWORK_NOTIFICATIONCENTER_ALWAYS])
            needsFallback = ![[NSUserDefaults standardUserDefaults] boolForKey:GROWL_FRAMEWORK_NOTIFICATIONCENTER_ALWAYS];
         
			NSMutableArray *queue = [self queuedNotes];
			if([queue count]){
            if (needsFallback) {
               if(useNotificationCenter){
                  NSLog(@"We failed at registering with items in our queue waiting to go to growl, sending them to OS X notification center instead");
                  dispatch_async(notificationQueue_Queue, ^{
                     [queue enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                        if([obj isKindOfClass:[NSDictionary class]]){
                           dispatch_async(dispatch_get_main_queue(), ^{
                              [self _fireAppleNotificationCenter:obj];
                           });
                        }
                     }];
                  });
               }
               else if([self isMistEnabled]){
                  NSLog(@"We failed at registering with items in our queue waiting to go to growl, sending them to Mist instead");
                  dispatch_async(notificationQueue_Queue, ^{
                     [queue enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                        if([obj isKindOfClass:[NSDictionary class]]){
                           dispatch_async(dispatch_get_main_queue(), ^{
                              [self _fireMiniDispatch:obj];
                           });
                        }
                     }];
                  });
               }
            }
            
				dispatch_async(notificationQueue_Queue, ^{
					[queue removeAllObjects];
				});
			}
      }
   }
   [[self attempts] removeObject:attempt];
}
+ (void) finishedWithAttempt:(GrowlCommunicationAttempt *)attempt{
   [[self attempts] removeObject:attempt];
}
+ (void) queueAndReregister:(GrowlCommunicationAttempt *)attempt{
   if(attempt.attemptType != GrowlCommunicationAttemptTypeNotify)
      return;
   
   [self queueNote:[attempt dictionary]];
   [self reregisterGrowlNotifications];
}

+ (void) notificationClicked:(GrowlCommunicationAttempt *)attempt context:(id)context
{
   if(delegate && _delegateRespondsTo.growlNotificationWasClicked)
      [delegate growlNotificationWasClicked:context];
}
+ (void) notificationTimedOut:(GrowlCommunicationAttempt *)attempt context:(id)context
{
   if(delegate && _delegateRespondsTo.growlNotificationTimedOut)
      [delegate growlNotificationTimedOut:context];
}

@end
