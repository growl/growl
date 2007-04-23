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
#include "nsIObserverService.h"
#include "nsCRT.h"

#import "wrapper.h"

NS_IMPL_THREADSAFE_ADDREF(grNotifications)
NS_IMPL_THREADSAFE_RELEASE(grNotifications)

NS_INTERFACE_MAP_BEGIN(grNotifications)
  NS_INTERFACE_MAP_ENTRY_AMBIGUOUS(nsISupports, grINotifications)
  NS_INTERFACE_MAP_ENTRY(nsIObserver)
  NS_INTERFACE_MAP_ENTRY(grINotifications)
NS_INTERFACE_MAP_END_THREADSAFE

nsresult
grNotifications::Init()
{
  if ([GrowlApplicationBridge isGrowlInstalled] == YES) {
    mDelegate = new GrowlDelegateWrapper();

  } else {
    return NS_ERROR_NOT_IMPLEMENTED;
  }

  nsresult rv;
  nsCOMPtr<nsIObserverService> os =
    do_GetService("@mozilla.org/observer-service;1", &rv);
  if (NS_FAILED(rv)) return rv;

  os->AddObserver(this, "growl-Wait for me to register", PR_FALSE);
  os->AddObserver(this, "growl-I'm done registering", PR_FALSE);
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

NS_IMETHODIMP
grNotifications::Observe(nsISupports *aSubject, const char *aTopic,
                         const PRUnichar *data)
{
#ifdef DEBUG
  printf("\nI'm observering this:%s\n\n", aTopic);
#endif
  if (nsCRT::strcmp(aTopic, "growl-Wait for me to register") == 0) {
    mCount++;
#ifdef DEBUG
    printf("\n*** %s, mCount=%d\n", aTopic, mCount);
#endif
  } else if (nsCRT::strcmp(aTopic, "growl-I'm done registering") == 0) {
    mCount--;
#ifdef DEBUG
    printf("\n*** %s, mCount=%d\n", aTopic, mCount);
#endif

    if (mCount == 0) { // Time to register with growl
      [GrowlApplicationBridge setGrowlDelegate: mDelegate->delegate];
    }
  }

  return NS_OK;
}
