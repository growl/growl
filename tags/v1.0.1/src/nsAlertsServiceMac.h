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
#include "nsIStringBundle.h"

struct GrowlDelegateWrapper;

class nsAlertsServiceMac : public nsIAlertsService
{
public:
  NS_DECL_ISUPPORTS
  NS_DECL_NSIALERTSSERVICE

  nsAlertsServiceMac();
private:
  GrowlDelegateWrapper* mDelegate;
  virtual ~nsAlertsServiceMac();
};

#endif // __nsAlertsServiceMac_H__
