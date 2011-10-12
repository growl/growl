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
#import "GrowlPathway.h"
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

#define GROWL_FRAMEWORK_MIST_ENABLE @"com.growl.growlframework.mist.enabled"

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

@end

static NSDictionary *cachedRegistrationDictionary = nil;
static NSString	*appName = nil;
static NSData	*appIconData = nil;

#if !GROWLHELPERAPP
static GrowlMiniDispatch *miniDispatch = nil;
#endif

static id		delegate = nil;
static BOOL		growlLaunched = NO;

static NSMutableArray	*queuedGrowlNotifications = nil;

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

#pragma mark -

@implementation GrowlApplicationBridge

+ (NSMutableArray *) attempts {
	if (!_attempts)
		_attempts = [[NSMutableArray alloc] init];
	return _attempts;
}

+ (void) setGrowlDelegate:(NSObject<GrowlApplicationBridgeDelegate> *)inDelegate {
	NSDistributedNotificationCenter *NSDNC = [NSDistributedNotificationCenter defaultCenter];

	if (inDelegate != delegate) {
		[delegate release];
		delegate = [inDelegate retain];
	}

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

	/* Watch for notification clicks if our delegate responds to the
	 * growlNotificationWasClicked: selector. Notifications will come in on a
	 * unique notification name based on our app name, pid and
	 * GROWL_DISTRIBUTED_NOTIFICATION_CLICKED_SUFFIX.
	 */
	int pid = [[NSProcessInfo processInfo] processIdentifier];
	NSString *growlNotificationClickedName = [[NSString alloc] initWithFormat:@"%@-%d-%@",
		appName, pid, GROWL_DISTRIBUTED_NOTIFICATION_CLICKED_SUFFIX];
	if ([delegate respondsToSelector:@selector(growlNotificationWasClicked:)])
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
	if ([delegate respondsToSelector:@selector(growlNotificationWasClicked:)])
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
	if ([delegate respondsToSelector:@selector(growlNotificationTimedOut:)])
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
	if ([delegate respondsToSelector:@selector(growlNotificationTimedOut:)])
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

	[self notifyWithDictionary:noteDict];
	[noteDict release];
}

+ (void) notifyWithDictionary:(NSDictionary *)userInfo 
{
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
         if (!queuedGrowlNotifications)
            queuedGrowlNotifications = [[NSMutableArray alloc] init];
         [queuedGrowlNotifications addObject:userInfo];
         
         if(!attemptingToRegister)
            [self registerWithDictionary:nil];
      } else {
         if([GrowlApplicationBridge isMistEnabled])
            dispatch_async(dispatch_get_main_queue(), ^(void) {
            [GrowlApplicationBridge _fireMiniDispatch:userInfo];
         });
      }
   }
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
   if (!miniDispatch) {
      miniDispatch = [[GrowlMiniDispatch alloc] init];
      miniDispatch.delegate = [GrowlApplicationBridge growlDelegate];
   }
   [miniDispatch displayNotification:growlDict];
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

	if (delegate && [delegate respondsToSelector:@selector(registrationDictionaryForGrowl)])
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
#pragma mark Private methods

+ (NSString *) _applicationNameForGrowlSearchingRegistrationDictionary:(NSDictionary *)regDict {
	NSString *applicationNameForGrowl = nil;

	if (delegate && [delegate respondsToSelector:@selector(applicationNameForGrowl)])
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
		if ([delegate respondsToSelector:@selector(applicationIconForGrowl)])
			iconData = (NSData *)[delegate applicationIconForGrowl];
		else if ([delegate respondsToSelector:@selector(applicationIconDataForGrowl)])
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
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[delegate growlNotificationWasClicked:
		[[notification userInfo] objectForKey:GROWL_KEY_CLICKED_CONTEXT]];
	[pool drain];
}
+ (void) growlNotificationTimedOut:(NSNotification *)notification {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[delegate growlNotificationTimedOut:
		[[notification userInfo] objectForKey:GROWL_KEY_CLICKED_CONTEXT]];
	[pool drain];
}

#pragma mark -

+ (void) _emptyQueue
{
   for (NSDictionary *noteDict in queuedGrowlNotifications) {
      [self notifyWithDictionary:noteDict];
   }
   [queuedGrowlNotifications release]; queuedGrowlNotifications = nil;
}

+ (void) _growlIsReady:(NSNotification *)notification {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

   //We may have gotten a new version of growl
   [self _growlIsReachableUpdateCache:YES];
	//Growl has now launched; we may get here with (growlLaunched == NO) when the user first installs
	growlLaunched = YES;

	//Inform our delegate if it is interested
	if ([delegate respondsToSelector:@selector(growlIsReady)])
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

	[pool drain];
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
   NSString *runningPath = [[[[NSRunningApplication runningApplicationsWithBundleIdentifier:GROWL_HELPERAPP_BUNDLE_IDENTIFIER] objectAtIndex:0] bundleURL] absoluteString];
   NSString *prefPaneSubpath = @"Growl.prefpane/Contents/Resources";
   
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
      if(delegate && [delegate respondsToSelector:@selector(hasNetworkClientEntitlement)])
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
      NSLog(@"Failed all attempts at %@", attempt.attemptType == GrowlCommunicationAttemptTypeNotify ? @"notifying" : @"registering");
      if(attempt.attemptType == GrowlCommunicationAttemptTypeRegister){
         attemptingToRegister = NO;
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
   
   if(!queuedGrowlNotifications)
      queuedGrowlNotifications = [[NSMutableArray alloc] init];
   [queuedGrowlNotifications addObject:[attempt dictionary]];
   [self reregisterGrowlNotifications];
}

+ (void) notificationClicked:(GrowlCommunicationAttempt *)attempt context:(id)context
{
   if(delegate && [delegate respondsToSelector:@selector(growlNotificationWasClicked:)])
      [delegate growlNotificationWasClicked:context];
}
+ (void) notificationTimedOut:(GrowlCommunicationAttempt *)attempt context:(id)context
{
   if(delegate && [delegate respondsToSelector:@selector(growlNotificationTimedOut:)])
      [delegate growlNotificationTimedOut:context];
}

@end
