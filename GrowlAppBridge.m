//
//  GrowlAppBridge.m
//  Growl
//
//  Created by Evan Schoenberg on Wed Jun 16 2004.
//

#import "GrowlAppBridge.h"
#import "GrowlDefines.h"
#import <ApplicationServices/ApplicationServices.h>

#define PREFERENCE_PANES_SUBFOLDER_OF_LIBRARY			@"PreferencePanes"
#define PREFERENCE_PANE_EXTENSION						@"prefPane"

@interface GrowlAppBridge (PRIVATE)
/*!
	@method growlPrefPaneBundle
	@abstract Returns the bundle containing Growl's PrefPane.
	@discussion Searches all installed PrefPanes for the Growl PrefPane.
	@result Returns an NSBundle if Growl's PrefPane is installed, nil otherwise
 */
+ (NSBundle *) growlPrefPaneBundle;

+ (NSEnumerator *) _preferencePaneSearchEnumerator;
+ (NSArray *)_allPreferencePaneBundles;


/*!
	@method launchGrowlIfInstalled
	@abstract Launches GrowlHelperApp
	@discussion Launches the GrowlHelperApp if it's not already running. GROWL_IS_READY will be posted to the distributed
		notification center once it is ready.
	@result Returns YES if GrowlHelperApp began launching or was already running, NO if Growl isn't installed
*/
+ (BOOL) launchGrowlIfInstalled;
@end

@implementation GrowlAppBridge

static NSString	*appName = nil;
static NSData	*appIconData = nil;

static id		delegate = nil;
static BOOL		growlLaunched = NO;

/* ***********************
* This must be called before using GrowlAppBridge.  The methods in the GrowlAppBridgeDelegate are required;
* other methods defined in the informal protocol are optional.
* ***********************/
+ (void) setGrowlDelegate:(NSObject<GrowlAppBridgeDelegate> *)inDelegate
{
	NSDistributedNotificationCenter *NSDNC = [NSDistributedNotificationCenter defaultCenter];
	
	[delegate autorelease];
	delegate = [inDelegate retain];

	//Cache the appName from the delegate
	[appName autorelease];
	appName = [[delegate growlAppName] retain];
	
	//Cache the appIconData from the delegate if it responds to the growlAppIconData selector
	[appIconData autorelease];
	if([delegate respondsToSelector:@selector(growlAppIconData)]){
		appIconData = [[delegate growlAppIconData] retain];
	}

	//Add the observer for GROWL_IS_READY which will be triggered later if all goes well
	[NSDNC addObserver:self 
			  selector:@selector(_growlIsReady:)
				  name:GROWL_IS_READY
				object:nil]; 

	//Watch for notification clicks if our delegate responds to the growlNotificationWasClicked: selector
	//Notificaitons will come in on a unique notification name based on our app name and GROWL_NOTIFICATION_CLICKED
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

	//Could do version checking here or something.
	if( !(growlLaunched = [self launchGrowlIfInstalled]) ){
		NSLog(@"Growl failed to launch.");
	}
}

/*
 Send a notification to Growl for display. title, description, and notifName are required.
 All other id parameters may be nil to accept defaults. priority is 0 by default; isSticky is FALSE by default.
 */
+ (void) notifyWithTitle:(NSString *)title
			 description:(NSString *)description
		notificationName:(NSString *)notifName
				iconData:(NSData *)iconData 
				priority:(int)priority
				isSticky:(BOOL)isSticky
			clickContext:(id)clickContext
{
	NSAssert(delegate != nil, @"+[GrowlAppBridge setGrowlDelegate:] must be called before using this method.");
	
	//Notification name is required.
	NSParameterAssert(notifName != nil);

	//At least one of title or description is required.
	NSParameterAssert((title != nil) || (description != nil));

	//Build our noteDict from all passed parameters
	NSMutableDictionary *noteDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
		appName, GROWL_APP_NAME,
		notifName, GROWL_NOTIFICATION_NAME,
		nil];
	
	if (title) {
		[noteDict setObject:title forKey:GROWL_NOTIFICATION_TITLE];
	}
	
	if (description) {
		[noteDict setObject:description forKey:GROWL_NOTIFICATION_DESCRIPTION];
	}
	
	if (iconData) {
		[noteDict setObject:iconData forKey:GROWL_NOTIFICATION_ICON];
	}
	
	if (appIconData) {
		[noteDict setObject:appIconData forKey:GROWL_NOTIFICATION_APP_ICON];		
	}
	
	if (priority) {
		[noteDict setObject:[NSNumber numberWithInt:priority] forKey:GROWL_NOTIFICATION_PRIORITY];
	}
	
	if (isSticky) {
		[noteDict setObject:[NSNumber numberWithBool:isSticky] forKey:GROWL_NOTIFICATION_STICKY];		
	}
	
	if (clickContext) {
		[noteDict setObject:clickContext forKey:GROWL_NOTIFICATION_CLICK_CONTEXT];
	}
	
	if (growlLaunched) {
		//Post to Growl via NSDistributedNotificationCenter
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName:GROWL_NOTIFICATION
																	   object:nil
																	 userInfo:noteDict
														   deliverImmediately:NO];
	} else {
		NSLog(@"Growl failed to launch earlier!");
	}
}

