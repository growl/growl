//
//  GrowlApplicationBridge-Carbon.c
//  Beep-Carbon
//
//  Created by Mac-arena the Bored Zo on Wed Jun 18 2004.
//  Based on GrowlApplicationBridge.m by Evan Schoenberg.
//  This source code is in the public domain. You may freely link it into any
//    program.
//

#include "GrowlApplicationBridge-Carbon.h"
#include "GrowlDefinesCarbon.h"

#pragma mark Constants

#define PREFERENCE_PANES_SUBFOLDER_OF_LIBRARY			CFSTR("PreferencePanes")
#define PREFERENCE_PANE_EXTENSION						CFSTR("prefPane")

#define GROWL_PREFPANE_BUNDLE_IDENTIFIER	CFSTR("com.growl.prefpanel")
#define GROWL_PREFPANE_NAME					CFSTR("Growl.prefPane")

#pragma mark -
#pragma mark Private API (declarations)

static CFArrayRef _copyAllPreferencePaneBundles(void);
//notification callback.
static void _growlIsReady(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo);

static	CFMutableArrayRef targetsToNotifyArray = NULL;

#ifdef GROWL_WITH_INSTALLER
static void _checkForPackagedUpdateForGrowlPrefPaneBundle(CFBundle *growlPrefPaneBundle);
#endif

struct GrowlDelegate *delegate = NULL;

//these functions are part of Foundation, and return NSStrings.
//thanks to toll-free bridging, we can simply declare them like this, and use
//	them as if they were pure CF functions.
extern CFStringRef NSTemporaryDirectory(void);
extern void NSLog(CFStringRef format, ...);

//helper functions.
static CFBundleRef _CopyGrowlPrefPaneBundle(void);
//these two join with a slash ("one/two").
static CFStringRef _CreateCFStringFromTwoCFStringPathComponents(CFStringRef one, CFStringRef two);
static CFStringRef _CreateCFStringFromThreeCFStringPathComponents(CFStringRef one, CFStringRef two, CFStringRef three);

#pragma mark -
#pragma mark Public API

Boolean Growl_SetDelegate(struct GrowlDelegate *newDelegate) {
	if(newDelegate && !(newDelegate->applicationName))
		return false;

	if(delegate && (delegate->release))
		delegate->release(delegate);
	if(newDelegate && newDelegate->retain)
		newDelegate = newDelegate->retain(newDelegate);
	delegate = newDelegate;

	return true;
}

void Growl_GetDelegate(void) {
	return delegate;
}

void Growl_PostNotification(const struct GrowlNotification *notification) {
	if(!notification) {
		NSLog(CFSTR("%@"), CFSTR("Growl_PostNotification called with a NULL notification\n"));
	}

	enum {
		nameIndex,
		titleIndex, descriptionIndex,
		priorityIndex,
		iconIndex,
		appIconIndex,

		highestKeyIndex = 5,
		numKeys,
	};
	void *keys[numKeys] = {
		GROWL_NOTIFICATION_NAME,
		GROWL_NOTIFICATION_TITLE, GROWL_NOTIFICATION_DESCRIPTION,
		GROWL_NOTIFICATION_PRIORITY,
		GROWL_NOTIFICATION_ICON,
		GROWL_NOTIFICATION_APP_ICON,
	};
	CFNumberRef priorityNumber = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &(notification->priority));
	void *values[numKeys] = {
		notification->name, //0
		notification->title, //1
		notification->description, //2
		priorityNumber, //3
		notification->iconData, //4
		NULL, //5
	};

	//make sure we have both a name and a title
	if(values[titleIndex] && !values[nameIndex])
		values[nameIndex] = values[titleIndex];
	else if(values[nameIndex] && !values[titleIndex])
		values[titleIndex] = values[nameIndex];

	//... and a description
	if(!values[descriptionIndex])
		values[descriptionIndex] = CFSTR("");

	//now, target the first NULL value.
	//if there was iconData, this is index 5; else, it is index 4.
	unsigned pairIndex = iconIndex + (values[iconIndex] != NULL);

	//...and set the custom application icon there.
	if(delegate && (delegate->applicationIcon)) {
		keys[pairIndex] = GROWL_NOTIFICATION_APP_ICON;
		values[pairIndex] = delegate->applicationIcon;
		++pairIndex;
	}

	CFDictionaryRef userInfo = CFDictionaryCreate(kCFAllocatorDefault,
	                                              keys, values,
	                                              /*numValues*/ pairIndex,
	                                              &kCFTypeDictionaryKeyCallBacks,
	                                              &kCFTypeDictionaryValueCallBacks);

	CFNotificationCenterPostNotification(CFNotificationCenterGetDistributedCenter(),
	                                     GROWL_NOTIFICATION,
	                                     /*object*/ NULL,
	                                     userInfo,
	                                     /*deliverImmediately*/ false);

	CFRelease(userInfo);
	CFRelease(priorityNumber);
}

