//
//  $Id$
//
//  Copyright 2007 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to license.txt for details

#ifndef grMailNotifications_h_
#define grMailNotifications_h_

#include "grNotifications.h"
#include "nsIObserver.h"
#include "nsIObserverService.h"
#include "nsCOMPtr.h"
#include "nsIStringBundle.h"

#define GROWL_MAIL_NOTIFICATIONS_CID \
  { 0xfae8a6b9, 0x98b8, 0x45d9, \
  { 0xa8, 0xc8, 0xd0, 0x04, 0x66, 0xa5, 0xf7, 0x56 } }

class grMailNotifications : public grIMailNotifications
{
public:
  NS_DECL_ISUPPORTS
  NS_DECL_GRIMAILNOTIFICATIONS
private:
  virtual ~grMailNotifications();
  nsCOMPtr<nsIStringBundle> mBundle;
  GrowlDelegateWrapper* mDelegate;
};

#endif // grMailNotifications_h_
