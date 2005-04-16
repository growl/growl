//
//  CFGrowlAdditions.c
//  Growl
//
//  Created by Mac-arena the Bored Zo on Wed Jun 18 2004.
//  Copyright 2005 The Growl Project.
//

#include <Carbon/Carbon.h>
#include "CFGrowlAdditions.h"

static CFStringRef _CFURLAliasDataKey  = CFSTR("_CFURLAliasData");
static CFStringRef _CFURLStringKey     = CFSTR("_CFURLString");
static CFStringRef _CFURLStringTypeKey = CFSTR("_CFURLStringType");

//see GrowlApplicationBridge-Carbon.c for rationale of using NSLog.
extern void NSLog(CFStringRef format, ...);

CFStringRef copyCurrentProcessName(void) {
	ProcessSerialNumber PSN = { 0, kCurrentProcess };
	CFStringRef name = NULL;
	OSStatus err = CopyProcessName(&PSN, &name);
	if (err != noErr) {
		NSLog(CFSTR("in copyCurrentProcessName in CFGrowlAdditions: Could not get process name because CopyProcessName returned %li"), (long)err);
		name = NULL;
	}
	return name;
}

CFURLRef copyCurrentProcessURL(void) {
	ProcessSerialNumber psn = { 0, kCurrentProcess };
	FSRef fsref;
	CFURLRef URL = NULL;
	OSStatus err = GetProcessBundleLocation(&psn, &fsref);
	if (err != noErr) {
		NSLog(CFSTR("in copyCurrentProcessURL in CFGrowlAdditions: Could not get application location, because GetProcessBundleLocation returned %li\n"), (long)err);
	} else {
		URL = CFURLCreateFromFSRef(kCFAllocatorDefault, &fsref);
	}
	return URL;
}
CFStringRef copyCurrentProcessPath(void) {
	CFURLRef URL = copyCurrentProcessURL();
	CFStringRef path = CFURLCopyFileSystemPath(URL, kCFURLPOSIXPathStyle);
	CFRelease(URL);
	return path;
}

CFStringRef copyTemporaryFolderPath(void) {
	FSRef ref;
	CFStringRef string;
	OSStatus err = FSFindFolder(kOnAppropriateDisk, kTemporaryFolderType, kCreateFolder, &ref);
	if (err != noErr) {
		NSLog(CFSTR("in copyTemporaryFolderPath in CFGrowlAdditions: Could not locate temporary folder because FSFindFolder returned %li"), (long)err);
		string = NULL;
	} else {
		CFURLRef url = CFURLCreateFromFSRef(kCFAllocatorDefault, &ref);
		string = CFURLCopyFileSystemPath(url, kCFURLPOSIXPathStyle);
		CFRelease(url);
	}
	return string;
}

CFDictionaryRef createDockDescriptionForURL(CFURLRef url) {
	if (!url) {
		NSLog(CFSTR("%@"), CFSTR("in copyDockDescriptionForURL in CFGrowlAdditions: Cannot copy Dock description for a NULL URL"));
		return NULL;
	}

	//return NULL for non-file: URLs.
	CFStringRef scheme = CFURLCopyScheme(url);
	Boolean isFileURL = (CFStringCompare(scheme, CFSTR("file"), kCFCompareCaseInsensitive) == kCFCompareEqualTo);
	CFRelease(scheme);
	if (!isFileURL)
		return NULL;

	CFDictionaryRef dict = NULL;
	CFStringRef path     = NULL;
	CFDataRef aliasData  = NULL;

	FSRef    fsref;
	if (CFURLGetFSRef(url, &fsref)) {
		AliasHandle alias = NULL;
		OSStatus    err   = FSNewAlias(/*fromFile*/ NULL, &fsref, &alias);
		if (err != noErr) {
			NSLog(CFSTR("in copyDockDescriptionForURL in CFGrowlAdditions: FSNewAlias for %@ returned %li"), url, (long)err);
		} else {
			HLock((Handle)alias);

			err = FSCopyAliasInfo(alias, /*targetName*/ NULL, /*volumeName*/ NULL, (CFStringRef *)&path, /*whichInfo*/ NULL, /*info*/ NULL);
			if (err != noErr) {
				NSLog(CFSTR("in copyDockDescriptionForURL in CFGrowlAdditions: FSCopyAliasInfo for %@ returned %li"), url, (long)err);
			}

			aliasData = CFDataCreate(kCFAllocatorDefault, (UInt8 *)*alias, GetHandleSize((Handle)alias));

			HUnlock((Handle)alias);
			DisposeHandle((Handle)alias);
		}
	}

	if (!path) {
		path = CFURLCopyFileSystemPath(url, kCFURLPOSIXPathStyle);
	}

	if (path || aliasData) {
		CFMutableDictionaryRef temp = CFDictionaryCreateMutable(kCFAllocatorDefault, /*capacity*/ 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);

		if (path) {
			CFDictionarySetValue(temp, _CFURLStringKey, path);
			CFRelease(path);

			int pathStyle = kCFURLPOSIXPathStyle;
			CFNumberRef pathStyleNum = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &pathStyle);
			CFDictionarySetValue(temp, _CFURLStringTypeKey, pathStyleNum);
			CFRelease(pathStyleNum);
		}

		if (aliasData) {
			CFDictionarySetValue(temp, _CFURLAliasDataKey, aliasData);
			CFRelease(aliasData);
		}

		dict = temp;
	}

	return dict;
}

CFDataRef copyIconDataForPath(CFStringRef path) {
	CFDataRef data = NULL;

	//false is probably safest, and is harmless when the object really is a directory.
	CFURLRef URL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, path, kCFURLPOSIXPathStyle, /*isDirectory*/ false);
	if (URL) {
		data = copyIconDataForURL(URL);
		CFRelease(URL);
	}

	return data;
}
CFDataRef copyIconDataForURL(CFURLRef URL) {
	CFDataRef data = NULL;

	if (URL) {
		FSRef ref;
		if (CFURLGetFSRef(URL, &ref)) {
			IconRef icon = NULL;
			SInt16 label_noOneCares;
			OSStatus err = GetIconRefFromFileInfo(&ref,
												  /*inFileNameLength*/ 0U, /*inFileName*/ NULL,
												  kFSCatInfoNone, /*inCatalogInfo*/ NULL,
												  kIconServicesNoBadgeFlag | kIconServicesUpdateIfNeededFlag,
												  &icon,
												  &label_noOneCares);
			if (err != noErr) {
				NSLog(CFSTR("in copyIconDataForURL in CFGrowlAdditions: could not get icon for %@: GetIconRefFromFileInfo returned %li\n"), URL, (long)err);
			} else {
				IconFamilyHandle fam = NULL;
				err = IconRefToIconFamily(icon, kSelectorAllAvailableData, &fam);
				if (err != noErr) {
					NSLog(CFSTR("in copyIconDataForURL in CFGrowlAdditions: could not get icon for %@: IconRefToIconFamily returned %li\n"), URL, (long)err);
				} else {
					HLock((Handle)fam);
					data = CFDataCreate(kCFAllocatorDefault, (const UInt8 *)*(Handle)fam, GetHandleSize((Handle)fam));
					HUnlock((Handle)fam);
					DisposeHandle((Handle)fam);
				}
				ReleaseIconRef(icon);
			}
		}
	}

	return data;
}