void Growl_NotifyWithTitleDescriptionNameIconPriorityStickyClickContext(
	CFStringRef title,
	CFStringRef description,
	CFStringRef notificationName,
	CFDataRef iconData,
	signed int priority,
	Boolean isSticky,
	CFPropertyListRef clickContext)
{
	struct GrowlNotification notification;
	InitGrowlNotification(&notification);

	notification->name = notificationName;
	notification->title = title;
	notification->description = description;
	notification->iconData = iconData;
	notification->priority = priority;
	notification->isSticky = (isSticky != false);
	notification->clickContext = clickContext;

	Growl_PostNotification(&notification);
}

void Growl_Reregister(void) {
	if(delegate && delegate->registrationDictionary) {
		return LaunchGrowlIfInstalled(/*callback*/ NULL, /*context*/ NULL);
	}
}

/*Growl_IsInstalled
 *
 *Determines whether the Growl prefpane and its helper app are installed.
 *Returns true if Growl is installed, false otherwise.
 */
Boolean Growl_IsInstalled(void) {
	return GetGrowlPrefpaneBundle() != NULL;
}

/*Growl_IsRunning
 *
 *Cycles through the process list to find whether GrowlHelperApp is running.
 *Returns true if Growl is running, false otherwise.
 */
Boolean Growl_IsRunning(void) {
	Boolean growlIsRunning = false;
	ProcessSerialNumber PSN = { kNoProcess, kNoProcess };

	while (GetNextProcess(&PSN) == noErr) {
		NSDictionary *infoDict = (NSDictionary *)ProcessInformationCopyDictionary(&PSN, kProcessDictionaryIncludeAllInformationMask);

		if (CFEqual(CFDictionaryGetValue(infoDict, CFSTR("CFBundleIdentifier")), CFSTR("com.Growl.GrowlHelperApp"))) {
			growlIsRunning = true;
			CFRelease(infoDict);
			break;
		}
		CFRelease(infoDict);
	}

	return growlIsRunning;
}

