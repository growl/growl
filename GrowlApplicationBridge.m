//
//  GrowlApplicationBridge.m
//  Growl
//
//  Created by Evan Schoenberg on Wed Jun 16 2004.
//  Copyright 2004-2005 The Growl Project. All rights reserved.
//

#import "GrowlApplicationBridge.h"
#import "GrowlInstallationPrompt.h"

#import <ApplicationServices/ApplicationServices.h>

#define PREFERENCE_PANES_SUBFOLDER_OF_LIBRARY			@"PreferencePanes"
#define PREFERENCE_PANE_EXTENSION						@"prefPane"

@interface GrowlApplicationBridge (PRIVATE)
/*!
	@method growlPrefPaneBundle
	@abstract Returns the bundle containing Growl's PrefPane.
	@discussion Searches all installed PrefPanes for the Growl PrefPane.
	@result Returns an NSBundle if Growl's PrefPane is installed, nil otherwise
 */
+ (NSBundle *) growlPrefPaneBundle;

+ (NSEnumerator *) _preferencePaneSearchEnumerator;
+ (NSArray *) _allPreferencePaneBundles;

/*!
	@method launchGrowlIfInstalled
	@abstract Launches GrowlHelperApp
	@discussion Launches the GrowlHelperApp if it's not already running. GROWL_IS_READY will be posted to the distributed
		notification center once it is ready.
	@result Returns YES if GrowlHelperApp began launching or was already running, NO if Growl isn't installed
*/
+ (BOOL) launchGrowlIfInstalled;


#ifdef GROWL_WITH_INSTALLER
+ (void) _checkForPackagedUpdateForGrowlPrefPaneBundle:(NSBundle *)growlPrefPaneBundle;
#endif

+ (void) _deprecatedNotifyTargetsGrowlIsReady;

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

	//Cache the appName from the delegate
	[appName autorelease];
	appName = [[delegate applicationNameForGrowl] retain];
	
	//Cache the appIconData from the delegate if it responds to the growlAppIconData selector
	[appIconData autorelease];
	if ([delegate respondsToSelector:@selector(growlAppIconData)]){
		appIconData = [[delegate growlAppIconData] retain];
	}

	//Add the observer for GROWL_IS_READY which will be triggered later if all goes well
	[NSDNC addObserver:self 
			  selector:@selector(_growlIsReady:)
				  name:GROWL_IS_READY
				object:nil]; 

	//Watch for notification clicks if our delegate responds to the growlNotificationWasClicked: selector
	//Notifications will come in on a unique notification name based on our app name and GROWL_NOTIFICATION_CLICKED
	NSString	*growlNotificationClickedName = [appName stringByAppendingString:GROWL_NOTIFICATION_CLICKED];
	if([delegate respondsToSelector:@selector(growlNotificationWasClicked:)]){
		[NSDNC addObserver:self
				  selector:@selector(_growlNotificationWasClicked:)
					  name:growlNotificationClickedName 
					object:nil];
	}else{
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
			clickContext:(id)clickContext {
	NSAssert(delegate != nil, @"+[GrowlApplicationBridge setGrowlDelegate:] must be called before using this method.");
	
	NSParameterAssert(notifName != nil);	//Notification name is required.
	NSParameterAssert((title != nil) || (description != nil));	//At least one of title or description is required.

	// Build our noteDict from all passed parameters
	NSMutableDictionary *noteDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:	appName,	GROWL_APP_NAME,
																						notifName,	GROWL_NOTIFICATION_NAME,
																						nil];

	if (title)			[noteDict setObject:title forKey:GROWL_NOTIFICATION_TITLE];
	if (description)	[noteDict setObject:description forKey:GROWL_NOTIFICATION_DESCRIPTION];
	if (iconData)		[noteDict setObject:iconData forKey:GROWL_NOTIFICATION_ICON];
	if (appIconData)	[noteDict setObject:appIconData forKey:GROWL_NOTIFICATION_APP_ICON];		
	if (priority)		[noteDict setObject:[NSNumber numberWithInt:priority] forKey:GROWL_NOTIFICATION_PRIORITY];
	if (isSticky)		[noteDict setObject:[NSNumber numberWithBool:isSticky] forKey:GROWL_NOTIFICATION_STICKY];
	if (clickContext)	[noteDict setObject:clickContext forKey:GROWL_NOTIFICATION_CLICK_CONTEXT];

	if (growlLaunched) {

		//Post to Growl via NSDistributedNotificationCenter
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName:GROWL_NOTIFICATION
																	   object:nil
																	 userInfo:noteDict
														   deliverImmediately:NO];
	} else {
#ifdef GROWL_WITH_INSTALLER
		//Store this notification for posting if Growl launches if the user hasn't already said NO
		if(!userChoseNotToInstallGrowl){
			if(!queuedGrowlNotifications) queuedGrowlNotifications = [[NSMutableArray alloc] init];
			[queuedGrowlNotifications addObject:noteDict];
			
			//If we have not already asked the user to install Growl, do it now
			if(!promptedToInstallGrowl){
				[GrowlInstallationPrompt showInstallationPromptForUpdate:NO];
				promptedToInstallGrowl = YES;
			}
		}
#endif
	}
}

