//
//  $Id$
//
//  Copyright 2007 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to license.txt for details

#ifndef __nsAlertsServiceMac_H__
#define __nsAlertsServiceMac_H__

#include "xpcom-config.h"
#include "nsIAlertsService.h"
#include "nsCOMPtr.h"

#define NS_ALERTSSERVICE_CONTRACTID \
  "@mozilla.org/alerts-service;1"
#define NS_ALERTSSERVICE_CLASSNAME \
  "nsAlertsServiceMac"
#define NS_ALERTSSERVICE_CID \
{ 0xa0ccaaf8, 0x9da, 0x44d8, { 0xb2, 0x50, 0x9a, 0xc3, 0xe9, 0x3c, 0x81, 0x17 } }

struct GrowlDelegateWrapper;

class nsAlertsServiceMac : public nsIAlertsService
{
public:
  NS_DECL_ISUPPORTS
  NS_DECL_NSIALERTSSERVICE

  nsAlertsServiceMac();
private:
  GrowlDelegateWrapper* mDelegate;
  ~nsAlertsServiceMac();
};

#endif // __nsAlertsServiceMac_H__