Boolean Growl_LaunchIfInstalled(GrowlLaunchCallback callback, void *context) {
	CFMutableDictionaryRef regDict = NULL;
	if(delegate && (delegate->registrationDict)) {
		//create the registration dictionary.
		//this is the same as the one in the delegate, but it must have
		//	GROWL_APP_NAME in it.
		regDict = CFDictionaryCreateMutableCopy(kCFAllocatorDefault, 0, delegate->registrationDict);
		if(delegate->applicationName)
			CFDictionarySetValue(regDict, GROWL_APP_NAME, delegate->applicationName);
		if(!CFDictionaryContainsKey(regDict, GROWL_APP_NAME)) {
			//no registering for us, it seems.
			CFRelease(regDict);
			regDict = NULL;
		}
	}

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
		/*Here we could check against a current version number and ensure the
		 *	installed Growl pane is the newest
		 */
		
		CFURLRef	growlHelperAppURL = NULL;
		
		//Extract the path to the Growl helper app from the pref pane's bundle
		growlHelperAppURL = CFBundleCopyResourceURL(growlPrefPaneBundle, CFSTR("GrowlHelperApp"), CFSTR("app"), /*subDirName*/ NULL);

		if(growlHelperAppURL) {
			if(callback) {
				//the Growl helper app will notify us via growlIsReady when it is done launching
				CFNotificationCenterAddObserver(CFNotificationCenterGetDistributedCenter(), /*observer*/ (void *)_growlIsReady, _growlIsReady, GROWL_IS_READY, /*object*/ NULL, CFNotificationSuspensionBehaviorCoalesce);
			
				//We probably will never have more than one callback/context set at a time, but this is cleaner than the alternatives
				if (!targetsToNotifyArray)
					targetsToNotifyArray = CFArrayCreateMutable(kCFAllocatorDefault, /*capacity*/ 0, &kCFTypeArrayCallBacks);

				CFStringRef keys[] = { CFSTR("Callback"), CFSTR("Context") };
				void *values[] = { (void *)callback, context };
				CFDictionaryRef	infoDict = CFDictionaryCreate(kCFAllocatorDefault, (const void **)keys, (const void **)values, /*numValues*/ 2, &kCFTypeDictionaryKeyCallBacks, /*valueCallbacks*/ NULL);
				if(infoDict) {
					CFArrayAppendValue(targetsToNotifyArray, infoDict);
					CFRelease(infoDict);
				}
			}

			CFArrayRef itemsToOpen = NULL;

			if(regDict) {
				/*since we have a registration dictionary, we must want to
				 *	register.
				 *if this block gets skipped, GHA will simply be launched
				 *	directly (as if the user had double-clicked on it or
				 *	clicked 'Start Growl').
				 */
				//create the path: /tmp/$UID/$UUID.growlRegDict
				CFStringRef tmp = NSTemporaryDirectory();
				CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
				CFStringRef uuidString = CFUUIDCreateString(kCFAllocatorDefault, uuid);
				CFRelease(uuid);
				CFStringRef extension = CFSTR(GROWL_REG_DICT_EXTENSION);
				CFStringRef slash = CFSTR("/");
				CFStringRef fullstop = CFSTR(".");

				enum { numComponents = 5 };
				void *componentObjects[numComponents] = {
					tmp, slash, UUIDString, fullstop, extension,
				};
				CFArrayRef components = CFArrayCreate(kCFAllocatorDefault, componentObjects, numComponents, &kCFTypeArrayCallBacks);
				CFRelease(uuidString);
				CFStringRef regDictPath = CFStringCreateByCombiningStrings(kCFAllocatorDefault, components, /*separator*/ CFSTR(""));
				CFRelease(components);

				CFURLRef regDictURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, regDictPath, kCFURLPOSIXPathStyle, /*isDirectory*/ false);
				CFRelease(regDictPath);

				//write out the dictionary to that path.
				CFWriteStreamRef stream = CFWriteStreamCreateWithFile(kCFAllocatorDefault, regDictURL);

				CFStringRef errorString = NULL;
				CFPropertyListWriteToStream(regDict, stream, kCFPropertyListXMLFormat_v1_0, &errorString);
				if(errorString)
					NSLog(CFSTR("Error writing registration dictionary to URL %@: %@"), regDictURL, errorString);

				CFWriteStreamClose(stream);
				CFRelease(stream);

				//be sure to open the file.
				itemsToOpen = CFArrayCreate(kCFAllocatorDefault, &regDictURL, /*count*/ 1, &kCFTypeArrayCallBacks);
				CFRelease(regDictURL);
			}

			//Houston, we are go for launch.
			//we use LSOpenFromURLSpec because it can act synchronously.
			struct LSLaunchURLSpec launchSpec = {
				.appURL = growlHelperAppURL,
				.itemURLs = itemsToOpen,
				.passThruParams = NULL,
				.launchFlags = kLSLaunchDontAddToRecents | kLSLaunchDontSwitch | kLSLaunchNoParams,
				.asyncRefCon = NULL,
			};
			success = (LSOpenFromURLSpec(&launchSpec, /*outLaunchedURL*/ NULL) == noErr);
			CFRelease(growlHelperAppURL);
			if(itemsToOpen)
				CFRelease(itemsToOpen);
		}

		CFRelease(growlPrefPaneBundle);
	}

	CFRelease(regDict);

	return success;
}

