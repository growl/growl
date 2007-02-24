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
#include "nsIStreamLoader.h"
#include "nsIStreamListener.h"
#include "nsIIOService.h"
#include "nsIChannel.h"
#include "nsComponentManagerUtils.h"
#include "nsServiceManagerUtils.h"

#import "mozGrowlDelegate.h"
#import <Growl-WithInstaller/GrowlApplicationBridge.h>

NS_IMPL_THREADSAFE_ADDREF(nsAlertsServiceMac)
NS_IMPL_THREADSAFE_RELEASE(nsAlertsServiceMac)

NS_INTERFACE_MAP_BEGIN(nsAlertsServiceMac)
  NS_INTERFACE_MAP_ENTRY_AMBIGUOUS(nsISupports, nsIAlertsService)
  NS_INTERFACE_MAP_ENTRY(nsIAlertsService)
NS_INTERFACE_MAP_END_THREADSAFE

struct GrowlDelegateWrapper
{
  mozGrowlDelegate* delegate;

  GrowlDelegateWrapper()
  {
    delegate = [[mozGrowlDelegate alloc] init];

    [GrowlApplicationBridge setGrowlDelegate:delegate];
  
    NS_ASSERTION(delegate == [GrowlApplicationBridge growlDelegate],
                 "Growl Delegate was not registered properly.");
  }

  ~GrowlDelegateWrapper()
  {
    [delegate release];
  }
};

nsAlertsServiceMac::nsAlertsServiceMac()
{
  mDelegate = new GrowlDelegateWrapper();
}

nsAlertsServiceMac::~nsAlertsServiceMac()
{
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
  if (aAlertListener) {
    NS_ADDREF(aAlertListener);
    ind = [mDelegate->delegate addObserver: aAlertListener];
  }

  nsCOMPtr<nsAlertsImageLoadListener> listener =
    new nsAlertsImageLoadListener(aAlertTitle, aAlertText, aAlertClickable,
                                  aAlertCookie, ind);
  
  nsCOMPtr<nsIIOService> io;
  io = do_GetService("@mozilla.org/network/io-service;1", &rv);
  NS_ENSURE_SUCCESS(rv, rv);
  
  nsCOMPtr<nsIURI> uri;
  rv = io->NewURI(NS_ConvertUTF16toUTF8(aImageUrl), nsnull, nsnull,
                  getter_AddRefs(uri));
  NS_ENSURE_SUCCESS(rv, rv);

  nsCOMPtr<nsIChannel> chan;
  rv = io->NewChannelFromURI(uri, getter_AddRefs(chan));
  NS_ENSURE_SUCCESS(rv, rv);

  nsCOMPtr<nsIStreamLoader> loader;
  loader = do_CreateInstance("@mozilla.org/network/stream-loader;1", &rv);
  NS_ENSURE_SUCCESS(rv, rv);
  rv = loader->Init(chan, listener, nsnull);
  NS_ENSURE_SUCCESS(rv, rv);
  
  nsCOMPtr<nsIStreamListener> list = do_QueryInterface(loader, &rv);
  NS_ENSURE_SUCCESS(rv, rv);
 
  rv = chan->AsyncOpen(list, nsnull);
  NS_ENSURE_SUCCESS(rv, rv);
  
  return NS_OK;
}
