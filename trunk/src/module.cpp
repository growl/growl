//
//  $Id$
//
//  Copyright 2007 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to license.txt for details

#include "nsIGenericFactory.h"
#include "nsToolkitCompsCID.h"
#include "nsAlertsServiceMac.h"
#include "grApplicationBridge.h"
#include "grNotifications.h"

NS_GENERIC_FACTORY_CONSTRUCTOR(nsAlertsServiceMac)
NS_GENERIC_FACTORY_CONSTRUCTOR(grApplicationBridge)
NS_GENERIC_FACTORY_CONSTRUCTOR_INIT(grNotifications, Init)

static nsModuleComponentInfo components[] =
{
  { "Alerts Service",
    NS_ALERTSSERVICE_CID,
    NS_ALERTSERVICE_CONTRACTID,
    nsAlertsServiceMacConstructor },
  { "Growl Application Bridge",
    GROWL_APPLICATION_BRIDGE_CID,
    GROWL_APPLICATION_BRIDGE_CONTRACTID,
    grApplicationBridgeConstructor },
  { "Growl Notifications",
    GROWL_NOTIFICATIONS_CID,
    GROWL_NOTIFICATIONS_CONTRACTID,
    grNotificationsConstructor },
};

NS_IMPL_NSGETMODULE(GrowlNotifications, components)
