//
//  NSMutableStringAdditions.h
//  Growl
//
//  Created by Ingmar Stein on 19.04.05.
//  Copyright 2005 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to License.txt for details

#import <Cocoa/Cocoa.h>

@interface NSMutableString (GrowlAdditions)
- (NSMutableString *) escapeForJavaScript;
- (NSMutableString *) escapeForHTML;
@end
