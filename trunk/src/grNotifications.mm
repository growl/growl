//
//  $Id$
//
//  Copyright 2007 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to license.txt for details

#include "grNotifications.h"
#include "nsAlertsImageLoadListener.h"
#include "nsServiceManagerUtils.h"
#include "nsComponentManagerUtils.h"
#include "nsStringAPI.h"
#include "nsIURI.h"
#include "nsIStreamListener.h"
#include "nsIIOService.h"
#include "nsIChannel.h"
#include "nsIStringBundle.h"
#include "localeKeys.h"

#import "wrapper.h"

NS_IMPL_THREADSAFE_ADDREF(grNotifications)
NS_IMPL_THREADSAFE_RELEASE(grNotifications)

NS_INTERFACE_MAP_BEGIN(grNotifications)
  NS_INTERFACE_MAP_ENTRY_AMBIGUOUS(nsISupports, grINotifications)
  NS_INTERFACE_MAP_ENTRY(grINotifications)
NS_INTERFACE_MAP_END_THREADSAFE

nsresult
grNotifications::Init()
{
  if ([GrowlApplicationBridge isGrowlInstalled] == YES) {
    nsresult rv;

    mDelegate = new GrowlDelegateWrapper();

    nsCOMPtr<nsIStringBundleService> bundleService =
 	    do_GetService("@mozilla.org/intl/stringbundle;1", &rv);
 	  if (NS_FAILED(rv)) return rv;

    nsCOMPtr<nsIStringBundle> bundle;
 	  rv = bundleService->CreateBundle(GROWL_BUNDLE_LOCATION, getter_AddRefs(bundle));
 	  if (NS_FAILED(rv)) return rv;

    nsString text;
    bundle->GetStringFromName(GENERAL_TITLE, getter_Copies(text));
    [mDelegate->delegate addNotification: text];

    return NS_OK;
  } else {
    return NS_ERROR_NOT_IMPLEMENTED;
  }
}

grNotifications::~grNotifications()
{
  if (mDelegate)
    delete mDelegate;
}

NS_IMETHODIMP
grNotifications::AddNotification(const nsAString &aName)
{
  [mDelegate->delegate addNotification: aName];

  return NS_OK;
}

NS_IMETHODIMP
grNotifications::RegisterAppWithGrowl()
{
  [GrowlApplicationBridge registerWithDictionary: nil];

  return NS_OK;
}

NS_IMETHODIMP
grNotifications::SendNotification(const nsAString &aName,
                                  const nsAString &aImage,
                                  const nsAString &aTitle,
                                  const nsAString &aMessage,
                                  nsIObserver* aObserver)
{
  nsresult rv;
  nsCOMPtr<nsAlertsImageLoadListener> listener = nsnull;

  PRUint32 ind = 0;
  if (aObserver)
    ind = [mDelegate->delegate addObserver: aObserver];

  nsCOMPtr<nsIIOService> io;
  io = do_GetService("@mozilla.org/network/io-service;1", &rv);
  NS_ENSURE_SUCCESS(rv, rv);

  nsCOMPtr<nsIURI> uri;
  rv = io->NewURI(NS_ConvertUTF16toUTF8(aImage), nsnull, nsnull,
                  getter_AddRefs(uri));
  if (NS_FAILED(rv)) { // URI failed, dispatch with no image
    [mDelegate->delegate name: aName
                        title: aTitle
                         text: aMessage
                        image: [NSData data]
                          key: ind
                       cookie: nsString()];
    return NS_OK;
  }

  listener = new nsAlertsImageLoadListener(aName, aTitle, aMessage,
                                           aObserver ? PR_TRUE : PR_FALSE,
                                           nsString(), ind);

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
