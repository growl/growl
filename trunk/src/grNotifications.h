//
//  $Id$
//
//  Copyright 2007 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to license.txt for details

#ifndef grNotifications_h_
#define grNotifications_h_

#include "xpcom-config.h"
#include "grINotifications.h"
#include "nsIObserver.h"

#define GROWL_NOTIFICATIONS_CID \
  { 0xf2dea461, 0xbd96, 0x47d1, \
  { 0xa2, 0x3c, 0x50, 0x08, 0x3b, 0x19, 0xc6, 0xc2 } }

#define GROWL_NOTIFICATIONS_CONTRACTID \
  "@growl.info/notifications;1"

struct GrowlDelegateWrapper;

class grNotifications : public grINotifications,
                        public nsIObserver
{
public:
  NS_DECL_ISUPPORTS
  NS_DECL_GRINOTIFICATIONS
  NS_DECL_NSIOBSERVER

  grNotifications() : mDelegate(nsnull) { }
  nsresult Init();
protected:
  virtual ~grNotifications();
  GrowlDelegateWrapper *mDelegate;
};

#endif // grNotifications_h_
