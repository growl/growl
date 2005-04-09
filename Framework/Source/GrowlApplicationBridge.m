//
//  GrowlApplicationBridge.m
//  Growl
//
//  Created by Evan Schoenberg on Wed Jun 16 2004.
//  Copyright 2004-2005 The Growl Project. All rights reserved.
//

#import "GrowlApplicationBridge.h"
#ifdef GROWL_WITH_INSTALLER
#import "GrowlInstallationPrompt.h"
#import "GrowlVersionUtilities.h"
#endif
#import "NSGrowlAdditions.h"
#import "CFGrowlAdditions.h"
#import "GrowlDefinesInternal.h"

#import <ApplicationServices/ApplicationServices.h>

#define PREFERENCE_PANES_SUBFOLDER_OF_LIBRARY			@"PreferencePanes"
#define PREFERENCE_PANE_EXTENSION						@"prefPane"

@interface GrowlApplicationBridge (PRIVATE)
/*!
 *	@method growlPrefPaneBundle
 *	@abstract Returns the bundle containing Growl's PrefPane.
 *	@discussion Searches all installed PrefPanes for the Growl PrefPane.
 *	@result Returns an NSBundle if Growl's PrefPane is installed, nil otherwise
 */
+ (NSBundle *) growlPrefPaneBundle;

/*!
 *	@method launchGrowlIfInstalled
 *	@abstract Launches GrowlHelperApp
 *	@discussion Launches the GrowlHelperApp if it's not already running.
 *	 GROWL_IS_READY will be posted to the distributed notification center
 *	 once it is ready.
 *	@result Returns YES if GrowlHelperApp began launching or was already running, NO if Growl isn't installed
 */
+ (BOOL) launchGrowlIfInstalled;


#ifdef GROWL_WITH_INSTALLER
+ (void) _checkForPackagedUpdateForGrowlPrefPaneBundle:(NSBundle *)growlPrefPaneBundle;
#endif

+ (NSString *) _applicationNameForGrowl;
+ (NSDictionary *) _registrationDictionary;

@end

@implementation GrowlApplicationBridge

static NSString	*appName = nil;
static NSData	*appIconData = nil;

static id		delegate = nil;
static BOOL		growlLaunched = NO;

static NSMutableArray	*queuedGrowlNotifications = nil;

#ifdef GROWL_WITH_INSTALLER
static BOOL				userChoseNotToInstallGrowl = NO;
static BOOL				promptedToInstallGrowl = NO;
static BOOL				promptedToUpgradeGrowl = NO;
#endif

/************************
 *setGrowlDelegate: must be called before otherwise using GrowlApplicationBridge.
 *The methods in the GrowlApplicationBridgeDelegate protocol are required;
 * 	other methods defined in the informal protocol are optional.
 ************************
 */
+ (void) setGrowlDelegate:(NSObject<GrowlApplicationBridgeDelegate> *)inDelegate {
	NSDistributedNotificationCenter *NSDNC = [NSDistributedNotificationCenter defaultCenter];

	[delegate autorelease];
	delegate = [inDelegate retain];

	//Cache the appName from the delegate or the process name
	[appName autorelease];
	appName = [[self _applicationNameForGrowl] retain];
	
	//Cache the appIconData from the delegate if it responds to the applicationIconDataForGrowl selector
	[appIconData autorelease];
	if ([delegate respondsToSelector:@selector(applicationIconDataForGrowl)])
		appIconData = [[delegate applicationIconDataForGrowl] retain];
	else
		appIconData = nil;

	//Add the observer for GROWL_IS_READY which will be triggered later if all goes well
	[NSDNC addObserver:self 
			  selector:@selector(_growlIsReady:)
				  name:GROWL_IS_READY
				object:nil]; 

	//Watch for notification clicks if our delegate responds to the growlNotificationWasClicked: selector
	//Notifications will come in on a unique notification name based on our app name and GROWL_NOTIFICATION_CLICKED
	NSString *growlNotificationClickedName = [appName stringByAppendingString:GROWL_NOTIFICATION_CLICKED];
	if ([delegate respondsToSelector:@selector(growlNotificationWasClicked:)]){
		[NSDNC addObserver:self
				  selector:@selector(_growlNotificationWasClicked:)
					  name:growlNotificationClickedName 
					object:nil];
	} else {
		[NSDNC removeObserver:self
						 name:growlNotificationClickedName
					   object:nil];
	}

#ifdef GROWL_WITH_INSTALLER
	//Determine if the user has previously told us not to ever request installation again
	userChoseNotToInstallGrowl = [[NSUserDefaults standardUserDefaults] boolForKey:@"Growl Installation: Do Not Prompt Again"];
#endif

	growlLaunched = [self launchGrowlIfInstalled];
}

