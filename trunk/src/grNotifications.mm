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
#include "nsIStringBundle.h"
#include "nsAutoPtr.h"
#include "localeKeys.h"

#import "wrapper.h"

NSAutoreleasePool *gGrowlAutoreleasePool;

////////////////////////////////////////////////////////////////////////////////
//// grNotificationsList

class grNotificationsList : public grINotificationsList
{
public:
  NS_DECL_ISUPPORTS
  NS_DECL_GRINOTIFICATIONSLIST

  grNotificationsList();
  ~grNotificationsList();

  void informController(mozGrowlDelegate *cont);
private:
  NSMutableArray *mNames;
  NSMutableArray *mEnabled;
};

NS_IMPL_ADDREF(grNotificationsList)
NS_IMPL_RELEASE(grNotificationsList)

NS_INTERFACE_MAP_BEGIN(grNotificationsList)
  NS_INTERFACE_MAP_ENTRY_AMBIGUOUS(nsISupports, grINotificationsList)
  NS_INTERFACE_MAP_ENTRY(grINotificationsList)
NS_INTERFACE_MAP_END

grNotificationsList::grNotificationsList()
{
  mNames   = [[NSMutableArray arrayWithCapacity: 8] retain];
  mEnabled = [[NSMutableArray arrayWithCapacity: 8] retain];
}

grNotificationsList::~grNotificationsList()
{
  [mNames release];
  [mEnabled release];
}

void
grNotificationsList::informController(mozGrowlDelegate *delegate)
{
  [delegate addNotificationNames: mNames];

  [delegate addEnabledNotifications: mEnabled];
}

////////////////////////////////////////////////////////////////////////////////
//// grNotifications

NS_IMPL_THREADSAFE_ADDREF(grNotifications)
NS_IMPL_THREADSAFE_RELEASE(grNotifications)

NS_INTERFACE_MAP_BEGIN(grNotifications)
  NS_INTERFACE_MAP_ENTRY_AMBIGUOUS(nsISupports, grINotifications)
  NS_INTERFACE_MAP_ENTRY(nsIObserver)
  NS_INTERFACE_MAP_ENTRY(grINotifications)
NS_INTERFACE_MAP_END_THREADSAFE

grNotifications *grNotifications::gNotificationsService = nsnull;

grNotifications *
grNotifications::GetSingleton()
{
  if (gNotificationsService) {
    NS_ADDREF(gNotificationsService);
    return gNotificationsService;
  }

  gNotificationsService = new grNotifications();
  if (gNotificationsService) {
    NS_ADDREF(gNotificationsService);
    if (NS_FAILED(gNotificationsService->Init()))
      NS_RELEASE(gNotificationsService);
  }

  return gNotificationsService;
}

nsresult
grNotifications::Init()
{
  gGrowlAutoreleasePool = [[NSAutoreleasePool alloc] init];

  if ([GrowlApplicationBridge isGrowlInstalled] == YES)
    mDelegate = new GrowlDelegateWrapper();
  else
    return NS_ERROR_NOT_IMPLEMENTED;

  nsresult rv;
  nsCOMPtr<nsIObserverService> os =
    do_GetService("@mozilla.org/observer-service;1", &rv);
  NS_ENSURE_SUCCESS(rv, rv);

  os->AddObserver(this, "final-ui-startup", PR_FALSE);

  return NS_OK;
}

grNotifications::~grNotifications()
{
  if (mDelegate)
    delete mDelegate;

  [gGrowlAutoreleasePool release];
}

////////////////////////////////////////////////////////////////////////////////
//// nsIAlertsService

