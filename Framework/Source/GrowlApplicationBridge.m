//
//  GrowlApplicationBridge.m
//  Growl
//
//  Created by Evan Schoenberg on Wed Jun 16 2004.
//  Copyright 2004-2006 The Growl Project. All rights reserved.
//

#import "GrowlApplicationBridge.h"
#include "CFGrowlAdditions.h"
#include "CFURLAdditions.h"
#include "CFMutableDictionaryAdditions.h"
#import "GrowlDefinesInternal.h"
#import "GrowlPathUtilities.h"
#import "GrowlProcessUtilities.h"
#import "GrowlPathway.h"
#import "GrowlImageAdditions.h"
#import "GrowlMiniDispatch.h"

#import "GrowlApplicationBridgeRegistrationAttempt.h"
#import "GrowlApplicationBridgeNotificationAttempt.h"

#import <ApplicationServices/ApplicationServices.h>

@interface GrowlApplicationBridge (PRIVATE)

#ifdef GROWL_WITH_INSTALLER
+ (void) _checkForPackagedUpdateForGrowlPrefPaneBundle:(NSBundle *)growlPrefPaneBundle;
#endif

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

static GrowlMiniDispatch *miniDispatch = nil;

static id		delegate = nil;
static BOOL		growlLaunched = NO;

static NSMutableArray	*queuedGrowlNotifications = nil;

#ifdef GROWL_WITH_INSTALLER
static BOOL				userChoseNotToInstallGrowl = NO;
static BOOL				promptedToInstallGrowl = NO;
static BOOL				promptedToUpgradeGrowl = NO;
#endif

static BOOL registeredWithGrowl = NO;
static NSMutableArray *attempts = nil;

//used primarily by GIP, but could be useful elsewhere.
static BOOL		registerWhenGrowlIsReady = NO;

#pragma mark -

@implementation GrowlApplicationBridge

+ (NSMutableArray *) attempts {
	if (!attempts)
		attempts = [[NSMutableArray alloc] init];
	return attempts;
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

#ifdef GROWL_WITH_INSTALLER
	//Determine if the user has previously told us not to ever request installation again
	userChoseNotToInstallGrowl = [[NSUserDefaults standardUserDefaults] boolForKey:@"Growl Installation:Do Not Prompt Again"];
#endif

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

	if (title)			setObjectForKey(noteDict, GROWL_NOTIFICATION_TITLE, title);
	if (description)	setObjectForKey(noteDict, GROWL_NOTIFICATION_DESCRIPTION, description);
	if (iconData)		setObjectForKey(noteDict, GROWL_NOTIFICATION_ICON_DATA, iconData);
	if (clickContext)	setObjectForKey(noteDict, GROWL_NOTIFICATION_CLICK_CONTEXT, clickContext);
	if (priority)		setIntegerForKey(noteDict, GROWL_NOTIFICATION_PRIORITY, priority);
	if (isSticky)		setBooleanForKey(noteDict, GROWL_NOTIFICATION_STICKY, isSticky);
	if (identifier)		setObjectForKey(noteDict, GROWL_NOTIFICATION_IDENTIFIER, identifier);

	[self notifyWithDictionary:noteDict];
	[noteDict release];
}

+ (void) notifyWithDictionary:(NSDictionary *)userInfo {
	if (registeredWithGrowl) {
		userInfo = [self notificationDictionaryByFillingInDictionary:userInfo];

		GrowlCommunicationAttempt *firstAttempt;
		GrowlApplicationBridgeNotificationAttempt *gabNotify;
		
		firstAttempt = 
		gabNotify = [[[GrowlApplicationBridgeNotificationAttempt alloc] initWithDictionary:userInfo] autorelease];
		gabNotify.delegate = (id <GrowlCommunicationAttemptDelegate>)self;
		[[self attempts] addObject:gabNotify];

		[firstAttempt begin];
	} else {
		if ([self isGrowlInstalled]) {
			if (!queuedGrowlNotifications)
				queuedGrowlNotifications = [[NSMutableArray alloc] init];
			[queuedGrowlNotifications addObject:userInfo];

			[self registerWithDictionary:nil];
		} else {
			if (!miniDispatch) {
				miniDispatch = [[GrowlMiniDispatch alloc] init];
				miniDispatch.delegate = [GrowlApplicationBridge growlDelegate];
			}
			[miniDispatch displayNotification:userInfo];
		}
	}
}

#pragma mark -

+ (BOOL) isGrowlInstalled {
	return ([GrowlPathUtilities growlPrefPaneBundle] != nil);
}

+ (BOOL) isGrowlRunning {
	return Growl_HelperAppIsRunning();
}

+ (void) displayInstallationPromptIfNeeded {
#ifdef GROWL_WITH_INSTALLER
    //if we have not already asked the user to install Growl, do it now
    if (!promptedToInstallGrowl) {
        [GrowlInstallationPrompt showInstallationPrompt];
        promptedToInstallGrowl = YES;
    }
#endif
}

#pragma mark -

