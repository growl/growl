//
//  NSGrowlAdditions.h
//  Growl
//
//  Created by Karl Adam on Fri May 28 2004.
//  Copyright 2004 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to License.txt for details

#import <Cocoa/Cocoa.h>

@interface NSWorkspace (GrowlAdditions)

- (NSImage *)iconForApplication:(NSString *) inName;

@end

@interface NSString (GrowlAdditions)

- (BOOL)boolValue;

+ (NSString *)stringWithUTF8String:(const char *)bytes length:(unsigned)len;
- (id)initWithUTF8String:(const char *)bytes length:(unsigned)len;

@end

@interface NSWindow (GrowlAdditions)

-(void)setSticky:(BOOL)flag;

@end
