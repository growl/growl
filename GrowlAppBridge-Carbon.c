//
//  GrowlApplicationBridge-Carbon.c
//  Beep-Carbon
//
//  Created by Mac-arena the Bored Zo on Wed Jun 18 2004.
//  Based on GrowlApplicationBridge.m by Evan Schoenberg.
//  This source code is in the public domain. You may freely link it into any
//    program.
//

#include "GrowlAppBridge-Carbon.h"
#include "GrowlDefinesCarbon.h"

#define PREFERENCE_PANE_EXTENSION						CFSTR("prefPane")

static CFArrayRef _copyAllPreferencePaneBundles(void);
//notification callback.
static void _growlIsReady(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo);

static	CFMutableArrayRef targetsToNotifyArray = NULL;

/*
Boolean LaunchGrowlIfInstalled(GrowlLaunchCallback callback, void *context)

Returns TRUE if the Growl helper app began launching.
Returns FALSE and performs no other action if the Growl prefPane is not properly installed.
callback will be called when Growl is ready for use (this will only occur when LaunchGrowlIfInstalled returns TRUE).
	Note: callback should take a single argument; this is to allow applications to have context-relevant information passed back. It is perfectly acceptable for context to be NULL.
*/

Boolean LaunchGrowlIfInstalled(GrowlLaunchCallback callback, void *context)
{
	CFArrayRef		prefPanes;
	CFIndex			prefPaneIndex = 0, numPrefPanes = 0;
	CFStringRef		bundleIdentifier;
	CFBundleRef		prefPaneBundle;
	CFBundleRef		growlPrefPaneBundle = NULL;
	Boolean			success = false;
	
	//Enumerate all installed preference panes, looking for the growl prefpane bundle identifier and stopping when we find it
	//Note that we check the bundle identifier because we should not insist the user not rename his preference pane files, although most users
	//of course will not.  If the user wants to destroy the info.plist file inside the bundle, he/she deserves not to have a working Growl installation.
	prefPanes = _copyAllPreferencePaneBundles();
	if(prefPanes) {
		numPrefPanes = CFArrayGetCount(prefPanes);

		while(prefPaneIndex < numPrefPanes) {
			prefPaneBundle = (CFBundleRef)CFArrayGetValueAtIndex(prefPanes, prefPaneIndex++);

			if (prefPaneBundle){
				bundleIdentifier = CFBundleGetIdentifier(prefPaneBundle);

				if (bundleIdentifier && (CFStringCompare(bundleIdentifier, GROWL_PREFPANE_BUNDLE_IDENTIFIER, kCFCompareCaseInsensitive | kCFCompareBackwards) == kCFCompareEqualTo)) {
					growlPrefPaneBundle = (CFBundleRef)CFRetain(prefPaneBundle);
					break;
				}
			}
		}

		CFRelease(prefPanes);
	}
	
	if(growlPrefPaneBundle){
		/* Here we could check against a current version number and ensure the installed Growl pane is the newest */
		
		CFURLRef	growlHelperAppURL = NULL;
		
		//Extract the path to the Growl helper app from the pref pane's bundle
		growlHelperAppURL = CFBundleCopyResourceURL(growlPrefPaneBundle, CFSTR("GrowlHelperApp"), CFSTR("app"), /*subDirName*/ NULL);

		if(growlHelperAppURL) {
			if(callback) {
				//the Growl helper app will notify us via growlIsReady when it is done launching
				CFNotificationCenterAddObserver(CFNotificationCenterGetDistributedCenter(), /*observer*/ (void *)_growlIsReady, _growlIsReady, GROWL_IS_READY, /*object*/ NULL, CFNotificationSuspensionBehaviorCoalesce);
			
				//We probably will never have more than one target/selector/context set at a time, but this is cleaner than the alternatives
				if (!targetsToNotifyArray) targetsToNotifyArray = CFArrayCreateMutable(kCFAllocatorDefault, /*capacity*/ 0, &kCFTypeArrayCallBacks);

				{
					CFStringRef keys[] = { CFSTR("Callback"), CFSTR("Context") };
					void *values[] = { (void *)callback, context };
					CFDictionaryRef	infoDict = CFDictionaryCreate(kCFAllocatorDefault, (const void **)keys, (const void **)values, /*numValues*/ 2, &kCFTypeDictionaryKeyCallBacks, /*valueCallbacks*/ NULL);
					if(infoDict) {
						CFArrayAppendValue(targetsToNotifyArray, infoDict);
						CFRelease(infoDict);
					}
				}
			}

			//Houston, we are go for launch.
			//we use LSOpenFromURLSpec because it can act synchronously.
			struct LSLaunchURLSpec launchSpec = { growlHelperAppURL, /*itemURLs*/ NULL, /*passThruParams*/ NULL, /*launchFlags*/ kLSLaunchDontAddToRecents | kLSLaunchDontSwitch | kLSLaunchNoParams, /*asyncRefCon*/ NULL };
			success = (LSOpenFromURLSpec(&launchSpec, /*outLaunchedURL*/ NULL) == noErr);
			CFRelease(growlHelperAppURL);
		}

		CFRelease(growlPrefPaneBundle);
	}

	return success;
}