+ (NSBundle *) growlPrefPaneBundle {
	NSString		*path;
	NSString		*bundleIdentifier;
	NSEnumerator	*preferencePanesPathsEnumerator;
	NSBundle		*prefPaneBundle;
	
	// First up, we'll have a look for Growl.prefPane, and if it exists, check it is our prefPane
	// This is much faster than having to enumerate all preference panes, and can drop a significant
	// amount of time off this code
	preferencePanesPathsEnumerator = [self _preferencePaneSearchEnumerator];
	while ((path = [preferencePanesPathsEnumerator nextObject])) {
		path = [path stringByAppendingPathComponent:GROWL_PREFPANE_NAME];
		
		if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
			prefPaneBundle = [NSBundle bundleWithPath:path];
			
			if (prefPaneBundle){
				bundleIdentifier = [prefPaneBundle bundleIdentifier];
				
				if (bundleIdentifier && [bundleIdentifier isEqualToString:GROWL_PREFPANE_BUNDLE_IDENTIFIER]){
					return prefPaneBundle;
				}
			}
		}
	}
	
	//Enumerate all installed preference panes, looking for the growl prefpane bundle identifier and stopping when we find it
	//Note that we check the bundle identifier because we should not insist the user not rename his preference pane files, although most users
	//of course will not.  If the user wants to destroy the info.plist file inside the bundle, he/she deserves not to have a working Growl installation.
	preferencePanesPathsEnumerator = [[GrowlApplicationBridge _allPreferencePaneBundles] objectEnumerator];
	while ( (path = [preferencePanesPathsEnumerator nextObject] ) ) {
		prefPaneBundle = [NSBundle bundleWithPath:path];
		
		if (prefPaneBundle) {
			bundleIdentifier = [prefPaneBundle bundleIdentifier];
			
			if (bundleIdentifier && [bundleIdentifier isEqualToString:GROWL_PREFPANE_BUNDLE_IDENTIFIER]) {
				return prefPaneBundle;
			}
		}
	}
	
	return nil;
}

/*	+ (BOOL)launchGrowlIfInstalled
 *
 *Returns YES if the Growl helper app began launching or was already running.
 *Returns NO and performs no other action if the Growl prefPane is not properly
 *	installed.
 *Passing registrationDict, which is an NSDictionary for registering the
 *	application with Growl (see documentation elsewhere) is the preferred way to
 *	register.
 *If Growl is installed but disabled, the application will be registered and
 *	GrowlHelperApp will then quit.  This method will still return YES if Growl
 *	is installed but disabled.
 */