#pragma mark -
#pragma mark Deprecated API

//keep these documentation comments

/*Boolean LaunchGrowlIfInstalled(GrowlLaunchCallback callback, void *context)
 *
 *Returns TRUE if the Growl helper app began launching.
 *Returns FALSE and performs no other action if the Growl prefPane is not properly installed.
 *callback will be called when Growl is ready for use (this will only occur when
 *	LaunchGrowlIfInstalled returns TRUE).
 *Note: callback should take a single argument; this is to allow applications to
 *	have context-relevant information passed back. It is perfectly acceptable
 *	for context to be NULL.
 *Note: This is no longer the recommended way to use Growl. Use the Growl
 *	delegate functions instead.
 *Additional features in 0.6:
 *	-	If a delegate is set, and the delegate has a registration dictionary,
 *		registration will be performed atomically with the launch.
 */

//to avoid code duplication, this function is currently called with
//	callback = NULL by LaunchGrowlIfInstalledNoCallback
//	and by Growl_Reregister.
//this will change when this function goes away.

Boolean LaunchGrowlIfInstalled(GrowlLaunchCallback callback, void *context) {
	return Growl_LaunchIfInstalled(callback, context);
}

#pragma mark -
#pragma mark Private API

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

#undef PREFPANEGRAB

	return allPreferencePaneBundles;
}