+ (NSObject<GrowlApplicationBridgeDelegate> *) growlDelegate {
	return delegate;
}

/*Send a notification to Growl for display.
 *title, description, and notifName are required.
 *All other id parameters may be nil to accept defaults.
 *priority is 0 by default; isSticky is NO by default.
 */
+ (void) notifyWithTitle:(NSString *)title
			 description:(NSString *)description
		notificationName:(NSString *)notifName
				iconData:(NSData *)iconData 
				priority:(int)priority
				isSticky:(BOOL)isSticky
			clickContext:(id)clickContext
{
	NSAssert(delegate, @"+[GrowlApplicationBridge setGrowlDelegate:] must be called before using this method.");
	
	NSParameterAssert(notifName);	//Notification name is required.
	NSParameterAssert(title || description);	//At least one of title or description is required.

	// Build our noteDict from all passed parameters
	NSMutableDictionary *noteDict = [[NSMutableDictionary alloc] initWithObjectsAndKeys:	appName,	GROWL_APP_NAME,
																							notifName,	GROWL_NOTIFICATION_NAME,
																							nil];

	if (title)			[noteDict setObject:title forKey:GROWL_NOTIFICATION_TITLE];
	if (description)	[noteDict setObject:description forKey:GROWL_NOTIFICATION_DESCRIPTION];
	if (iconData)		[noteDict setObject:iconData forKey:GROWL_NOTIFICATION_ICON];
	if (appIconData)	[noteDict setObject:appIconData forKey:GROWL_NOTIFICATION_APP_ICON];		
	if (clickContext)	[noteDict setObject:clickContext forKey:GROWL_NOTIFICATION_CLICK_CONTEXT];
	if (priority) {
		NSNumber *value = [[NSNumber alloc] initWithInt:priority];
		[noteDict setObject:value forKey:GROWL_NOTIFICATION_PRIORITY];
		[value release];
	}
	if (isSticky) {
		NSNumber *value = [[NSNumber alloc] initWithBool:isSticky];
		[noteDict setObject:value forKey:GROWL_NOTIFICATION_STICKY];
		[value release];
	}

	[GrowlApplicationBridge notifyWithDictionary:noteDict];
	[noteDict release];
}

+ (void) notifyWithDictionary:(NSDictionary *)userInfo {
	if (growlLaunched) {
		//Post to Growl via NSDistributedNotificationCenter
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName:GROWL_NOTIFICATION
																	   object:nil
																	 userInfo:userInfo
														   deliverImmediately:NO];
	} else {
#ifdef GROWL_WITH_INSTALLER
		/*if Growl launches, and the user hasn't already said NO to installing
		 *	it, store this notification for posting
		 */
		if (!userChoseNotToInstallGrowl) {
			//in case the dictionary is mutable, make a copy.
			userInfo = [userInfo copy];

			if (!queuedGrowlNotifications) {
				queuedGrowlNotifications = [[NSMutableArray alloc] init];
			}
			[queuedGrowlNotifications addObject:userInfo];

			//if we have not already asked the user to install Growl, do it now
			if (!promptedToInstallGrowl) {
				[GrowlInstallationPrompt showInstallationPrompt];
				promptedToInstallGrowl = YES;
			}
			[userInfo release];
		}
#endif
	}
}

/*	+ (BOOL)launchGrowlIfInstalled
 *
 *Returns YES if the Growl helper app began launching or was already running.
 *Returns NO and performs no other action if the Growl prefPane is not properly
 *	installed.
 *If Growl is installed but disabled, the application will be registered and
 *	GrowlHelperApp will then quit.  This method will still return YES if Growl
 *	is installed but disabled.
 */
