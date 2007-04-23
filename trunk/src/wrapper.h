//
//  $Id$
//
//  Copyright 2007 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to license.txt for details

#import "mozGrowlDelegate.h"
#include "nsStringAPI.h"

struct GrowlDelegateWrapper
{
  mozGrowlDelegate* delegate;

  GrowlDelegateWrapper()
  {
    if ([GrowlApplicationBridge growlDelegate] == nil) {
      delegate = [[mozGrowlDelegate alloc] init];

      //[GrowlApplicationBridge setGrowlDelegate:delegate];
    } else {
      delegate = (mozGrowlDelegate*)[GrowlApplicationBridge growlDelegate];

      [delegate retain];
    }
  }

  ~GrowlDelegateWrapper()
  {
    [delegate release];
  }
};