NS_IMETHODIMP
grNotifications::ShowAlertNotification(const nsAString &aImageUrl,
                                       const nsAString &aAlertTitle,
                                       const nsAString &aAlertText,
                                       PRBool aAlertClickable,
                                       const nsAString &aAlertCookie,
                                       nsIObserver* aAlertListener)
{
  nsresult rv;
  nsCOMPtr<nsIStringBundleService> bundleService =
    do_GetService("@mozilla.org/intl/stringbundle;1", &rv);

  nsString name = NS_LITERAL_STRING("General Notification");
  if (NS_SUCCEEDED(rv)) {
    nsCOMPtr<nsIStringBundle> bundle;
    rv = bundleService->CreateBundle(GROWL_BUNDLE_LOCATION,
                                     getter_AddRefs(bundle));

    if (NS_SUCCEEDED(rv)) {
      rv = bundle->GetStringFromName(GENERAL_TITLE, getter_Copies(name));

      if (NS_FAILED(rv))
        name = NS_LITERAL_STRING("General Notification");
    }
  }

  return SendNotification(name, aImageUrl, aAlertTitle, aAlertText,
                          aAlertCookie, aAlertListener);
}

////////////////////////////////////////////////////////////////////////////////
//// grINotifications

NS_IMETHODIMP
grNotifications::SendNotification(const nsAString &aName,
                                  const nsAString &aImage,
                                  const nsAString &aTitle,
                                  const nsAString &aMessage,
                                  const nsAString &aData,
                                  nsIObserver* aObserver)
{
  NS_ASSERTION(mDelegate->delegate == [GrowlApplicationBridge growlDelegate],
               "Growl Delegate was not registered properly.");

  PRUint32 ind = 0;
  if (aObserver)
    ind = [mDelegate->delegate addObserver: aObserver];

  nsresult rv;
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
                       cookie: aData];
    return NS_OK;
  }

  nsCOMPtr<nsIChannel> chan;
  rv = io->NewChannelFromURI(uri, getter_AddRefs(chan));
  NS_ENSURE_SUCCESS(rv, rv);

  nsCOMPtr<nsAlertsImageLoadListener> listener = nsnull;
  listener = new nsAlertsImageLoadListener(aName, aTitle, aMessage,
                                           aObserver ? PR_TRUE : PR_FALSE,
                                           nsString(), ind);
  if (!listener)
    return NS_ERROR_OUT_OF_MEMORY;

  nsCOMPtr<nsIStreamLoader> loader;
  loader = do_CreateInstance("@mozilla.org/network/stream-loader;1", &rv);
  NS_ENSURE_SUCCESS(rv, rv);
  rv = loader->Init(chan, listener, nsnull);
  NS_ENSURE_SUCCESS(rv, rv);

  return NS_OK;
}

NS_IMETHODIMP
grNotifications::MakeAppFocused()
{
  OSErr err;

  ProcessSerialNumber psn;
  err = ::GetCurrentProcess(&psn);
  if (err != 0) return NS_ERROR_FAILURE;

  err = ::SetFrontProcess(&psn);
  if (err != 0) return NS_ERROR_FAILURE;

  return NS_OK;
}

NS_IMETHODIMP
grNotifications::Observe(nsISupports *aSubject, const char *aTopic,
                         const PRUnichar *data)
{
  if (strcmp(aTopic, "final-ui-startup") == 0) {
    // get any extra notifications, then register with Growl
    nsRefPtr<grNotificationsList> notifications = new grNotificationsList();

    nsresult rv;
    nsCOMPtr<nsIObserverService> os =
      do_GetService("@mozilla.org/observer-service;1", &rv);
    NS_ENSURE_SUCCESS(rv, rv);

    os->NotifyObservers(notifications, "before-growl-registration", nsnull);

    notifications->informController(mDelegate->delegate);

    [GrowlApplicationBridge setGrowlDelegate: mDelegate->delegate];
  }

  return NS_OK;
}

////////////////////////////////////////////////////////////////////////////////
//// grINotifications

NS_IMETHODIMP
grNotificationsList::AddNotification(const nsAString &aName, PRBool aEnabled)
{
  NSString * name = [NSString stringWithCharacters: aName.BeginReading()
                                            length: aName.Length()];

  [mNames addObject: name];

  if (aEnabled)
    [mEnabled addObject: name];

  return NS_OK;
}

NS_IMETHODIMP
grNotificationsList::IsNotification(const nsAString &aName, PRBool *retVal)
{
  NSString * name = [NSString stringWithCharacters: aName.BeginReading()
                                            length: aName.Length()];

  if ([mNames containsObject: name])
    *retVal = PR_TRUE;
  else
    *retVal = PR_FALSE;

  return NS_OK;
}
