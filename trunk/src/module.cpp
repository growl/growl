//
//  $Id$
//
//  Copyright 2007 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to license.txt for details

#include "nsIGenericFactory.h"
#include "nsToolkitCompsCID.h"
#include "nsAlertsServiceMac.h"

NS_GENERIC_FACTORY_CONSTRUCTOR(nsAlertsServiceMac)

static nsModuleComponentInfo components[] =
{
  { "Alerts Service",
    NS_ALERTSSERVICE_CID,
    NS_ALERTSERVICE_CONTRACTID,
    nsAlertsServiceMacConstructor },
};

NS_IMPL_NSGETMODULE(GrowlNotifications, components)
