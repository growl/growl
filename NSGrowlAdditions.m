//
//  NSAdditions.m
//  Growl
//
//  Created by Karl Adam on Fri May 28 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "NSGrowlAdditions.h"

@implementation NSWorkspace (GrowlAdditions)

- (NSImage *) iconForApplication:(NSString *) inName {
	NSString *path = [self fullPathForApplication:inName];
	NSLog(@"Pulled icon for %@ from path: %@",inName,path);
	return path ? [self iconForFile:path] : nil;
}

@end

@implementation NSString (GrowlAdditions)

- (BOOL)boolValue {
	return [self intValue];
}

@end

// thanks to Alcor for the following
typedef int CGSConnection;
typedef int CGSWindow;
extern CGSConnection _CGSDefaultConnection(void);

OSStatus CGSGetWindowTags(CGSConnection cid,CGSWindow widow,int *tags,int other);
OSStatus CGSSetWindowTags(CGSConnection cid,CGSWindow widow,int *tags,int other);

@implementation NSWindow (GrowlAdditions)

-(void)setSticky:(BOOL)flag {
	CGSConnection cid;
	CGSWindow wid;
	
	wid = [self windowNumber ];
	cid = _CGSDefaultConnection();
	int tags[2];
	tags[0] = tags[1] = 0;
	OSStatus retVal = CGSGetWindowTags(cid, wid, tags, 32);
	if(!retVal) {
		if (flag)
			tags[0] = tags[0] | 0x00000800;
		else
			tags[0] = tags[0] & 0x00000800;
		retVal = CGSSetWindowTags(cid, wid, tags, 32);
	}
}

@end