+ (BOOL) launchGrowlIfInstalled {
	NSBundle		*growlPrefPaneBundle;
	BOOL			success = NO;
	
	growlPrefPaneBundle = [GrowlApplicationBridge growlPrefPaneBundle];
	
	if (growlPrefPaneBundle) {
		NSString *growlHelperAppPath = [growlPrefPaneBundle pathForResource:@"GrowlHelperApp"
																	 ofType:@"app"];

#ifdef GROWL_WITH_INSTALLER
		/* Check against our current version number and ensure the installed Growl pane is the same or later */
		[self _checkForPackagedUpdateForGrowlPrefPaneBundle:growlPrefPaneBundle];
#endif

		//Houston, we are go for launch.
		if (growlHelperAppPath) {
			
			//Let's launch in the background (unfortunately, requires Carbon)
			LSLaunchFSRefSpec spec;
			FSRef appRef;
			OSStatus status = FSPathMakeRef((UInt8 *)[growlHelperAppPath fileSystemRepresentation], &appRef, NULL);
			if (status == noErr) {
				
				NSDictionary	*registrationDict = [self _registrationDictionary];
				
				FSRef regItemRef;
				BOOL passRegDict = NO;
				
				if (registrationDict) {
					OSStatus regStatus;
					NSString *regDictFileName;
					NSString *regDictPath;

					//Obtain a truly unique file name
					regDictFileName = [[[NSProcessInfo processInfo] globallyUniqueString] stringByAppendingPathExtension:GROWL_REG_DICT_EXTENSION];

					//Write the registration dictionary out to the temporary directory
					regDictPath = [NSTemporaryDirectory() stringByAppendingPathComponent:regDictFileName];
					NSData *plistData;
					NSString *error;
					plistData = [NSPropertyListSerialization dataFromPropertyList:registrationDict
																		   format:NSPropertyListBinaryFormat_v1_0
																 errorDescription:&error];
					if (plistData) {
						[plistData writeToFile:regDictPath atomically:NO];
					} else {
						NSLog(@"GrowlApplicationBridge: Error writing registration dictionary at %@: %@", regDictPath, error);
						NSLog(@"GrowlApplicationBridge: Registration dictionary follows\n%@", registrationDict);
						[error release];
					}

					regStatus = FSPathMakeRef((UInt8 *)[regDictPath fileSystemRepresentation], &regItemRef, NULL);
					if (regStatus == noErr) {
						passRegDict = YES;
					}
				}
				
				spec.appRef = &appRef;
				spec.numDocs = (passRegDict != NO);
				spec.itemRefs = (passRegDict ? &regItemRef : NULL);
				spec.passThruParams = NULL;
				spec.launchFlags = kLSLaunchDontAddToRecents | kLSLaunchDontSwitch | kLSLaunchNoParams | kLSLaunchAsync;
				spec.asyncRefCon = NULL;
				status = LSOpenFromRefSpec( &spec, NULL );
				
				success = (status == noErr);
			}
		}
	}

	return success;
}

+ (BOOL) isGrowlInstalled {
	return ([GrowlApplicationBridge growlPrefPaneBundle] != nil);
}

+ (BOOL) isGrowlRunning {
	BOOL growlIsRunning = NO;
	ProcessSerialNumber PSN = {kNoProcess, kNoProcess};
	
	while (GetNextProcess(&PSN) == noErr) {
		NSDictionary *infoDict = (NSDictionary *)ProcessInformationCopyDictionary(&PSN, kProcessDictionaryIncludeAllInformationMask);

		if ([[infoDict objectForKey:(NSString *)kCFBundleIdentifierKey] isEqualToString:@"com.Growl.GrowlHelperApp"]) {
			growlIsRunning = YES;
			[infoDict release];
			break;
		}
		[infoDict release];
	}
	
	return growlIsRunning;
}

+ (void) reregisterGrowlNotifications {
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:GROWL_APP_REGISTRATION 
																   object:nil 
																 userInfo:[self _registrationDictionary]];	
}