+ (NSBundle *) growlPrefPaneBundle
{
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
		if ([[NSFileManager defaultManager] fileExistsAtPath:path])
		{
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
	preferencePanesPathsEnumerator = [[GrowlAppBridge _allPreferencePaneBundles] objectEnumerator];
	while ( (path = [preferencePanesPathsEnumerator nextObject] ) ) {
		prefPaneBundle = [NSBundle bundleWithPath:path];
		if (prefPaneBundle) {
			bundleIdentifier = [prefPaneBundle bundleIdentifier];
			if (bundleIdentifier && [bundleIdentifier isEqualToString:GROWL_PREFPANE_BUNDLE_IDENTIFIER]) {
				return prefPaneBundle;
			}
		}
	}

	return (nil);
}

/*
 + (BOOL)launchGrowlIfInstalled
 Returns YES (TRUE) if the Growl helper app began launching.
 Returns NO (FALSE) and performs no other action if the Growl prefPane is not properly installed.
 Passing registrationDict, which is an NSDictionary *for registering the application with Growl (see documentation elsewhere)
	is the preferred way to register.  If Growl is installed but disabled, the application will be registered and GrowlHelperApp
	will then quit.  This method will still return YES if Growl is installed but disabled.
 */
+ (BOOL) launchGrowlIfInstalled
{
	NSBundle		*growlPrefPaneBundle;
	BOOL			success = NO;

	growlPrefPaneBundle = [GrowlAppBridge growlPrefPaneBundle];

	if (growlPrefPaneBundle) {
		/* Here we could check against a current version number and ensure the installed Growl pane is the newest */
		NSDictionary	*registrationDict = [delegate growlRegistrationDict];

		NSString	*growlHelperAppPath;
		
		//Extract the path to the Growl helper app from the pref pane's bundle
		growlHelperAppPath = [growlPrefPaneBundle pathForResource:@"GrowlHelperApp" ofType:@"app"];

		//Houston, we are go for launch.
		//Let's launch in the background (unfortunately, requires Carbon)
		LSLaunchFSRefSpec spec;
		FSRef appRef;
		OSStatus status = FSPathMakeRef((UInt8 *)[growlHelperAppPath fileSystemRepresentation], &appRef, NULL);
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
				
				regStatus = FSPathMakeRef((UInt8 *)[regDictPath fileSystemRepresentation], &regItemRef, NULL);
				if (regStatus == noErr) passRegDict = YES;
			}

			spec.appRef = &appRef;
			spec.numDocs = (passRegDict != nil);
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
	return( [GrowlAppBridge growlPrefPaneBundle] != nil );
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

/* Selector called when a growl notification is clicked.  This should never be called manually, and the calling observer
 * should only be registered if the delegate responds to growlNotificationWasClicked: */
+ (void) _growlNotificationWasClicked:(NSNotification *)notification
{
	[delegate performSelector:@selector(growlNotificationWasClicked:)
				   withObject:[[notification userInfo] objectForKey:GROWL_KEY_CLICKED_CONTEXT]];
}

+ (void)_growlIsReady:(NSNotification *)notification
{
	//Inform our delegate if it is interested
	if([delegate respondsToSelector:@selector(growlIsReady)]){
		[delegate growlIsReady];
	}

	//Post a notification locally
	[[NSNotificationCenter defaultCenter] postNotificationName:GROWL_IS_READY
														object:nil];
	
	//Stop observing for GROWL_IS_READY
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self
															   name:GROWL_IS_READY
															 object:nil];
}

// Returns an enumerator covering each of the locations preference panes can live
+ (NSEnumerator *) _preferencePaneSearchEnumerator
{
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

//Returns an array of paths to all user-installed .prefPane bundles
+ (NSArray *)_allPreferencePaneBundles
{
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

@end
