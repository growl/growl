//
//  GrowlMailFoundBundle.m
//  GrowlMailUUIDPatcher
//
//  Copyright 2010 The Growl Project. All rights reserved.
//

#import "GrowlMailFoundBundle.h"

#import "GMCompatibilityUUIDs.h"

@implementation GrowlMailFoundBundle

+ (id) foundBundleWithURL:(NSURL *)newURL {
	return [[[self alloc] initWithURL:newURL] autorelease];
}
- (id) initWithURL:(NSURL *)newURL {
	if ((self = [super init])) {
		URL = [newURL copy];
	}
	return self;
}

- (void) dealloc {
	[URL release];
	[super dealloc];
}

@synthesize URL;

- (BOOL) isCompatibleWithCurrentMailAndMessageFramework {
	//Can't use -[NSBundle objectForInfoDictionaryKey:] or -[NSBundle infoDictionary] here because NSBundle caches it, and that value is stale after the patcher does its work.
	NSURL *infoPlistURL = [[URL URLByAppendingPathComponent:@"Contents"] URLByAppendingPathComponent:@"Info.plist"];
	NSDictionary *infoPlist = [NSDictionary dictionaryWithContentsOfURL:infoPlistURL];
	NSArray *compatibilityUUIDs = [infoPlist objectForKey:@"SupportedPluginCompatibilityUUIDs"];
	return [compatibilityUUIDs containsObject:GMCurrentMailCompatibilityUUID()] && [compatibilityUUIDs containsObject:GMCurrentMessageFrameworkCompatibilityUUID()];
}

- (NSString *) bundleVersion {
	return [[NSBundle bundleWithURL:URL] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey];
}

- (NSSearchPathDomainMask) domain {
	if ([[URL path] hasPrefix:[NSHomeDirectory() stringByAppendingPathComponent:@"Library"]]) {
		return NSUserDomainMask;
	} else if ([[URL path] hasPrefix:@"/Library"]) {
		return NSLocalDomainMask;
	} else if ([[URL path] hasPrefix:@"/Network/Library"]) {
		return NSNetworkDomainMask;
	} else if ([[URL path] hasPrefix:@"/System/Library"]) {
		return NSSystemDomainMask;
	}

	return 0;
}

#pragma mark Debugging

- (NSString *) description {
	return [NSString stringWithFormat:@"<%@ %p version %@ at %@>",
		[self class], self,
		self.bundleVersion,
		[URL path]];
}

@end

#include <CoreServices/CoreServices.h>

@implementation GrowlMailFoundBundle (HeyTheresViewMethodsInMyModelClass)

//Returns the Home, Computer, Finder, or Network icon image.
- (NSImage *) domainImage {
	switch (self.domain) {
		case NSUserDomainMask:
			return [[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kToolbarHomeIcon)];
		case NSLocalDomainMask:
			return [NSImage imageNamed:NSImageNameComputer];
		case NSSystemDomainMask:
			return [[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kFinderIcon)];
		case NSNetworkDomainMask:
			return [NSImage imageNamed:NSImageNameNetwork];

		default:
			return [[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kQuestionMarkIcon)];
	}
}
//Returns either the white-checkmark-on-green-circle or white-X-on-red-circle image.
- (NSImage *) compatibleImage {
	return [self isCompatibleWithCurrentMailAndMessageFramework] ? [NSImage imageNamed:@"WhiteCheckmarkOnGreenCircle"] : [NSImage imageNamed:@"WhiteXOnRedCircle"];
}

@end
