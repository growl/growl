//
//  GrowlApplicationBridge.m
//  Growl
//
//  Created by Evan Schoenberg on Wed Jun 16 2004.
//

#import "GrowlApplicationBridge.h"

#define PREFERENCE_PANES_SUBFOLDER_OF_LIBRARY			@"PreferencePanes"
#define PREFERENCE_PANE_EXTENSION						@"prefPane"

@interface GrowlApplicationBridge (PRIVATE)
+ (NSArray *)_allPreferencePaneBundles;
@end

@implementation GrowlApplicationBridge

/*
+ (BOOL)launchGrowlIfInstalledNotifyingTarget:(id)target selector:(SEL)selector context:(void *)context
Returns YES (TRUE) if the Growl helper app began launching.
Returns NO (FALSE) and performs no other action if the Growl prefPane is not properly installed.
GrowlApplicationBridge will send "selector" to "target" when Growl is ready for use (this will only occur when it also returns YES).
	Note: selector should take a single argument; this is to allow applications to have context-relevent information passed back. It is perfectly
	acceptable for context to be NULL.
*/

static  NSMutableArray *targetsToNotifyArray = nil;

+ (BOOL)launchGrowlIfInstalledNotifyingTarget:(id)target selector:(SEL)selector context:(void *)context
{
	NSEnumerator	*preferencePanesPathsEnumerator;
	NSString		*path, *bundleIdentifier;
	NSBundle		*prefPaneBundle;
	NSBundle		*growlPrefPaneBundle = nil;
	BOOL			success = NO;
	
	//Enumerate all installed preference panes, looking for the growl prefpane bundle identifier and stopping when we find it
	//Note that we check the bundle identifier because we should not insist the user not rename his preference pane files, although most users
	//of course will not.  If the user wants to destroy the info.plist file inside the bundle, he/she deserves not to have a working Growl installation.
	preferencePanesPathsEnumerator = [[self _allPreferencePaneBundles] objectEnumerator];
	while (path = [preferencePanesPathsEnumerator nextObject]){
		prefPaneBundle = [NSBundle bundleWithPath:path];
		if (prefPaneBundle){
			bundleIdentifier = [prefPaneBundle bundleIdentifier];
			if (bundleIdentifier && [bundleIdentifier isEqualToString:GROWL_PREFPANE_BUNDLE_IDENTIFIER]){
				growlPrefPaneBundle = prefPaneBundle;
				break;
			}
		}
	}
	
	if (growlPrefPaneBundle){
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
		if (!targetsToNotifyArray) targetsToNotifyArray = [[NSMutableArray alloc] init];
		NSDictionary	*infoDict = [NSDictionary dictionaryWithObjectsAndKeys:target,@"Target",
										NSStringFromSelector(selector),@"Selector",
										[NSValue valueWithPointer:context],@"Context",nil];
		[targetsToNotifyArray addObject:infoDict];
		
		//Houston, we are go for launch.
		if ([[NSWorkspace sharedWorkspace] launchApplication:growlHelperAppPath]){
			success = YES;
		}
	}
	
	
	return success;
}

+ (void)_growlIsReady:(NSNotification *)notification
{
	NSEnumerator	*enumerator = [targetsToNotifyArray objectEnumerator];
	NSDictionary	*infoDict;
	while (infoDict = [enumerator nextObject]){
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

//Returns an array of paths to all user-installed .prefPane bundles
+ (NSArray *)_allPreferencePaneBundles
{
	NSArray			*librarySearchPaths;
	NSEnumerator	*searchPathEnumerator;
	NSString		*preferencePanesSubfolder, *path, *prefPaneExtension;
	NSMutableArray  *pathArray = [NSMutableArray arrayWithCapacity:4];
	NSMutableArray  *allPreferencePaneBundles = [NSMutableArray array];

	preferencePanesSubfolder = PREFERENCE_PANES_SUBFOLDER_OF_LIBRARY;
	
	//Find Library directories in all domains except /System (as of Panther, that's ~/Library, /Library, and /Network/Library)
	librarySearchPaths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSAllDomainsMask - NSSystemDomainMask, YES);
	searchPathEnumerator = [librarySearchPaths objectEnumerator];
	
	//Copy each discovered path into the pathArray after adding our subfolder path
	while(path = [searchPathEnumerator nextObject]){
		[pathArray addObject:[path stringByAppendingPathComponent:preferencePanesSubfolder]];
	}

	prefPaneExtension = PREFERENCE_PANE_EXTENSION;
	
	searchPathEnumerator = [pathArray objectEnumerator];		
    while(path = [searchPathEnumerator nextObject]){
		
        NSString				*bundlePath;
		NSDirectoryEnumerator   *bundleEnum;

        bundleEnum = [[NSFileManager defaultManager] enumeratorAtPath:path];
		
        if(bundleEnum){
			
            while(bundlePath = [bundleEnum nextObject]) {				
                if([[bundlePath pathExtension] isEqualToString:prefPaneExtension]) {
					
					[allPreferencePaneBundles addObject:[path stringByAppendingPathComponent:bundlePath]];
                }
            }
        }
    }

	return allPreferencePaneBundles;
}

@end
