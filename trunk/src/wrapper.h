//
//  $Id$
//
//  Copyright 2007 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to license.txt for details

#import "mozGrowlDelegate.h"

struct GrowlDelegateWrapper
{
  mozGrowlDelegate* delegate;

  GrowlDelegateWrapper()
  {
    if ([GrowlApplicationBridge growlDelegate] == nil) {
      delegate = [[mozGrowlDelegate alloc] init];

      [GrowlApplicationBridge setGrowlDelegate:delegate];

      [GrowlApplicationBridge registerWithDictionary: nil];
    } else {
      delegate = [GrowlApplicationBridge growlDelegate];

      [delegate retain];
    }

    NS_ASSERTION(delegate == [GrowlApplicationBridge growlDelegate],
                 "Growl Delegate was not registered properly.");
  }

  ~GrowlDelegateWrapper()
  {
    [delegate release];
  }
};
