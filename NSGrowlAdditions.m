//
//  NSGrowlAdditions.m
//  Growl
//
//  Created by Karl Adam on Fri May 28 2004.
//  Copyright 2004 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to License.txt for details

#import "NSGrowlAdditions.h"

@implementation NSWorkspace (GrowlAdditions)

- (NSImage *) iconForApplication:(NSString *) inName {
	NSString *path = [self fullPathForApplication:inName];
	NSImage *appIcon = path ? [self iconForFile:path] : nil;
	
	if ( appIcon ) {
		[appIcon setSize:NSMakeSize(128.0f,128.0f)];
	}
	return appIcon;
}

@end

#pragma mark -

@implementation NSString (GrowlAdditions)

+ (NSString *) stringWithUTF8String:(const char *)bytes length:(unsigned)len {
	return [[[self alloc] initWithUTF8String:bytes length:len] autorelease];
}

- (id) initWithUTF8String:(const char *)bytes length:(unsigned)len {
	return [self initWithBytes:bytes length:len encoding:NSUTF8StringEncoding];
}

- (BOOL) boolValue {
	return [self intValue];
}

@end

#pragma mark -

// Thanks to Alcor for the following. This allows us to tell the window manager
// that the window should be sticky. A sticky window will stay around when the
// ExposŽ sweep-all-windows-away event happens. Additionally, if a window is not
// sticky while it fades in (see KABubbleWindowController for an example of fading
// in), and simultaneously the desktop is switched via DesktopManager, the window
// may end up getting left on the previous desktop, even if that window's level 
// set to NSStatusWindowLevel. See http://www.cocoadev.com/index.pl?DontExposeMe 
// for more information.
typedef int CGSConnection;
typedef int CGSWindow;
extern CGSConnection _CGSDefaultConnection(void);

OSStatus CGSGetWindowTags(CGSConnection cid,CGSWindow window,int *tags,int other);
OSStatus CGSSetWindowTags(CGSConnection cid,CGSWindow window,int *tags,int other);

@implementation NSWindow (GrowlAdditions)

-(void) setSticky:(BOOL)flag {
	// Check if we are on Panther or better (for expose)
	if ( floor( NSAppKitVersionNumber ) > NSAppKitVersionNumber10_2 ) {
		CGSConnection cid;
		CGSWindow wid;
		
		wid = [self windowNumber];
		cid = _CGSDefaultConnection();
		int tags[2];
		tags[0] = tags[1] = 0;
		OSStatus retVal = CGSGetWindowTags(cid, wid, tags, 32);
		
		if (!retVal) {
			if (flag)
				tags[0] = tags[0] | 0x00000800;
			else
				tags[0] = tags[0] & 0x00000800;
			retVal = CGSSetWindowTags(cid, wid, tags, 32);
		}
	}
}

@end
