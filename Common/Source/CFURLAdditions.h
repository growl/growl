//
//  CFURLAdditions.h
//  Growl
//
//  Created by Karl Adam on Fri May 28 2004.
//  Copyright 2004-2006 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to License.txt for details

#ifndef HAVE_CFURLADDITIONS_H
#define HAVE_CFURLADDITIONS_H

#include <CoreFoundation/CoreFoundation.h>

//'alias' as in the Alias Manager.
NSURL *createFileURLWithAliasData(NSData *aliasData);
NSData *createAliasDataWithURL(NSURL *theURL);

//these are the type of external representations used by Dock.app.
NSURL *createFileURLWithDockDescription(NSDictionary *dict);
//createDockDescriptionWithURL returns NULL for non-file: URLs.
NSDictionary *createDockDescriptionWithURL(NSURL *theURL);

#endif
