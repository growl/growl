//
//  $Id$
//
//  Copyright 2007 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to license.txt for details

#include "nsAlertsImageLoadListener.h"

NS_IMPL_ISUPPORTS1(nsAlertsImageLoadListener, nsIStreamLoaderObserver)

nsAlertsImageLoadListener::nsAlertsImageLoadListener(const nsAString &aAlertTitle,
                                                     const nsAString &aAlertText,
                                                     PRBool aAlertClickable,
                                                     const nsAString &aAlertCookie,
                                                     PRUint32 aAlertListenerKey) :
  mAlertTitle(aAlertTitle), mAlertText(aAlertText),
  mAlertClickable(aAlertClickable), mAlertCookie(aAlertCookie),
  mAlertListenerKey(aAlertListenerKey)
{
}

NS_IMETHODIMP
nsAlertsImageLoadListener::OnStreamComplete(nsIStreamLoader* aLoader,
                                            nsISupports* aContext,
                                            nsresult aStatus,
                                            PRUint32 aLength,
                                            const PRUint8* aResult)
{
  NSNumber* observer = [NSNumber numberWithUnsignedInt: mAlertListenerKey];
  NSArray* cookie    = [NSArray arrayWithObject:
                        [NSString stringWithCharacters: mAlertCookie.BeginReading()
                                                length: mAlertCookie.Length()]];
  if (mAlertListenerKey) {
    [GrowlApplicationBridge
     notifyWithTitle: [NSString stringWithCharacters: mAlertTitle.BeginReading()
                                              length: mAlertTitle.Length()]
         description: [NSString stringWithCharacters: mAlertText.BeginReading()
                                              length: mAlertText.Length()]
    notificationName: NOTIFICATION_NAME
            iconData: NS_FAILED(aStatus) ? [NSData data] :
                                           [NSData dataWithBytes: aResult
                                                          length: aLength]
            priority: 0
            isSticky: NO
        clickContext: [NSDictionary
                        dictionaryWithObjectsAndKeys: observer,
                                                      OBSERVER_KEY,
                                                      cookie,
                                                      COOKIE_KEY,
                                                      nil]];
  } else {
    // if we don't have an obsever (key is 0), do not send a click context
    [GrowlApplicationBridge
     notifyWithTitle: [NSString stringWithCharacters: mAlertTitle.BeginReading()
                                              length: mAlertTitle.Length()]
         description: [NSString stringWithCharacters: mAlertText.BeginReading()
                                              length: mAlertText.Length()]
    notificationName: NOTIFICATION_NAME
            iconData: NS_FAILED(aStatus) ? [NSData data] :
                                           [NSData dataWithBytes: aResult
                                                          length: aLength]
            priority: 0
            isSticky: NO
        clickContext: nil];
  }
  
  return NS_OK;
}
