//
//  $Id$
//
//  Copyright 2007 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to license.txt for details

#include "nsAlertsImageLoadListener.h"
#include "localeKeys.h"
#import "GrowlApplicationBridge.h"
#import "mozGrowlDelegate.h"

NS_IMPL_ISUPPORTS1(nsAlertsImageLoadListener, nsIStreamLoaderObserver)

nsAlertsImageLoadListener::nsAlertsImageLoadListener(const nsAString &aName,
                                                     const nsAString &aAlertTitle,
                                                     const nsAString &aAlertText,
                                                     PRBool aAlertClickable,
                                                     const nsAString &aAlertCookie,
                                                     PRUint32 aAlertListenerKey) :
  mName(aName), mAlertTitle(aAlertTitle), mAlertText(aAlertText),
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
  [mozGrowlDelegate  name: mName
                    title: mAlertTitle
                     text: mAlertText
                    image: NS_FAILED(aStatus) ? [NSData data] :
                                                [NSData dataWithBytes: aResult
                                                               length: aLength]
                      key: mAlertListenerKey
                   cookie: mAlertCookie];

  return NS_OK;
}
