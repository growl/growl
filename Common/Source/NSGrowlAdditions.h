//
//  NSGrowlAdditions.h
//  Growl
//
//  Created by Karl Adam on Fri May 28 2004.
//  Copyright 2004 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to License.txt for details

#import <Cocoa/Cocoa.h>

#pragma mark Foundation

@interface NSString (GrowlAdditions)

- (BOOL) boolValue;

+ (NSString *) stringWithUTF8String:(const char *)bytes length:(unsigned)len;
- (id) initWithUTF8String:(const char *)bytes length:(unsigned)len;
- (void)drawWithEllipsisInRect:(NSRect)rect withAttributes:(NSDictionary *)attributes;

@end

@interface NSURL (GrowlAdditions)

//these are the type of external representations used by Dock.app.
+ fileURLWithDockDescription:(NSDictionary *)dict;
//-dockDescription returns nil for non-file: URLs.
- (NSDictionary *)dockDescription;

@end

#pragma mark AppKit

@interface NSWindow (GrowlAdditions)

- (void) setSticky:(BOOL)flag;

@end

@interface NSWorkspace (GrowlAdditions)

- (NSImage *) iconForApplication:(NSString *) inName;

@end
