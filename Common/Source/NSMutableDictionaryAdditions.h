//
//  NSMutableDictionaryAdditions.h
//  Growl
//
//  Created by Ingmar Stein on 29.05.05.
//  Copyright 2005 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to License.txt for details

#import <Cocoa/Cocoa.h>

@interface NSMutableDictionary(GrowlAdditions)

- (void) setBool:(BOOL)value forKey:(NSString *)key;
- (void) setInteger:(int)value forKey:(NSString *)key;

@end
