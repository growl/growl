//
//  GrowlApplicationBridge.m
//  Growl
//
//  Created by Evan Schoenberg on Wed Jun 16 2004.
//

#import "GrowlApplicationBridge.h"
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
+ (NSBundle *)growlPrefPaneBundle;

+ (NSEnumerator *) _preferencePaneSearchEnumerator;
+ (NSArray *)_allPreferencePaneBundles;
@end

@implementation GrowlAppBridge

/*
+ (BOOL)launchGrowlIfInstalledNotifyingTarget:(id)target selector:(SEL)selector context:(void *)context registrationDict:(NSDictionary *)registrationDict
Returns YES (TRUE) if the Growl helper app began launching.
Returns NO (FALSE) and performs no other action if the Growl prefPane is not properly installed.
GrowlApplicationBridge will send "selector" to "target" when Growl is ready for use (this will only occur when it also returns YES).
	Note: selector should take a single argument; this is to allow applications to have context-relevent information passed back. It is perfectly
	acceptable for context to be NULL.
Passing registrationDict, which is an NSDictionary *for registering the application with Growl (see documentation elsewhere)
	is the preferred way to register.  If Growl is installed but disabled, the application will be registered and GrowlHelperApp
	will then quit.  "selector" will never be sent to "target" if Growl is installed but disabled; this method will still
	return YES.
*/

static NSMutableArray *targetsToNotifyArray = nil;

+ (NSBundle *)growlPrefPaneBundle
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
		path = [path stringByAppendingFormat:@"/%@", GROWL_PREFPANE_NAME];
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

+ (BOOL)launchGrowlIfInstalledNotifyingTarget:(id)target selector:(SEL)selector context:(void *)context registrationDict:(NSDictionary *)registrationDict
{
	NSBundle		*growlPrefPaneBundle;
	BOOL			success = NO;

	growlPrefPaneBundle = [GrowlAppBridge growlPrefPaneBundle];

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
		if (!targetsToNotifyArray) {
			targetsToNotifyArray = [[NSMutableArray alloc] init];
		}
		NSDictionary	*infoDict = [NSDictionary dictionaryWithObjectsAndKeys:target, @"Target",
										NSStringFromSelector(selector), @"Selector",
										[NSValue valueWithPointer:context], @"Context",nil];
		[targetsToNotifyArray addObject:infoDict];
		
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
			spec.numDocs = (passRegDict ? 1 :0);
			spec.itemRefs = (passRegDict ? &regItemRef : NULL);
			spec.passThruParams = NULL;
			spec.launchFlags = kLSLaunchNoParams | kLSLaunchAsync | kLSLaunchDontSwitch;
			spec.asyncRefCon = NULL;
			status = LSOpenFromRefSpec( &spec, NULL );
		}
		success = (status == noErr);
	}
	
	return success;
}
//Compatibility method. Do not use. If you're already using it, switch to the above method.
+ (BOOL)launchGrowlIfInstalledNotifyingTarget:(id)target selector:(SEL)selector context:(void *)context {
	return [self launchGrowlIfInstalledNotifyingTarget:target
											  selector:selector
											   context:context
									  registrationDict:nil];
}

+ (BOOL)isGrowlRunning {
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

+ (void)_growlIsReady:(NSNotification *)notification
{
	NSEnumerator	*enumerator = [targetsToNotifyArray objectEnumerator];
	NSDictionary	*infoDict;
	while ( (infoDict = [enumerator nextObject] ) ) {
		id  target = [infoDict objectForKey:@"Target"];
		SEL selector = NSSelectorFromString([infoDict objectForKey:@"Selector"]);
		void *context = [[infoDict objectForKey:@"Context"] pointerValue];
		
		[target performSelector:selector
					 withObject:context];
	}
	
	//Stop observing
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
	
	//Clear our tracking array
	[targetsToNotifyArray release]; targetsToNotifyArray = nil;
}

// Returns an enumerator covering each of the locations preference panes can live
+ (NSEnumerator *) _preferencePaneSearchEnumerator
{
	NSArray			*librarySearchPaths;
	NSEnumerator	*searchPathEnumerator;
	NSString		*preferencePanesSubfolder, *path;
	NSMutableArray  *pathArray = [NSMutableArray arrayWithCapacity:4];
	
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