+ (NSDictionary *) _registrationDictionary {
	NSDictionary *registrationDictionary = nil;
	if(delegate && [delegate respondsToSelector:@selector(registrationDictionaryForGrowl)])
		registrationDictionary = [delegate registrationDictionaryForGrowl];

	if (!registrationDictionary) {
		/*delegate didn't supply one.
		 *look for an auto-discoverable plist in the app bundle.
		 */
		NSBundle *bundle = [NSBundle mainBundle];
		NSString *regDictPath = [bundle pathForResource:@"Growl Registration Ticket" ofType:GROWL_REG_DICT_EXTENSION];
		if (regDictPath) {
			registrationDictionary = [NSDictionary dictionaryWithContentsOfFile:regDictPath];
			if (!registrationDictionary)
				NSLog(@"GrowlApplicationBridge: Delegate did not supply a registration dictionary, and it could not be loaded from %@", regDictPath);
		} else
			NSLog(@"GrowlApplicationBridge: Delegate did not supply a registration dictionary, and the app bundle at %@ does not have one", [bundle bundlePath]);
	}

	//Ensure the registration dictionary has the GROWL_APP_NAME specified
	if (![registrationDictionary objectForKey:GROWL_APP_NAME]) {
		NSMutableDictionary	*properRegistrationDictionary = [[registrationDictionary mutableCopy] autorelease];

		[properRegistrationDictionary setObject:appName
										 forKey:GROWL_APP_NAME];

		//don't rely on the application to give us a path; get it ourselves.
		NSURL *myURL = _copyCurrentProcessURL();
		if (myURL) {
			NSDictionary *file_data = [myURL dockDescription];
			if (file_data) {
				NSDictionary *location = [[NSDictionary alloc] initWithObjectsAndKeys:file_data, @"file-data", nil];
				[properRegistrationDictionary setObject:location
												 forKey:GROWL_APP_LOCATION];
				[location release];
			} else {
				[properRegistrationDictionary removeObjectForKey:GROWL_APP_LOCATION];
			}
			[myURL release];
		}

		registrationDictionary = properRegistrationDictionary;
	}
	if (![registrationDictionary objectForKey:GROWL_APP_ICON] && appIconData) {
		NSMutableDictionary	*properRegistrationDictionary = [[registrationDictionary mutableCopy] autorelease];
		
		[properRegistrationDictionary setObject:appIconData
										 forKey:GROWL_APP_ICON];

		registrationDictionary = properRegistrationDictionary;
	}

	return registrationDictionary;
}

+ (NSString *) _applicationNameForGrowl {
	NSString *applicationNameForGrowl;
	
	if ([delegate respondsToSelector:@selector(applicationNameForGrowl)]) {
		applicationNameForGrowl = [delegate applicationNameForGrowl];
	} else {
		applicationNameForGrowl = [[NSProcessInfo processInfo] processName];
	}
	
	if (!applicationNameForGrowl) NSLog(@"GrowlApplicationBridge: Cannot register because the application name was not supplied and could not be determined");
	
	return applicationNameForGrowl;
}

/*Selector called when a growl notification is clicked.  This should never be
 *	called manually, and the calling observer should only be registered if the
 *	delegate responds to growlNotificationWasClicked:.
 */
+ (void) _growlNotificationWasClicked:(NSNotification *)notification {
	[delegate performSelector:@selector(growlNotificationWasClicked:)
				   withObject:[[notification userInfo] objectForKey:GROWL_KEY_CLICKED_CONTEXT]];
}

+ (void) _growlIsReady:(NSNotification *)notification {
	
	//Growl has now launched; we may get here with (growlLaunched == NO) when the user first installs
	growlLaunched = YES;
	
	//Inform our delegate if it is interested
	if ([delegate respondsToSelector:@selector(growlIsReady)]){
		[delegate growlIsReady];
	}
	
	//Post a notification locally
	[[NSNotificationCenter defaultCenter] postNotificationName:GROWL_IS_READY
														object:nil];
	
	//Stop observing for GROWL_IS_READY
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self
															   name:GROWL_IS_READY
															 object:nil];

	//register (fixes #102: this is necessary if we got here by Growl having just been installed)
	[self reregisterGrowlNotifications];

	//Perform any queued notifications
	NSEnumerator *enumerator;
	NSDictionary *noteDict;
	
	enumerator = [queuedGrowlNotifications objectEnumerator];
	while ((noteDict = [enumerator nextObject])){
		//Post to Growl via NSDistributedNotificationCenter
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName:GROWL_NOTIFICATION
																	   object:nil
																	 userInfo:noteDict
														   deliverImmediately:NO];
	}

	[queuedGrowlNotifications release]; queuedGrowlNotifications = nil;
}