+ (BOOL) registerWithDictionary:(NSDictionary *)regDict {
	if (regDict)
		regDict = [self registrationDictionaryByFillingInDictionary:regDict];
	else
		regDict = [self bestRegistrationDictionary];

	[cachedRegistrationDictionary release];
	cachedRegistrationDictionary = [regDict retain];

	GrowlCommunicationAttempt *firstAttempt;
	GrowlApplicationBridgeRegistrationAttempt *gabRegister;

	firstAttempt =
	gabRegister = [[[GrowlApplicationBridgeRegistrationAttempt alloc] initWithDictionary:regDict] autorelease];
	gabRegister.applicationName = [self _applicationNameForGrowlSearchingRegistrationDictionary:regDict];
	gabRegister.delegate = (id <GrowlCommunicationAttemptDelegate>)self;
	[attempts addObject:gabRegister];

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
			NSURL *myURL = copyCurrentProcessURL();
			if (myURL) {
				NSDictionary *file_data = createDockDescriptionWithURL(myURL);
				if (file_data) {
					NSDictionary *location = [[NSDictionary alloc] initWithObjectsAndKeys:file_data, @"file-data", nil];
					[file_data release];
					[mRegDict setObject:location forKey:GROWL_APP_LOCATION];
					[location release];
				} else {
					[mRegDict removeObjectForKey:GROWL_APP_LOCATION];
				}
				[NSMakeCollectable(myURL) release];
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
#ifdef GROWL_WITH_INSTALLER
	return (NSDictionary *)CFBundleGetInfoDictionary(CFBundleGetBundleWithIdentifier(CFSTR("com.growl.growlwithinstallerframework")));
#else
	return (NSDictionary *)CFBundleGetInfoDictionary(CFBundleGetBundleWithIdentifier(CFSTR("com.growl.growlframework")));
#endif
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
		NSURL *URL = copyCurrentProcessURL();
		iconData = [copyIconDataForURL(URL) autorelease];
		[NSMakeCollectable(URL) release];
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

		for (NSDictionary *noteDict in queuedGrowlNotifications) {
			[self notifyWithDictionary:noteDict];
		}
		[queuedGrowlNotifications release]; queuedGrowlNotifications = nil;
	}

	[pool drain];
}

#ifdef GROWL_WITH_INSTALLER
/*Sent to us by GrowlInstallationPrompt if the user clicks Cancel so we can
 *	avoid prompting again this session (or ever if they checked Don't Ask Again)
 */
+ (void) _userChoseNotToInstallGrowl {
	//Note the user's action so we stop queueing notifications, etc.
	userChoseNotToInstallGrowl = YES;

	//Clear our queued notifications; we won't be needing them
	[queuedGrowlNotifications release]; queuedGrowlNotifications = nil;
}

// Check against our current version number and ensure the installed Growl pane is the same or later
+ (void) _checkForPackagedUpdateForGrowlPrefPaneBundle:(NSBundle *)growlPrefPaneBundle {
	NSString *ourGrowlPrefPaneInfoPath;
	NSDictionary *infoDictionary;
	NSString *packagedVersion, *installedVersion;
	BOOL upgradeIsAvailable;

	ourGrowlPrefPaneInfoPath = [[NSBundle bundleWithIdentifier:@"com.growl.growlwithinstallerframework"] pathForResource:@"GrowlPrefPaneInfo"
																												  ofType:@"plist"];

	NSObject *infoPropertyList = createPropertyListFromURL([NSURL fileURLWithPath:ourGrowlPrefPaneInfoPath],
														   kCFPropertyListImmutable,
														   /* outFormat */ NULL, /* outErrorString */ NULL);
	NSDictionary *infoDict = ([infoPropertyList isKindOfClass:[NSDictionary class]] ? (NSDictionary *)infoPropertyList : nil);

	packagedVersion = [infoDict objectForKey:(NSString *)kCFBundleVersionKey];

	infoDictionary = [growlPrefPaneBundle infoDictionary];
	installedVersion = [infoDictionary objectForKey:(NSString *)kCFBundleVersionKey];

	//If the installed version is earlier than our packaged version, we can offer an upgrade.
	upgradeIsAvailable = (compareVersionStringsTranslating1_0To0_5(packagedVersion, installedVersion) == kCFCompareGreaterThan);
	if (upgradeIsAvailable && !promptedToUpgradeGrowl) {
		NSString	*lastDoNotPromptVersion = [[NSUserDefaults standardUserDefaults] objectForKey:@"Growl Update:Do Not Prompt Again:Last Version"];

		if (!lastDoNotPromptVersion ||
			(compareVersionStringsTranslating1_0To0_5(packagedVersion, lastDoNotPromptVersion) == kCFCompareGreaterThan))
		{
			[GrowlInstallationPrompt showUpdatePromptForVersion:packagedVersion];
			promptedToUpgradeGrowl = YES;
		}
	}
	[infoDict release];
}
#endif

#pragma mark GrowlCommunicationAttemptDelegate protocol conformance

//I'm not sure whether we want to implement these here or not. The attempts' delegate protocol itself may be unnecessary and due for removal under YAGNI. -prh
//Note: These must be class methods, since we use the class itself as attempts' delegate.

+ (void) attemptDidSucceed:(GrowlCommunicationAttempt *)attempt {
}
+ (void) attemptDidFail:(GrowlCommunicationAttempt *)attempt {
}

@end
