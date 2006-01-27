//
//  CFMutableStringAdditions.h
//  Growl
//
//  Created by Ingmar Stein on 19.04.05.
//  Copyright 2005-2006 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to License.txt for details

#ifndef CFMUTABLESTRINGADDITIONS_H
#define CFMUTABLESTRINGADDITIONS_H

#include <CoreFoundation/CoreFoundation.h>

CFMutableStringRef escapeForJavaScript(CFMutableStringRef theString);
CFStringRef createStringByEscapingForHTML(CFStringRef theString);

#endif
