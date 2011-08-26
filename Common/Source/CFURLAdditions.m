//
//  CFURLAdditions.c
//  Growl
//
//  Created by Karl Adam on Fri May 28 2004.
//  Copyright 2004-2006 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to License.txt for details

#include "CFURLAdditions.h"
#include <stdbool.h>
#include <Carbon/Carbon.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/stat.h>
#import <Foundation/Foundation.h>

static NSString *_CFURLAliasDataKey  = @"_CFURLAliasData";
static NSString *_CFURLStringKey     = @"_CFURLString";
static NSString *_CFURLStringTypeKey = @"_CFURLStringType";

//'alias' as in the Alias Manager.
NSURL *createFileURLWithAliasData(NSData *aliasData) {
	if (!aliasData) {
		NSLog(@"WARNING: createFileURLWithAliasData called with NULL aliasData");
		return NULL;
	}

	NSURL *url = nil;

	AliasHandle alias = NULL;
	OSStatus err = PtrToHand([aliasData bytes], (Handle *)&alias, [aliasData length]);
	if (err != noErr) {
		NSLog(@"in createFileURLWithAliasData: Could not allocate an alias handle from %lu bytes of alias data (data follows) because PtrToHand returned %li\n%@", [aliasData length], (long)err, aliasData);
	} else {
		CFStringRef path = nil;
		/*
		 * FSResolveAlias mounts disk images or network shares to resolve
		 * aliases, thus we resort to FSCopyAliasInfo.
		 */
		err = FSCopyAliasInfo(alias,
							  /* targetName */ NULL,
							  /* volumeName */ NULL,
							  &path,
							  /* whichInfo */ NULL,
							  /* info */ NULL);
		DisposeHandle((Handle)alias);
		if (err != noErr) {
			if (err != fnfErr) //ignore file-not-found; it's harmless
				NSLog(@"in createFileURLWithAliasData: Could not resolve alias (alias data follows) because FSResolveAlias returned %li - will try path\n%@", (long)err, aliasData);
		} else if (path) {
			url = [[NSURL alloc] initFileURLWithPath:(NSString*)path isDirectory:YES];
		} else {
			NSLog(@"in createFileURLWithAliasData: FSCopyAliasInfo returned a NULL path");
		}
		CFRelease(path);
	}

	return [url autorelease];
}

NSData *createAliasDataWithURL(NSURL *theURL) {
	//return NULL for non-file: URLs.
	CFStringRef scheme = CFURLCopyScheme((CFURLRef)theURL);
	CFComparisonResult isFileURL = CFStringCompare(scheme, (CFStringRef)@"file", kCFCompareCaseInsensitive);
	CFRelease(scheme);
	if (isFileURL != kCFCompareEqualTo)
		return NULL;

	NSData *aliasData = nil;

	FSRef fsref;
	if (CFURLGetFSRef((CFURLRef)theURL, &fsref)) {
		AliasHandle alias = NULL;
		OSStatus    err   = FSNewAlias(/*fromFile*/ NULL, &fsref, &alias);
		if (err != noErr) {
			NSLog(@"in createAliasDataForURL: FSNewAlias for %@ returned %li", theURL, (long)err);
		} else {
			HLock((Handle)alias);

			aliasData = (NSData*)CFDataCreate(kCFAllocatorDefault, (const UInt8 *)*alias, GetHandleSize((Handle)alias));

			HUnlock((Handle)alias);
			DisposeHandle((Handle)alias);
		}
	}

	return aliasData;
}

//these are the type of external representations used by Dock.app.
NSURL *createFileURLWithDockDescription(NSDictionary *dict) {
	NSURL *url = nil;

	NSString *path      = [dict valueForKey:_CFURLStringKey];
	NSData *aliasData = [dict valueForKey:_CFURLAliasDataKey];

	if (aliasData)
		url = createFileURLWithAliasData(aliasData);

	if (!url) {
		if (path) {
			NSNumber *pathStyleNum = [dict valueForKey:_CFURLStringTypeKey];
			CFURLPathStyle pathStyle = kCFURLPOSIXPathStyle;
			
			if (pathStyleNum)
				pathStyle = [pathStyleNum intValue];

			char *filename;
         CFIndex size = CFStringGetMaximumSizeOfFileSystemRepresentation((CFStringRef)path);
         filename  = malloc(size);
            [path getFileSystemRepresentation:filename maxLength:size];
			int fd = open(filename, O_RDONLY, 0);
			free(filename);
			if (fd != -1) {
				struct stat sb;
				fstat(fd, &sb);
				close(fd);
				url = (NSURL*)CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (CFStringRef)path, pathStyle, /*isDirectory*/ (bool)(sb.st_mode & S_IFDIR));
			}
		}
	}

	return url;
}

NSDictionary *createDockDescriptionWithURL(NSURL *theURL) {
	NSMutableDictionary *dict;

	if (!theURL) {
		NSLog(@"in createDockDescriptionWithURL: Cannot copy Dock description for a NULL URL");
		return NULL;
	}

	CFStringRef path     = CFURLCopyFileSystemPath((CFURLRef)theURL, kCFURLPOSIXPathStyle);
	CFDataRef aliasData  = (CFDataRef)createAliasDataWithURL(theURL);

	if (path || aliasData) {
		dict = [NSMutableDictionary dictionary];

		if (path) {
			[dict setValue:(NSString*)path forKey:_CFURLStringKey];
			CFRelease(path);
            [dict setValue:[NSNumber numberWithInt:kCFURLPOSIXPathStyle] forKey:_CFURLStringTypeKey];
		}

		if (aliasData) {
			[dict setValue:(NSData*)aliasData forKey:_CFURLAliasDataKey];
			CFRelease(aliasData);
		}
	} else {
		dict = NULL;
	}

	return dict;
}
