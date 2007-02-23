//
//  $Id$
//
//  Copyright 2007 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to license.txt for details

#include "nsAlertsImageLoadListener.h"

#ifdef DEBUG
#include "nsIRequest.h"
#include "nsIChannel.h"
#include "nsIURI.h"
#include "nsCOMPtr.h"
#endif

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
#ifdef DEBUG
  // print a load error on bad status
  nsCOMPtr<nsIRequest> request;
  aLoader->GetRequest(getter_AddRefs(request));
  nsCOMPtr<nsIChannel> channel = do_QueryInterface(request);

  if (NS_FAILED(aStatus)) {
    if (channel) {
      nsCOMPtr<nsIURI> uri;
      channel->GetURI(getter_AddRefs(uri));
      if (uri) {
        nsCAutoString uriSpec;
        uri->GetSpec(uriSpec);
        printf("Failed to load %s\n", uriSpec.get());
      }
    }
  }
#endif
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
