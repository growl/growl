//
//  NSAdditions.h
//  Growl
//
//  Created by Karl Adam on Fri May 28 2004.
//  Copyright 2004 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to License.txt for details

#import <Foundation/Foundation.h>

@interface NSWorkspace (GrowlAdditions) 
- (NSImage *) iconForApplication:(NSString *) inName;
@end

@interface NSString (GrowlAdditions)
- (BOOL) boolValue;
@end

@interface NSWindow (GrowlAdditions)
-(void) setSticky:(BOOL)flag;
@end
