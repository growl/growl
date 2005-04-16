//
//  NSGrowlAdditions.m
//  Growl
//
//  Created by Karl Adam on Fri May 28 2004.
//  Copyright 2004 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to License.txt for details

#import "NSGrowlAdditions.h"
#import "CoreGraphicsServices.h"

#pragma mark Foundation

@implementation NSString (GrowlAdditions)

+ (NSString *) stringWithUTF8String:(const char *)bytes length:(unsigned)len {
	return [[[NSString alloc] initWithUTF8String:bytes length:len] autorelease];
}

- (id) initWithUTF8String:(const char *)bytes length:(unsigned)len {
	return [self initWithBytes:bytes length:len encoding:NSUTF8StringEncoding];
}

//for greater polymorphism with NSNumber.
- (BOOL) boolValue {
	return [self intValue] != 0
		|| [self caseInsensitiveCompare:@"yes"]  == NSOrderedSame
		|| [self caseInsensitiveCompare:@"true"] == NSOrderedSame;
}

- (unsigned long) unsignedLongValue {
	return strtoul([self UTF8String], /*endptr*/ NULL, /*base*/ 0);
}

- (unsigned) unsignedIntValue {
	return [self unsignedLongValue];
}

#warning XXX - currently does not handle equivalence of things such as .. or .
- (BOOL) isSubpathOf:(NSString *)superpath {
	return [self isEqualToString:superpath] || [self hasPrefix:[superpath stringByAppendingString:@"/"]];
}

@end

#pragma mark -

#define _CFURLAliasDataKey  @"_CFURLAliasData"
#define _CFURLStringKey     @"_CFURLString"
#define _CFURLStringTypeKey @"_CFURLStringType"

@implementation NSURL (GrowlAdditions)

//'alias' as in the Alias Manager.
+ (NSURL *) fileURLWithAliasData:(NSData *)aliasData {
	NSParameterAssert(aliasData != nil);

	NSURL *URL = nil;

	AliasHandle alias = NULL;
	OSStatus err = PtrToHand([aliasData bytes], (Handle *)&alias, [aliasData length]);
	if (err != noErr) {
		NSLog(@"in +[NSURL(GrowlAdditions) fileURLWithAliasData:]: Could not allocate an alias handle from %u bytes of alias data (data follows) because PtrToHand returned %li\n%@", [aliasData length], aliasData, (long)err);
	} else {
		FSRef fsref;
		Boolean nobodyCares;
		err = FSResolveAlias(/*fromFile*/ NULL, alias, &fsref, /*wasChanged*/ &nobodyCares);
		if (err != noErr) {
			if (err != fnfErr) { //ignore file-not-found; it's harmless
				NSLog(@"in +[NSURL(GrowlAdditions) fileURLWithAliasData:]: Could not resolve alias (alias data follows) because FSResolveAlias returned %li - will try path\n%@", (long)err, aliasData);
			}
		} else {
			URL = [(NSURL *)CFURLCreateFromFSRef(kCFAllocatorDefault, &fsref) autorelease];
		}
	}

	return URL;
}

- (NSData *) aliasData {
	//return nil for non-file: URLs.
	if ([[self scheme] caseInsensitiveCompare:@"file"] != NSOrderedSame)
		return nil;

	NSData       *aliasData = nil;

	FSRef fsref;
	if (CFURLGetFSRef((CFURLRef)self, &fsref)) {
		AliasHandle alias = NULL;
		OSStatus    err   = FSNewAlias(/*fromFile*/ NULL, &fsref, &alias);
		if (err != noErr) {
			NSLog(@"in -[NSURL(GrowlAdditions) dockDescription]: FSNewAlias for %@ returned %li", self, (long)err);
		} else {
			HLock((Handle)alias);

			aliasData = [NSData dataWithBytes:*alias length:GetHandleSize((Handle)alias)];

			HUnlock((Handle)alias);
			DisposeHandle((Handle)alias);
		}
	}

	return aliasData;
}

//these are the type of external representations used by Dock.app.
+ (NSURL *) fileURLWithDockDescription:(NSDictionary *)dict {
	NSURL *URL = nil;

	NSString *path      = [dict objectForKey:_CFURLStringKey];
	NSData   *aliasData = [dict objectForKey:_CFURLAliasDataKey];

	if (aliasData) 
		URL = [self fileURLWithAliasData:aliasData];

	if (!URL) {
		if (path) {
			NSNumber *pathStyleNum = [dict objectForKey:_CFURLStringTypeKey];
			CFURLPathStyle pathStyle = pathStyleNum ? [pathStyleNum intValue] : kCFURLPOSIXPathStyle;

			BOOL isDir = YES;
			BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir];

			if (exists) {
				URL = [(NSURL *)CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (CFStringRef)path, pathStyle, /*isDirectory*/ isDir) autorelease];
			}
		}
	}

	return URL;
}

- (NSDictionary *) dockDescription {
	NSMutableDictionary *dict;
	NSString *path      = [self path];
	NSData   *aliasData = [self aliasData];

	if (path || aliasData) {
		dict = [NSMutableDictionary dictionaryWithCapacity:3U];

		if (path) {
			NSNumber *type = [[NSNumber alloc] initWithInt:kCFURLPOSIXPathStyle];
			[dict setObject:path forKey:_CFURLStringKey];
			[dict setObject:type forKey:_CFURLStringTypeKey];
			[type release];
		}

		if (aliasData) {
			[dict setObject:aliasData forKey:_CFURLAliasDataKey];
		}
	} else {
		dict = nil;
	}

	return dict;
}

@end

#pragma mark -
#pragma mark AppKit

@implementation NSWorkspace (GrowlAdditions)

- (NSImage *) iconForApplication:(NSString *) inName {
	NSString *path = [self fullPathForApplication:inName];
	NSImage *appIcon = path ? [self iconForFile:path] : nil;

	if (appIcon) {
		[appIcon setSize:NSMakeSize(128.0f,128.0f)];
	}
	return appIcon;
}

@end
