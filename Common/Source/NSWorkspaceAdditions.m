//
//  NSWorkspaceAdditions.m
//  Growl
//
//  Created by Ingmar Stein on 16.05.05.
//  Copyright 2005-2006 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to License.txt for details

#import "NSWorkspaceAdditions.h"
#include <ApplicationServices/ApplicationServices.h>

@implementation NSWorkspace (GrowlAdditions)

- (NSImage *) iconForApplication:(NSString *) inName {
	NSString *path = [self fullPathForApplication:inName];
	NSImage *appIcon = path ? [self iconForFile:path] : nil;

	if (appIcon)
		[appIcon setSize:NSMakeSize(128.0,128.0)];

	return appIcon;
}

- (BOOL) getFileType:(out NSString **)outFileType creatorCode:(out NSString **)outCreatorCode forURL:(NSURL *)URL {
	NSParameterAssert(URL != nil);

	struct LSItemInfoRecord rec;

	OSStatus err = LSCopyItemInfoForURL((CFURLRef)URL, kLSRequestTypeCreator, &rec);
	if (err == noErr) {
		if (outFileType)    *outFileType    = NSFileTypeForHFSTypeCode(rec.filetype);
		if (outCreatorCode) *outCreatorCode = NSFileTypeForHFSTypeCode(rec.creator);
	}

	return (err == noErr);
}
- (BOOL) getFileType:(out NSString **)outFileType creatorCode:(out NSString **)outCreatorCode forFile:(NSString *)path {
	NSURL *URL = [[NSURL alloc] initFileURLWithPath:path];
	BOOL success = [self getFileType:outFileType creatorCode:outCreatorCode forURL:URL];
	[URL release];
	return success;
}

@end
