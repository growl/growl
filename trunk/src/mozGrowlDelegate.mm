//
//  $Id$
//
//  Copyright 2007 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to license.txt for details

#import "mozGrowlDelegate.h"

#include "nsIObserver.h"
#include "nsStringAPI.h"
#include "nscore.h"

@implementation mozGrowlDelegate

- (id) init
{
  if ((self = [super init])) {
    mKey = 0;
    mDict = [[NSMutableDictionary dictionaryWithCapacity:8] retain];
  }

  return self;
}

- (void) dealloc
{
  [mDict release];
}

- (PRUint32) addObserver:(nsIObserver*)aObserver
{
  mKey++;
  [mDict setObject: [NSValue valueWithPointer: aObserver]
            forKey: [NSNumber numberWithUnsignedInt: mKey]];
  return mKey;
}

- (NSDictionary *) registrationDictionaryForGrowl
{
  return [NSDictionary dictionaryWithObjectsAndKeys:
           [NSArray arrayWithObjects: NOTIFICATION_NAME, nil],
           GROWL_NOTIFICATIONS_ALL,
           [NSArray arrayWithObjects: NOTIFICATION_NAME, nil],
           GROWL_NOTIFICATIONS_DEFAULT,
           nil];
}


- (void) growlNotificationTimedOut:(id)clickContext
{
  NS_ASSERTION([clickContext valueForKey: OBSERVER_KEY] != nil,
               "OBSERVER_KEY not found!");
  NS_ASSERTION([clickContext valueForKey: COOKIE_KEY] != nil,
               "COOKIE_KEY not found!");
  
  nsIObserver* observer =
    NS_STATIC_CAST(nsIObserver*,
      [[mDict objectForKey: [clickContext valueForKey: OBSERVER_KEY]]
        pointerValue]);
  [mDict removeObjectForKey: [clickContext valueForKey: OBSERVER_KEY]];
  NSString* cookie      = [[clickContext valueForKey: COOKIE_KEY]
                             objectAtIndex: 0];
  if (observer) {
    nsString tmp;
    tmp.SetLength([cookie length]);
    [cookie getCharacters:tmp.BeginWriting()];
    observer->Observe(nsnull, "alertfinished", tmp.get());
    NS_RELEASE(observer);
  }
}

- (void) growlNotificationWasClicked:(id)clickContext
{
  NS_ASSERTION([clickContext valueForKey: OBSERVER_KEY] != nil,
               "OBSERVER_KEY not found!");
  NS_ASSERTION([clickContext valueForKey: COOKIE_KEY] != nil,
               "COOKIE_KEY not found!");
  
  nsIObserver* observer =
    NS_STATIC_CAST(nsIObserver*,
      [[mDict objectForKey: [clickContext valueForKey: OBSERVER_KEY]]
        pointerValue]);
  [mDict removeObjectForKey: [clickContext valueForKey: OBSERVER_KEY]];
  NSString* cookie      = [[clickContext valueForKey: COOKIE_KEY]
                             objectAtIndex: 0];
  if (observer) {
    nsString tmp;
    tmp.SetLength([cookie length]);
    [cookie getCharacters:tmp.BeginWriting()];
    observer->Observe(nsnull, "alertclickcallback", tmp.get());
    observer->Observe(nsnull, "alertfinished", tmp.get());
    NS_RELEASE(observer);
  }
}

@end
