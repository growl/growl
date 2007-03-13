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
#include "nsCRT.h"
#include "nsStringAPI.h"
#include "nsIDownload.h"
#include "nsIURI.h"
#include "nsIStreamListener.h"
#include "nsIIOService.h"
#include "nsIChannel.h"

#include "localeKeys.h"
#import "wrapper.h"

#define DOWNLOAD_START_IMAGE \
  NS_LITERAL_STRING("chrome://growl/content/downloadIcon.png")
#define DOWNLOAD_FINISHED_IMAGE \
  NS_LITERAL_STRING("chrome://growl/content/downloadIcon.png")
#define DOWNLOAD_CANCELED_IMAGE \
  NS_LITERAL_STRING("chrome://growl/content/downloadIcon.png")
#define DOWNLOAD_FAILED_IMAGE \
  NS_LITERAL_STRING("chrome://growl/content/downloadIcon.png")

NS_IMPL_THREADSAFE_ISUPPORTS2(grBrowserNotifications, grIBrowserNotifications,
                              nsIObserver)

grBrowserNotifications::grBrowserNotifications() : mObserverService(nsnull)
{
  mDelegate = new GrowlDelegateWrapper();
}

nsresult
grBrowserNotifications::Init()
{
  nsresult rv;

  mObserverService = do_GetService("@mozilla.org/observer-service;1", &rv);
  if (NS_FAILED(rv)) return rv;

  nsCOMPtr<nsIStringBundleService> bundleService =
    do_GetService("@mozilla.org/intl/stringbundle;1", &rv);
  if (NS_FAILED(rv)) return rv;

  rv = bundleService->CreateBundle(GROWL_BUNDLE_LOCATION, getter_AddRefs(mBundle));
  if (NS_FAILED(rv)) return rv;

  mObserverService->AddObserver(this, GROWL_DOWNLOAD_STARTED_KEY, PR_FALSE);
  mObserverService->AddObserver(this, GROWL_DOWNLOAD_FINISHED_KEY, PR_FALSE);
  mObserverService->AddObserver(this, GROWL_DOWNLOAD_CANCELED_KEY, PR_FALSE);
  mObserverService->AddObserver(this, GROWL_DOWNLOAD_FAILED_KEY, PR_FALSE);

  return NS_OK;
}

grBrowserNotifications::~grBrowserNotifications()
{
  if (mObserverService) {
    mObserverService->RemoveObserver(this, GROWL_DOWNLOAD_STARTED_KEY);
    mObserverService->RemoveObserver(this, GROWL_DOWNLOAD_FINISHED_KEY);
    mObserverService->RemoveObserver(this, GROWL_DOWNLOAD_CANCELED_KEY);
    mObserverService->RemoveObserver(this, GROWL_DOWNLOAD_FAILED_KEY);
  }

  if (mDelegate)
    delete mDelegate;
}

NS_IMETHODIMP
grBrowserNotifications::Observe(nsISupports *aSubject, const char *aTopic,
                                const PRUnichar *aData)
{
  nsresult rv;
  nsCOMPtr<nsAlertsImageLoadListener> listener = nsnull;

  nsString title, message, image;

  if (nsCRT::strcmp(aTopic, GROWL_DOWNLOAD_STARTED_KEY) == 0) {
    // The download has started
    mBundle->GetStringFromName(DOWNLOAD_START_TITLE, getter_Copies(title));
    nsCOMPtr<nsIDownload> download = do_QueryInterface(aSubject);
    download->GetDisplayName(getter_Copies(message));
    image = DOWNLOAD_START_IMAGE;

  } else if (nsCRT::strcmp(aTopic, GROWL_DOWNLOAD_FINISHED_KEY) == 0) {
    // The download has finished
    mBundle->GetStringFromName(DOWNLOAD_FINISHED_TITLE, getter_Copies(title));
    nsCOMPtr<nsIDownload> download = do_QueryInterface(aSubject);
    download->GetDisplayName(getter_Copies(message));
    image = DOWNLOAD_FINISHED_IMAGE;

  } else if (nsCRT::strcmp(aTopic, GROWL_DOWNLOAD_CANCELED_KEY) == 0) {
    // The download was canceled
    mBundle->GetStringFromName(DOWNLOAD_CANCELED_TITLE, getter_Copies(title));
    nsCOMPtr<nsIDownload> download = do_QueryInterface(aSubject);
    download->GetDisplayName(getter_Copies(message));
    image = DOWNLOAD_CANCELED_IMAGE;

  } else if (nsCRT::strcmp(aTopic, GROWL_DOWNLOAD_FAILED_KEY) == 0) {
    // The download failed
    mBundle->GetStringFromName(DOWNLOAD_FAILED_TITLE, getter_Copies(title));
    nsCOMPtr<nsIDownload> download = do_QueryInterface(aSubject);
    download->GetDisplayName(getter_Copies(message));
    image = DOWNLOAD_FAILED_IMAGE;
  }

  // TODO: observers for clickback
  listener = new nsAlertsImageLoadListener(title, title, message, PR_FALSE, nsString(), PRUint32(0));
  nsCOMPtr<nsIIOService> io;
  io = do_GetService("@mozilla.org/network/io-service;1", &rv);
  NS_ENSURE_SUCCESS(rv, rv);

  nsCOMPtr<nsIURI> uri;
  rv = io->NewURI(NS_ConvertUTF16toUTF8(image), nsnull, nsnull,
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

  return NS_OK;
}
