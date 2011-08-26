//
//  NSMutableStringAdditions.h
//  Growl
//
//  Created by Mac-arena the Bored Zo on 2006-02-11.
//  Copyright 2006 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to License.txt for details
//

@interface NSMutableString (GrowlAdditions)

- (void) appendCharacter:(unichar)ch;

- (NSMutableString*)escapeForJavaScript;
- (NSMutableString*)escapeForHTML;

@end
