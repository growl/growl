//
//  CFMutableDictionaryAdditions.h
//  Growl
//
//  Created by Ingmar Stein on 29.05.05.
//  Copyright 2005-2006 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to License.txt for details

#ifndef HAVE_CFMUTABLEDICTIONARYADDITIONS_H
#define HAVE_CFMUTABLEDICTIONARYADDITIONS_H

void setObjectForKey(NSMutableDictionary *dict, const void *key, id value);
void setIntegerForKey(NSMutableDictionary *dict, const void *key, int value);
void setBooleanForKey(NSMutableDictionary *dict, const void *key, BOOL value);

#endif