+ (BOOL) launchGrowlIfInstalled {
	NSBundle		*growlPrefPaneBundle;
	BOOL			success = NO;
	
	growlPrefPaneBundle = [GrowlApplicationBridge growlPrefPaneBundle];
	
	if (growlPrefPaneBundle) {
		NSString        *growlHelperAppPath = [growlPrefPaneBundle pathForResource:@"GrowlHelperApp"
																			ofType:@"app"];

#ifdef GROWL_WITH_INSTALLER
		/* Check against our current version number and ensure the installed Growl pane is the same or later */
		[self _checkForPackagedUpdateForGrowlPrefPaneBundle:growlPrefPaneBundle];
#endif

		//Houston, we are go for launch.
		//Let's launch in the background (unfortunately, requires Carbon)
		LSLaunchFSRefSpec spec;
		FSRef appRef;
		OSStatus status = FSPathMakeRef((UInt8 *)[growlHelperAppPath fileSystemRepresentation], &appRef, NULL);
		if (status == noErr) {
			NSDictionary *registrationDict = [delegate growlRegistrationDictionary];
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
				[registrationDict writeToFile:regDictPath atomically:NO];
				
				regStatus = FSPathMakeRef((UInt8 *)[regDictPath fileSystemRepresentation], &regItemRef, NULL);
				if (regStatus == noErr) passRegDict = YES;
			}

			spec.appRef = &appRef;
			spec.numDocs = (passRegDict != NO);
			spec.itemRefs = (passRegDict ? &regItemRef : NULL);
			spec.passThruParams = NULL;
			spec.launchFlags = kLSLaunchNoParams | kLSLaunchAsync | kLSLaunchDontSwitch;
			spec.asyncRefCon = NULL;
			status = LSOpenFromRefSpec( &spec, NULL );
			
			success = (status == noErr);
		}
	}

	return success;
}

+ (BOOL) isGrowlInstalled {
	return( [GrowlApplicationBridge growlPrefPaneBundle] != nil );
}

+ (BOOL) isGrowlRunning {
	BOOL growlIsRunning = NO;
	ProcessSerialNumber PSN = {kNoProcess, kNoProcess};
	
	while (GetNextProcess(&PSN) == noErr) {
		NSDictionary *infoDict = (NSDictionary *)ProcessInformationCopyDictionary(&PSN, kProcessDictionaryIncludeAllInformationMask);

		if ([[infoDict objectForKey:@"CFBundleIdentifier"] isEqualToString:@"com.Growl.GrowlHelperApp"]) {
			growlIsRunning = YES;
			[infoDict release];
			break;
		}
		[infoDict release];
	}
	
	return growlIsRunning;
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

	//Inform our delegate if it is interested
	if ([delegate respondsToSelector:@selector(growlIsReady)]){
		[delegate growlIsReady];
	}

	[self _deprecatedNotifyTargetsGrowlIsReady];
	
	//Post a notification locally
	[[NSNotificationCenter defaultCenter] postNotificationName:GROWL_IS_READY
														object:nil];
	
	//Stop observing for GROWL_IS_READY
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self
															   name:GROWL_IS_READY
															 object:nil];

	//Perform any queued notifications
	NSEnumerator *enumerator;
	NSDictionary *noteDict;
	
	enumerator = [queuedGrowlNotifications objectEnumerator];
	while((noteDict = [enumerator nextObject])){
		//Post to Growl via NSDistributedNotificationCenter
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName:GROWL_NOTIFICATION
																	   object:nil
																	 userInfo:noteDict
														   deliverImmediately:NO];
	}

	[queuedGrowlNotifications release]; queuedGrowlNotifications = nil;
}

