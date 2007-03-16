//
//  $Id$
//
//  Copyright 2007 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to license.txt for details

#ifndef grBrowserNotifications_h_
#define grBrowserNotifications_h_

#include "grINotifications.h"
#include "nsIObserver.h"
#include "nsIObserverService.h"
#include "nsCOMPtr.h"
#include "nsIStringBundle.h"

#define GROWL_BROWSER_NOTIFICATIONS_CID \
  { 0x4d19794c, 0x982c, 0x4259, \
  { 0x8d, 0xa4, 0x41, 0x3f, 0x5c, 0x2c, 0x4f, 0x6b } }

#define GROWL_DOWNLOAD_STARTED_KEY  "dl-start"
#define GROWL_DOWNLOAD_FINISHED_KEY "dl-done"
#define GROWL_DOWNLOAD_CANCELED_KEY "dl-cancel"
#define GROWL_DOWNLOAD_FAILED_KEY   "dl-failed"

#define DOWNLOAD_START_IMAGE \
  NS_LITERAL_STRING("chrome://growl/content/downloadIcon.png")
#define DOWNLOAD_FINISHED_IMAGE \
  NS_LITERAL_STRING("chrome://growl/content/downloadIcon.png")
#define DOWNLOAD_CANCELED_IMAGE \
  NS_LITERAL_STRING("chrome://growl/content/downloadIcon.png")
#define DOWNLOAD_FAILED_IMAGE \
  NS_LITERAL_STRING("chrome://growl/content/downloadIcon.png")

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

#endif // grBrowserNotifications_h_
