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
#include "nsCOMPtr.h"
#include "nsServiceManagerUtils.h"
#include "nsIXULAppInfo.h"

@implementation mozGrowlDelegate

- (id) init
{
  if ((self = [super init])) {
    mKey = 0;
    mDict = [[NSMutableDictionary dictionaryWithCapacity: 8] retain];

    mNotifications = [[NSMutableArray arrayWithCapacity: 8] retain];
  }

  return self;
}

- (void) dealloc
{
  [mDict release];

  [mNotifications release];

  [super dealloc];
}

+ (void)  name:(const nsAString&)aName
         title:(const nsAString&)aTitle
          text:(const nsAString&)aText
         image:(NSData*)aImage
           key:(PRUint32)aKey
        cookie:(const nsAString&)aCookie
{
  NSDictionary* clickContext = nil;
  if (aKey)
    clickContext = [NSDictionary dictionaryWithObjectsAndKeys:
      [NSNumber numberWithUnsignedInt: aKey],
      OBSERVER_KEY,
      [NSArray arrayWithObject:
        [NSString stringWithCharacters: aCookie.BeginReading()
                                length: aCookie.Length()]],
      COOKIE_KEY,
      nil];

  [GrowlApplicationBridge
     notifyWithTitle: [NSString stringWithCharacters: aTitle.BeginReading()
                                              length: aTitle.Length()]
         description: [NSString stringWithCharacters: aText.BeginReading()
                                              length: aText.Length()]
    notificationName: [NSString stringWithCharacters: aName.BeginReading()
                                              length: aName.Length()]
            iconData: aImage
            priority: 0
            isSticky: NO
        clickContext: clickContext];
}

- (void)addNotification:(const nsAString&)aName
{
  [mNotifications addObject: [NSString stringWithCharacters: aName.BeginReading()
                                                     length: aName.Length()]];
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
           mNotifications, GROWL_NOTIFICATIONS_ALL,
           mNotifications, GROWL_NOTIFICATIONS_DEFAULT,
           nil];
}

- (NSString*) applicationNameForGrowl
{
  nsresult rv;

  nsCOMPtr<nsIXULAppInfo> appInfo =
    do_GetService("@mozilla.org/xre/app-info;1", &rv);
  if (NS_FAILED(rv)) return nil;

  nsCString appName;
  rv = appInfo->GetName(appName);
  if (NS_FAILED(rv)) return nil;

  nsString name = NS_ConvertUTF8toUTF16(appName);
  return [NSString stringWithCharacters: name.BeginReading()
                                 length: name.Length()];
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