// Returns an enumerator covering each of the locations preference panes can live
+ (NSEnumerator *) _preferencePaneSearchEnumerator {
	NSArray			*librarySearchPaths;
	NSEnumerator	*searchPathEnumerator;
	NSString		*preferencePanesSubfolder, *path;
	NSMutableArray  *pathArray = [NSMutableArray arrayWithCapacity:4U];
	
	preferencePanesSubfolder = PREFERENCE_PANES_SUBFOLDER_OF_LIBRARY;
	
	//Find Library directories in all domains except /System (as of Panther, that's ~/Library, /Library, and /Network/Library)
	librarySearchPaths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSAllDomainsMask - NSSystemDomainMask, YES);
	searchPathEnumerator = [librarySearchPaths objectEnumerator];
	
	//Copy each discovered path into the pathArray after adding our subfolder path
	while ((path = [searchPathEnumerator nextObject])) {
		[pathArray addObject:[path stringByAppendingPathComponent:preferencePanesSubfolder]];
	}
	
	return [pathArray objectEnumerator];	
}

// Returns an array of paths to all user-installed .prefPane bundles
+ (NSArray *) _allPreferencePaneBundles {
	NSEnumerator	*searchPathEnumerator;
	NSString		*path, *prefPaneExtension;
	NSMutableArray  *allPreferencePaneBundles = [NSMutableArray array];

	prefPaneExtension = PREFERENCE_PANE_EXTENSION;
	searchPathEnumerator = [self _preferencePaneSearchEnumerator];		
    
	while ( ( path = [searchPathEnumerator nextObject] ) ) {
		
        NSString				*bundlePath;
		NSDirectoryEnumerator   *bundleEnum;

        bundleEnum = [[NSFileManager defaultManager] enumeratorAtPath:path];

        if (bundleEnum) {
            while ( ( bundlePath = [bundleEnum nextObject] ) ) {
                if ([[bundlePath pathExtension] isEqualToString:prefPaneExtension]) {
					[allPreferencePaneBundles addObject:[path stringByAppendingPathComponent:bundlePath]];
                }
            }
        }
    }

	return allPreferencePaneBundles;
}

#ifdef GROWL_WITH_INSTALLER
/* Sent to us by GrowlInstallationPrompt if the user clicks Cancel so we can avoid prompting again this session
 * (or ever if they checked Don't Ask Again) */
+ (void) _userChoseNotToInstallGrowl {
	//Note the user's action so we stop queueing notifications, etc.
	userChoseNotToInstallGrowl = YES;

	//Clear our queued notifications; we won't be needing them
	[queuedGrowlNotifications release]; queuedGrowlNotifications = nil;
}

// Check against our current version number and ensure the installed Growl pane is the same or later
+ (void) _checkForPackagedUpdateForGrowlPrefPaneBundle:(NSBundle *)growlPrefPaneBundle {
	//Extract the path to the Growl helper app from the pref pane's bundle
	NSString	*ourGrowlPrefPaneInfoPath;
	float packagedVersion, installedVersion;

	ourGrowlPrefPaneInfoPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"GrowlPrefPaneInfo" 
																				ofType:@"plist"];

	packagedVersion = [[[NSDictionary dictionaryWithContentsOfFile:ourGrowlPrefPaneInfoPath] objectForKey:(NSString *)kCFBundleVersionKey] floatValue];
	installedVersion = [[[growlPrefPaneBundle infoDictionary] objectForKey:(NSString *)kCFBundleVersionKey] floatValue];
	if (installedVersion < packagedVersion) {
		if (!promptedToUpgradeGrowl) {
			[GrowlInstallationPrompt showInstallationPromptForUpdate:YES];
			promptedToUpgradeGrowl = YES;
			
		}
	}
}
#endif

#pragma mark Deprecated methods
/* Deprecated methods */

static NSMutableArray		*launchNotificationTargets = nil;

