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

CFStringRef _copyCurrentProcessName(void) {
	ProcessSerialNumber PSN = { 0, kCurrentProcess };
	CFStringRef name = NULL;
	OSStatus err = CopyProcessName(&PSN, &name);
	if (err != noErr) {
		NSLog(CFSTR("in CFGrowlAdditions: Could not get process name because CopyProcessName returned %li"), (long)err);
		name = NULL;
	}
	return name;
}

CFURLRef _copyCurrentProcessURL(void) {
	ProcessSerialNumber psn = { 0, kCurrentProcess };
	FSRef fsref;
	CFURLRef URL = NULL;
	OSStatus err = GetProcessBundleLocation(&psn, &fsref);
	if(err != noErr)
		NSLog(CFSTR("in CFGrowlAdditions: Could not get application location, because GetProcessBundleLocation returned %li\n"), (long)err);
	else
		URL = CFURLCreateFromFSRef(kCFAllocatorDefault, &fsref);
	return URL;
}
CFStringRef _copyCurrentProcessPath(void) {
	CFURLRef URL = _copyCurrentProcessURL();
	CFStringRef path = CFURLCopyFileSystemPath(URL, kCFURLPOSIXPathStyle);
	CFRelease(URL);
	return path;
}

CFStringRef _copyTemporaryFolderPath(void) {
	FSRef ref;
	CFStringRef string;
	OSStatus err = FSFindFolder(kOnAppropriateDisk, kTemporaryFolderType, kCreateFolder, &ref);
	if (err != noErr) {
		NSLog(CFSTR("in CFGrowlAdditions: Could not locate temporary folder because FSFindFolder returned %li"), (long)err);
		string = NULL;
	} else {
		CFURLRef url = CFURLCreateFromFSRef(kCFAllocatorDefault, &ref);
		string = CFURLCopyFileSystemPath(url, kCFURLPOSIXPathStyle);
		CFRelease(url);
	}
	return string;
}

CFDictionaryRef _createDockDescriptionForURL(CFURLRef url) {
	if(!url) {
		NSLog(CFSTR("%@"), CFSTR("in CFGrowlAdditions' _copyDockDescriptionForURL: Cannot copy Dock description for a NULL URL"));
		return NULL;
	}

	//return NULL for non-file: URLs.
	CFStringRef scheme = CFURLCopyScheme(url);
	Boolean isFileURL = (CFStringCompare(scheme, CFSTR("file"), kCFCompareCaseInsensitive) == kCFCompareEqualTo);
	CFRelease(scheme);
	if(isFileURL)
		return NULL;

	CFDictionaryRef dict = NULL;
	CFStringRef path     = NULL;
	CFDataRef aliasData  = NULL;

	FSRef    fsref;
	if(CFURLGetFSRef(url, &fsref)) {
		AliasHandle alias = NULL;
		OSStatus    err   = FSNewAlias(/*fromFile*/ NULL, &fsref, &alias);
		if(err != noErr) {
			NSLog(CFSTR("in CFGrowlAdditions' _copyDockDescriptionForURL: FSNewAlias for %@ returned %li"), url, (long)err);
		} else {
			HLock((Handle)alias);

			err = FSCopyAliasInfo(alias, /*targetName*/ NULL, /*volumeName*/ NULL, (CFStringRef *)&path, /*whichInfo*/ NULL, /*info*/ NULL);
			if(err != noErr)
				NSLog(CFSTR("in CFGrowlAdditions' _copyDockDescriptionForURL: FSCopyAliasInfo for %@ returned %li"), url, (long)err);

			aliasData = CFDataCreate(kCFAllocatorDefault, (UInt8 *)*alias, GetHandleSize((Handle)alias));

			HUnlock((Handle)alias);
			DisposeHandle((Handle)alias);
		}
	}

	if(!path)
		path = CFURLCopyFileSystemPath(url, kCFURLPOSIXPathStyle);

	if(path || aliasData) {
		CFMutableDictionaryRef temp = CFDictionaryCreateMutable(kCFAllocatorDefault, /*capacity*/ 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);

		if(path) {
			CFDictionarySetValue(temp, _CFURLStringKey, path);
			CFRelease(path);

			int pathStyle = kCFURLPOSIXPathStyle;
			CFNumberRef pathStyleNum = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &pathStyle);
			CFDictionarySetValue(temp, _CFURLStringTypeKey, pathStyleNum);
			CFRelease(pathStyleNum);
		}

		if(aliasData) {
			CFDictionarySetValue(temp, _CFURLAliasDataKey, aliasData);
			CFRelease(aliasData);
		}

		dict = temp;
	}

	return dict;
}
