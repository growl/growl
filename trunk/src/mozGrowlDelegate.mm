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

  [super dealloc];
}

+ (void) title:(const nsAString&)aTitle
          text:(const nsAString&)aText
         image:(NSData*)aImage
           key:(PRUint32)aKey
        cookie:(const nsAString&)aCookie
{
  if (aKey) {
    [GrowlApplicationBridge
     notifyWithTitle: [NSString stringWithCharacters: aTitle.BeginReading()
                                              length: aTitle.Length()]
         description: [NSString stringWithCharacters: aText.BeginReading()
                                              length: aText.Length()]
    notificationName: NOTIFICATION_NAME
            iconData: aImage
            priority: 0
            isSticky: NO
        clickContext: [NSDictionary
  dictionaryWithObjectsAndKeys: [NSNumber numberWithUnsignedInt: aKey],
                                OBSERVER_KEY,
                                [NSArray arrayWithObject:
                                  [NSString stringWithCharacters: aCookie.BeginReading()
                                                          length: aCookie.Length()]],
                                COOKIE_KEY,
                                nil]];
  } else {
    // if we don't have an obsever (aKey is 0), do not send a click context
    [GrowlApplicationBridge
     notifyWithTitle: [NSString stringWithCharacters: aTitle.BeginReading()
                                              length: aTitle.Length()]
         description: [NSString stringWithCharacters: aText.BeginReading()
                                              length: aText.Length()]
    notificationName: NOTIFICATION_NAME
            iconData: aImage
            priority: 0
            isSticky: NO
        clickContext: nil];
  }
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

  nsIObserver* observer = NS_STATIC_CAST(nsIObserver*,
    [[mDict objectForKey: [clickContext valueForKey: OBSERVER_KEY]]
      pointerValue]);
  [mDict removeObjectForKey: [clickContext valueForKey: OBSERVER_KEY]];
  NSString* cookie = [[clickContext valueForKey: COOKIE_KEY] objectAtIndex: 0];

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

  nsIObserver* observer = NS_STATIC_CAST(nsIObserver*,
    [[mDict objectForKey: [clickContext valueForKey: OBSERVER_KEY]]
      pointerValue]);
  [mDict removeObjectForKey: [clickContext valueForKey: OBSERVER_KEY]];
  NSString* cookie = [[clickContext valueForKey: COOKIE_KEY] objectAtIndex: 0];

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
