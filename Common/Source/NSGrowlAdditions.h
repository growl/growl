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

+ (NSString *) stringWithUTF8String:(const char *)bytes length:(unsigned)len;
- (id) initWithUTF8String:(const char *)bytes length:(unsigned)len;
- (BOOL) boolValue;

@end

@interface NSURL (GrowlAdditions)

//'alias' as in the Alias Manager.
+ (NSURL *)fileURLWithAliasData:(NSData *)aliasData;
- (NSData *)aliasData;

//these are the type of external representations used by Dock.app.
+ (NSURL *)fileURLWithDockDescription:(NSDictionary *)dict;
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