/*	+ (BOOL)launchGrowlIfInstalledNotifyingTarget:(id)target
 *                                       selector:(SEL)selector
 *                                        context:(void *)context
 *                               registrationDict:(NSDictionary *)registrationDict
 *
 *Returns YES if the Growl helper app began launching.
 *Returns NO and performs no other action if the Growl prefPane is not properly
 *	installed.
 *GrowlApplicationBridge will make target perform selector when Growl is ready
 *	for use (this will only occur when it also returns YES).
 *Note: selector can take a single argument, which will be the context argument
 *	passed to this method. It is perfectly acceptable for context to be NULL.
 *You should use the delegate system (see the GrowlApplicationBridgeDelegate
 *	protocol) instead of this method, as this method may be deprecated in the
 *	future.
 *If Growl is installed but disabled, the application will be registered and
 *	GrowlHelperApp will then quit.  "selector" will never be sent to "target" if
 *	Growl is installed but disabled; this method will still return YES.
 */
+ (BOOL) launchGrowlIfInstalledNotifyingTarget:(id)target selector:(SEL)selector context:(void *)context registrationDict:(NSDictionary *)registrationDict
{
	NSBundle		*growlPrefPaneBundle;
	BOOL			success = NO;
	
	growlPrefPaneBundle = [GrowlApplicationBridge growlPrefPaneBundle];
	
	if (growlPrefPaneBundle) {
		/* Here we could check against a current version number and ensure the installed Growl pane is the newest */
		
		NSString	*growlHelperAppPath;
		
		//Extract the path to the Growl helper app from the pref pane's bundle
		growlHelperAppPath = [growlPrefPaneBundle pathForResource:@"GrowlHelperApp" ofType:@"app"];
		
		//Launch the Growl helper app, which will notify us via growlIsReady when it is done launching
		[[NSDistributedNotificationCenter defaultCenter] addObserver:self 
															selector:@selector(_growlIsReady:)
																name:GROWL_IS_READY
															  object:nil]; 
		
		//We probably will never have more than one target/selector/context set at a time, but this is cleaner than the alternatives
		if (!launchNotificationTargets) {
			launchNotificationTargets = [[NSMutableArray alloc] init];
		}
		NSDictionary	*infoDict = [NSDictionary dictionaryWithObjectsAndKeys:target, @"Target",
			NSStringFromSelector(selector), @"Selector",
			[NSValue valueWithPointer:context], @"Context",nil];
		[launchNotificationTargets addObject:infoDict];
		
		//Houston, we are go for launch.
		//Let's launch in the background (unfortunately, requires Carbon)
		LSLaunchFSRefSpec spec;
		FSRef appRef;
		OSStatus status = FSPathMakeRef([growlHelperAppPath fileSystemRepresentation], &appRef, NULL);
		if (status == noErr) {
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
				[registrationDict writeToFile:regDictPath atomically:NO];
				
				regStatus = FSPathMakeRef([regDictPath fileSystemRepresentation], &regItemRef, NULL);
				if (regStatus == noErr) passRegDict = YES;
			}
			
			spec.appRef = &appRef;
			spec.numDocs = (passRegDict != NO);
			spec.itemRefs = (passRegDict ? &regItemRef : NULL);
			spec.passThruParams = NULL;
			spec.launchFlags = kLSLaunchNoParams | kLSLaunchAsync | kLSLaunchDontSwitch;
			spec.asyncRefCon = NULL;
			status = LSOpenFromRefSpec( &spec, NULL );
			
			success = (status == noErr);
		}
	}
	
	return success;
}

+ (BOOL) launchGrowlIfInstalledNotifyingTarget:(id)target selector:(SEL)selector context:(void *)context {
	return [self launchGrowlIfInstalledNotifyingTarget:target
											  selector:selector
											   context:context
									  registrationDict:nil];
}

+ (void) _deprecatedNotifyTargetsGrowlIsReady {
	if (launchNotificationTargets) {
		NSEnumerator	*enumerator = [launchNotificationTargets objectEnumerator];
		NSDictionary	*infoDict;
		while ( (infoDict = [enumerator nextObject] ) ) {
			id  target = [infoDict objectForKey:@"Target"];
			SEL selector = NSSelectorFromString([infoDict objectForKey:@"Selector"]);
			void *context = [[infoDict objectForKey:@"Context"] pointerValue];
			
			[target performSelector:selector
						 withObject:context];
		}
	}
}

@end
