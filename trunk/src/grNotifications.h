//
//  $Id$
//
//  Copyright 2007 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to license.txt for details

#ifndef grNotifications_h_
#define grNotifications_h_

#include "grINotifications.h"
#include "nsIObserver.h"
#include "nsIObserverService.h"
#include "nsCOMPtr.h"
#include "nsIStringBundle.h"
#include "xpcom-config.h"

#define GROWL_BROWSER_NOTIFICATIONS_CID \
  { 0x4d19794c, 0x982c, 0x4259, \
  { 0x8d, 0xa4, 0x41, 0x3f, 0x5c, 0x2c, 0x4f, 0x6b } }

#define GROWL_MAIL_NOTIFICATIONS_CID \
  { 0xfae8a6b9, 0x98b8, 0x45d9, \
  { 0xa8, 0xc8, 0xd0, 0x04, 0x66, 0xa5, 0xf7, 0x56 } }

#define GROWL_NOTIFICATIONS_CONTRACTID \
  "@growl.info/notifications;1"

#define GROWL_DOWNLOAD_STARTED_KEY  "dl-start"
#define GROWL_DOWNLOAD_FINISHED_KEY "dl-done"
#define GROWL_DOWNLOAD_CANCELED_KEY "dl-cancel"
#define GROWL_DOWNLOAD_FAILED_KEY   "dl-failed"

struct GrowlDelegateWrapper;

class grBrowserNotifications : public grIBrowserNotifications,
                               public nsIObserver
{
public:
  NS_DECL_ISUPPORTS
  NS_DECL_GRIBROWSERNOTIFICATIONS
  NS_DECL_NSIOBSERVER

  grBrowserNotifications();
  nsresult Init();
protected:
  virtual ~grBrowserNotifications();
  nsCOMPtr<nsIObserverService> mObserverService;
  nsCOMPtr<nsIStringBundle> mBundle;
  GrowlDelegateWrapper* mDelegate;
};

class grMailNotifications : public grIMailNotifications
{
public:
  NS_DECL_ISUPPORTS
  NS_DECL_GRIMAILNOTIFICATIONS
};

#endif // grNotifications_h_
