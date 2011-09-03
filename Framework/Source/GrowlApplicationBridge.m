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

#import <ApplicationServices/ApplicationServices.h>

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

+ (void) notifyWithDictionary:(NSDictionary *)userInfo {
	if (registeredWithGrowl && [self isGrowlRunning]) {
		userInfo = [self notificationDictionaryByFillingInDictionary:userInfo];

		GrowlCommunicationAttempt *firstAttempt;
		GrowlGNTPNotificationAttempt *gntpNotify;
		GrowlApplicationBridgeNotificationAttempt *gabNotify;
		
		firstAttempt = 
		gntpNotify = [[[GrowlGNTPNotificationAttempt alloc] initWithDictionary:userInfo] autorelease];
		gntpNotify.delegate = (id <GrowlCommunicationAttemptDelegate>)self;
		[[self attempts] addObject:gntpNotify];

		gabNotify = [[[GrowlApplicationBridgeNotificationAttempt alloc] initWithDictionary:userInfo] autorelease];
		gabNotify.delegate = (id <GrowlCommunicationAttemptDelegate>)self;
		[[self attempts] addObject:gabNotify];
		gntpNotify.nextAttempt = gabNotify;

		[firstAttempt begin];
	} else {
#if !GROWLHELPERAPP
		if ([self isGrowlRunning])
#endif
		{
			if (!queuedGrowlNotifications)
				queuedGrowlNotifications = [[NSMutableArray alloc] init];
			[queuedGrowlNotifications addObject:userInfo];

         if(!attemptingToRegister)
            [self registerWithDictionary:nil];
#if !GROWLHELPERAPP
		} else {
			if (!miniDispatch) {
				miniDispatch = [[GrowlMiniDispatch alloc] init];
				miniDispatch.delegate = [GrowlApplicationBridge growlDelegate];
			}
			[miniDispatch displayNotification:userInfo];
#endif
		}
	}
}

#pragma mark -

+ (BOOL) isGrowlInstalled {
	return ([GrowlPathUtilities helperAppBundle] != nil);
}

+ (BOOL) isGrowlRunning {
	return Growl_HelperAppIsRunning();
}

#pragma mark -

+ (BOOL) registerWithDictionary:(NSDictionary *)regDict {
   if(attemptingToRegister){
      NSLog(@"Attempting to register while an attempt is already running");
   }
	if (regDict)
		regDict = [self registrationDictionaryByFillingInDictionary:regDict];
	else
		regDict = [self bestRegistrationDictionary];

   attemptingToRegister = YES;
   
	[cachedRegistrationDictionary release];
	cachedRegistrationDictionary = [regDict retain];

	GrowlCommunicationAttempt *firstAttempt;
	GrowlGNTPRegistrationAttempt *gntpRegister;
	GrowlApplicationBridgeRegistrationAttempt *gabRegister;

	firstAttempt =
	gntpRegister = [[[GrowlGNTPRegistrationAttempt alloc] initWithDictionary:regDict] autorelease];
	gntpRegister.delegate = (id <GrowlCommunicationAttemptDelegate>)self;
	[[self attempts] addObject:gntpRegister];

	gabRegister = [[[GrowlApplicationBridgeRegistrationAttempt alloc] initWithDictionary:regDict] autorelease];
	gabRegister.applicationName = [self _applicationNameForGrowlSearchingRegistrationDictionary:regDict];
	gabRegister.delegate = (id <GrowlCommunicationAttemptDelegate>)self;
	[[self attempts] addObject:gabRegister];
	gntpRegister.nextAttempt = gabRegister;

	[firstAttempt begin];

	return YES;
}

+ (void) reregisterGrowlNotifications {
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

#pragma mark GrowlCommunicationAttemptDelegate protocol conformance

+ (void) attemptDidSucceed:(GrowlCommunicationAttempt *)attempt {
	if (attempt.attemptType == GrowlCommunicationAttemptTypeRegister) {
		registeredWithGrowl = YES;
      attemptingToRegister = NO;
      
      [self _emptyQueue];
	}
}
+ (void) attemptDidFail:(GrowlCommunicationAttempt *)attempt {
   if(attempt.attemptType == GrowlCommunicationAttemptTypeRegister){
      attemptingToRegister = NO;
   }
}

@end