static CFBundleRef _CopyGrowlPrefPaneBundle(void) {
	CFBundleRef		growlPrefPaneBundle = NULL;

	CFStringRef		bundleIdentifier;
	CFBundleRef		prefPaneBundle;

	//first try looking up the prefpane by name.
	{
//outPtr should be a CFBundleRef *.
#define COPYPREFPANE(domain, outPtr) \
	do { \
		FSRef domain;
		err = FSFindFolder((domain), kPreferencePanesFolderType, /*createFolder*/ false, &domain); \
		if(err == noErr) { \
			CFURLRef domainURL = CFURLCreateFromFSRef(kCFAllocatorDefault, &domain); \
			if(domainURL) { \
				CFURLRef prefPaneURL = CFURLCreateCopyAppendingPathComponent(kCFAllocatorDefault, domainURL, GROWL_PREFPANE_NAME, /*isDirectory*/ true); \
				CFRelease(domainURL); \
				if(prefPaneURL) { \
					(*outPtr) = CFBundleCreate(kCFAllocatorDefault, prefPaneURL); \
					CFRelease(prefPaneURL); \
				} \
			} \
		} \
	while(0)

		//User domain.
		COPYPREFPANE(kUserDomain, &prefPaneBundle);
		if(prefPaneBundle) {
			bundleIdentifier = CFBundleGetIdentifier(prefPaneBundle);
		
			if (bundleIdentifier && (CFStringCompare(bundleIdentifier, GROWL_PREFPANE_BUNDLE_IDENTIFIER, bundleIDComparisonFlags) == kCFCompareEqualTo)) {
				growlPrefPaneBundle = prefPaneBundle;
			}
		}

		if(!growlPrefPaneBundle) {
			//Local domain.
			COPYPREFPANE(kLocalDomain, &prefPaneBundle);
			if(prefPaneBundle) {
				bundleIdentifier = CFBundleGetIdentifier(prefPaneBundle);
			
				if (bundleIdentifier && (CFStringCompare(bundleIdentifier, GROWL_PREFPANE_BUNDLE_IDENTIFIER, bundleIDComparisonFlags) == kCFCompareEqualTo)) {
					growlPrefPaneBundle = prefPaneBundle;
				}
			}

			if(!growlPrefPaneBundle) {
				//Network domain.
				COPYPREFPANE(kNetworkDomain, &prefPaneBundle);
				if(prefPaneBundle) {
					bundleIdentifier = CFBundleGetIdentifier(prefPaneBundle);
				
					if (bundleIdentifier && (CFStringCompare(bundleIdentifier, GROWL_PREFPANE_BUNDLE_IDENTIFIER, bundleIDComparisonFlags) == kCFCompareEqualTo)) {
						growlPrefPaneBundle = prefPaneBundle;
					}
				}
			}
		}
	}

	if(!growlPrefPaneBundle) {
		//Enumerate all installed preference panes, looking for the growl prefpane bundle identifier and stopping when we find it
		//Note that we check the bundle identifier because we should not insist the user not rename his preference pane files, although most users
		//of course will not.  If the user wants to destroy the info.plist file inside the bundle, he/she deserves not to have a working Growl installation.
		CFArrayRef		prefPanes = _copyAllPreferencePaneBundles();
		if(prefPanes) {
			CFIndex		prefPaneIndex = 0, numPrefPanes = CFArrayGetCount(prefPanes);
			static const CFOptionBits bundleIDComparisonFlags = kCFCompareCaseInsensitive | kCFCompareBackwards;
	
			while(prefPaneIndex < numPrefPanes) {
				prefPaneBundle = (CFBundleRef)CFArrayGetValueAtIndex(prefPanes, prefPaneIndex++);
	
				if (prefPaneBundle){
					bundleIdentifier = CFBundleGetIdentifier(prefPaneBundle);
	
					if (bundleIdentifier && (CFStringCompare(bundleIdentifier, GROWL_PREFPANE_BUNDLE_IDENTIFIER, bundleIDComparisonFlags) == kCFCompareEqualTo)) {
						growlPrefPaneBundle = (CFBundleRef)CFRetain(prefPaneBundle);
						break;
					}
				}
			}
	
			CFRelease(prefPanes);
		}
	}

	return growlPrefPaneBundle;
}

#pragma mark -
#pragma mark Helpers

static UniChar slash = '/';

static CFStringRef _CreateCFStringFromTwoCFStringPathComponents(CFStringRef one, CFStringRef two) {
	CFIndex capacity = CFStringGetLength(one) + CFStringGetLength(two);
	CFMutableStringRef mutable = CFStringCreateMutableCopy(kCFAllocatorDefault, capacity, one);
	CFStringAppendCharacters(mutable, &slash, /*numChars*/ 1);
	CFStringAppend(mutable, two);
	CFStringRef joined = CFStringCreateCopy(kCFAllocatorDefault, mutable);
	CFRelease(mutable);
	return joined;
}
static CFStringRef _CreateCFStringFromThreeCFStringPathComponents(CFStringRef one, CFStringRef two, CFStringRef three) {
	CFIndex capacity = CFStringGetLength(one) + CFStringGetLength(two) + CFStringGetLength(three);
	CFMutableStringRef mutable = CFStringCreateMutableCopy(kCFAllocatorDefault, capacity, one);
	CFStringAppendCharacters(mutable, &slash, /*numChars*/ 1);
	CFStringAppend(mutable, two);
	CFStringAppendCharacters(mutable, &slash, /*numChars*/ 1);
	CFStringAppend(mutable, three);
	CFStringRef joined = CFStringCreateCopy(kCFAllocatorDefault, mutable);
	CFRelease(mutable);
	return joined;
}