//notification callback.
static void _growlIsReady(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	CFIndex			dictIndex = 0, numDicts = CFArrayGetCount(targetsToNotifyArray);
	CFDictionaryRef	infoDict;

	while(dictIndex < numDicts) {
		infoDict = CFArrayGetValueAtIndex(targetsToNotifyArray, dictIndex++);

		GrowlLaunchCallback callback = (GrowlLaunchCallback)CFDictionaryGetValue(infoDict, CFSTR("Callback"));
		void *context = (void *)CFDictionaryGetValue(infoDict, CFSTR("Context"));

		callback(context);
	}
	
	//Stop observing
	CFNotificationCenterRemoveEveryObserver(CFNotificationCenterGetDistributedCenter(), (void *)_growlIsReady);
	
	//Clear our tracking array
	CFRelease(targetsToNotifyArray); targetsToNotifyArray = NULL;
}

//Returns an array of paths to all user-installed .prefPane bundles
static CFArrayRef _copyAllPreferencePaneBundles(void)
{
	CFStringRef			prefPaneExtension = PREFERENCE_PANE_EXTENSION;
	CFMutableArrayRef	allPreferencePaneBundles = CFArrayCreateMutable(kCFAllocatorDefault, /*capacity*/ 0, &kCFTypeArrayCallBacks);
	CFArrayRef			curDirContents;
	CFRange				contentsRange = { 0, 0 };
	CFURLRef			curDirURL;
	OSStatus			err;
	FSRef				curDir;

	//Find Library directories in all domains except /System (as of Panther, that's ~/Library, /Library, and /Network/Library)
#define PREFPANEGRAB(destArray, domain) \
	err = FSFindFolder((domain), kPreferencePanesFolderType, /*createFolder*/ false, &curDir); \
	if(err == noErr) { \
		curDirURL = CFURLCreateFromFSRef(kCFAllocatorDefault, &curDir); \
		if(curDirURL) { \
			curDirContents = CFBundleCreateBundlesFromDirectory(kCFAllocatorDefault, curDirURL, prefPaneExtension); \
			if(curDirContents) { \
				contentsRange.length = CFArrayGetCount(curDirContents); \
				CFArrayAppendArray((destArray), curDirContents, contentsRange); \
				CFRelease(curDirContents); \
			} \
			CFRelease(curDirURL); \
		} \
	}

	PREFPANEGRAB(allPreferencePaneBundles, kUserDomain)
	PREFPANEGRAB(allPreferencePaneBundles, kLocalDomain)
	PREFPANEGRAB(allPreferencePaneBundles, kNetworkDomain)

	return allPreferencePaneBundles;
}
