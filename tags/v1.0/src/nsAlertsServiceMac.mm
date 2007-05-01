//
//  $Id$
//
//  Copyright 2007 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to license.txt for details

#include "nsAlertsServiceMac.h"
#include "nsStringAPI.h"
#include "nsAlertsImageLoadListener.h"
#include "nsIURI.h"
#include "nsIStreamListener.h"
#include "nsIIOService.h"
#include "nsIChannel.h"
#include "nsComponentManagerUtils.h"
#include "nsServiceManagerUtils.h"
#include "localeKeys.h"

#import "wrapper.h"
#import "GrowlApplicationBridge.h"

NS_IMPL_THREADSAFE_ADDREF(nsAlertsServiceMac)
NS_IMPL_THREADSAFE_RELEASE(nsAlertsServiceMac)

NS_INTERFACE_MAP_BEGIN(nsAlertsServiceMac)
  NS_INTERFACE_MAP_ENTRY_AMBIGUOUS(nsISupports, nsIAlertsService)
  NS_INTERFACE_MAP_ENTRY(nsIAlertsService)
NS_INTERFACE_MAP_END_THREADSAFE

nsAlertsServiceMac::nsAlertsServiceMac()
{
  mDelegate = new GrowlDelegateWrapper();
}

nsAlertsServiceMac::~nsAlertsServiceMac()
{
  if (mDelegate)
    delete mDelegate;
}

NS_IMETHODIMP
nsAlertsServiceMac::ShowAlertNotification(const nsAString &aImageUrl,
                                          const nsAString &aAlertTitle,
                                          const nsAString &aAlertText,
                                          PRBool aAlertClickable,
                                          const nsAString &aAlertCookie,
                                          nsIObserver* aAlertListener)
{
  nsresult rv;

  PRUint32 ind = 0;
  if (aAlertListener)
    ind = [mDelegate->delegate addObserver: aAlertListener];

  nsCOMPtr<nsIStringBundleService> bundleService =
    do_GetService("@mozilla.org/intl/stringbundle;1", &rv);
  if (NS_FAILED(rv)) return rv;

  rv = bundleService->CreateBundle(GROWL_BUNDLE_LOCATION, getter_AddRefs(mBundle));
  if (NS_FAILED(rv)) return rv;

  nsString name;
  mBundle->GetStringFromName(GENERAL_TITLE, getter_Copies(name));

  nsCOMPtr<nsAlertsImageLoadListener> listener =
    new nsAlertsImageLoadListener(name, aAlertTitle, aAlertText, aAlertClickable,
                                  aAlertCookie, ind);

  nsCOMPtr<nsIIOService> io;
  io = do_GetService("@mozilla.org/network/io-service;1", &rv);
  NS_ENSURE_SUCCESS(rv, rv);

  nsCOMPtr<nsIURI> uri;
  rv = io->NewURI(NS_ConvertUTF16toUTF8(aImageUrl), nsnull, nsnull,
                  getter_AddRefs(uri));
  if (NS_FAILED(rv)) {
    // image uri failed to resolve, so dispatch to growl with no image
    [mozGrowlDelegate  name: name
                      title: aAlertTitle
                       text: aAlertText
                      image: [NSData data]
                        key: ind
                     cookie: aAlertCookie];

    return NS_OK;
  }

  nsCOMPtr<nsIChannel> chan;
  rv = io->NewChannelFromURI(uri, getter_AddRefs(chan));
  NS_ENSURE_SUCCESS(rv, rv);

  nsCOMPtr<nsIStreamLoader> loader;
  loader = do_CreateInstance("@mozilla.org/network/stream-loader;1", &rv);
  NS_ENSURE_SUCCESS(rv, rv);
  rv = loader->Init(chan, listener, nsnull);
  NS_ENSURE_SUCCESS(rv, rv);

  return NS_OK;
}