+ (NSBundle *) growlPrefPaneBundle {
	NSArray			*librarySearchPaths;
	NSString		*path;
	NSString		*bundleIdentifier;
	NSEnumerator	*searchPathEnumerator;
	NSBundle		*prefPaneBundle;

	static const unsigned bundleIDComparisonFlags = NSCaseInsensitiveSearch | NSBackwardsSearch;

	//Find Library directories in all domains except /System (as of Panther, that's ~/Library, /Library, and /Network/Library)
	librarySearchPaths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSAllDomainsMask & ~NSSystemDomainMask, YES);
	
	/*First up, we'll have a look for Growl.prefPane, and if it exists, check
	 *	whether it is our prefPane.
	 *This is much faster than having to enumerate all preference panes, and
	 *	can drop a significant amount of time off this code.
	 */
	searchPathEnumerator = [librarySearchPaths objectEnumerator];
	while ((path = [searchPathEnumerator nextObject])) {
		path = [path stringByAppendingPathComponent:PREFERENCE_PANES_SUBFOLDER_OF_LIBRARY];
		path = [path stringByAppendingPathComponent:GROWL_PREFPANE_NAME];

		if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
			prefPaneBundle = [NSBundle bundleWithPath:path];
			
			if (prefPaneBundle) {
				bundleIdentifier = [prefPaneBundle bundleIdentifier];

				if (bundleIdentifier && ([bundleIdentifier compare:GROWL_PREFPANE_BUNDLE_IDENTIFIER options:bundleIDComparisonFlags] == NSOrderedSame)) {
					return prefPaneBundle;
				}
			}
		}
	}
	
	/*Enumerate all installed preference panes, looking for the Growl prefpane
	 *	bundle identifier and stopping when we find it.
	 *Note that we check the bundle identifier because we should not insist
	 *	that the user not rename his preference pane files, although most users
	 *	of course will not.  If the user wants to mutilate the Info.plist file
	 *	inside the bundle, he/she deserves to not have a working Growl
	 *	installation.
	 */
	searchPathEnumerator = [librarySearchPaths objectEnumerator];
	while ((path = [searchPathEnumerator nextObject])) {
		NSString				*bundlePath;
		NSDirectoryEnumerator   *bundleEnum;

		path = [path stringByAppendingPathComponent:PREFERENCE_PANES_SUBFOLDER_OF_LIBRARY];
		bundleEnum = [[NSFileManager defaultManager] enumeratorAtPath:path];

		while ((bundlePath = [bundleEnum nextObject])) {
			if ([[bundlePath pathExtension] isEqualToString:PREFERENCE_PANE_EXTENSION]) {
				prefPaneBundle = [NSBundle bundleWithPath:[path stringByAppendingPathComponent:bundlePath]];

				if (prefPaneBundle) {
					bundleIdentifier = [prefPaneBundle bundleIdentifier];
	
					if (bundleIdentifier && ([bundleIdentifier compare:GROWL_PREFPANE_BUNDLE_IDENTIFIER options:bundleIDComparisonFlags] == NSOrderedSame)) {
						return prefPaneBundle;
					}
				}

				[bundleEnum skipDescendents];
			}
		}
	}
	
	return nil;
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
	
	ourGrowlPrefPaneInfoPath = [[NSBundle bundleForClass:[GrowlApplicationBridge class]] pathForResource:@"GrowlPrefPaneInfo" 
																								  ofType:@"plist"];

	NSDictionary *infoDict = [[NSDictionary alloc] initWithContentsOfFile:ourGrowlPrefPaneInfoPath];
	packagedVersion = [infoDict objectForKey:(NSString *)kCFBundleVersionKey];

	infoDictionary = [growlPrefPaneBundle infoDictionary];
	installedVersion = [infoDictionary objectForKey:(NSString *)kCFBundleVersionKey];

	//If the installed version is earlier than our packaged version, we can offer an upgrade.
	upgradeIsAvailable = (compareVersionStringsTranslating1_0To0_5(packagedVersion, installedVersion) == kCFCompareGreaterThan);
	if (upgradeIsAvailable && !promptedToUpgradeGrowl) {
		NSString	*lastDoNotPromptVersion;
		lastDoNotPromptVersion = [[NSUserDefaults standardUserDefaults] objectForKey:@"Growl Update:Do Not Prompt Again:Last Version"];
		
		if (!lastDoNotPromptVersion ||
			(compareVersionStringsTranslating1_0To0_5(packagedVersion, lastDoNotPromptVersion) == kCFCompareGreaterThan)) {
			[GrowlInstallationPrompt showUpdatePromptForVersion:packagedVersion];
			promptedToUpgradeGrowl = YES;
		}
	}
	[infoDict release];
}
#endif

@end
