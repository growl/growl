//
//  $Id$
//
//  Copyright 2007 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to license.txt for details

#include "nsIGenericFactory.h"
#include "nsToolkitCompsCID.h"
#include "grApplicationBridge.h"
#include "grNotifications.h"
#include "nsICategoryManager.h"
#include "nsServiceManagerUtils.h"
#include "nsMemory.h"

NS_GENERIC_FACTORY_CONSTRUCTOR(grApplicationBridge)
NS_GENERIC_FACTORY_SINGLETON_CONSTRUCTOR(grNotifications,
                                         grNotifications::GetSingleton)

static
NS_METHOD
grNotificationsRegister(nsIComponentManager* aCompMgr,
                        nsIFile* aPath,
                        const char* registryLocation,
                        const char* componentType,
                        const nsModuleComponentInfo* info)
{
  nsresult rv;

  nsCOMPtr<nsICategoryManager> catman =
    do_GetService(NS_CATEGORYMANAGER_CONTRACTID, &rv);
  if (NS_FAILED(rv)) return rv;

  char* prev = nsnull;
  rv = catman->AddCategoryEntry("xpcom-startup", "grNotifications",
                                GROWL_NOTIFICATIONS_CONTRACTID, PR_TRUE,
                                PR_TRUE, &prev);
  if (prev)
    nsMemory::Free(prev);

  return rv;
}

static
NS_METHOD
grNotificationsUnregister(nsIComponentManager* aCompMgr,
                          nsIFile* aPath,
                          const char* registryLocation,
                          const nsModuleComponentInfo* info)
{
  nsresult rv;

  nsCOMPtr<nsICategoryManager> catman =
    do_GetService(NS_CATEGORYMANAGER_CONTRACTID, &rv);
  if (NS_FAILED(rv)) return rv;

  rv = catman->DeleteCategoryEntry("xpcom-startup", "grNotifications", PR_TRUE);

  return rv;
}

static nsModuleComponentInfo components[] =
{
  { "Alerts Service",
    NS_ALERTSSERVICE_CID,
    NS_ALERTSERVICE_CONTRACTID,
    grNotificationsConstructor },
  { "Growl Application Bridge",
    GROWL_APPLICATION_BRIDGE_CID,
    GROWL_APPLICATION_BRIDGE_CONTRACTID,
    grApplicationBridgeConstructor },
  { "Growl Notifications",
    GROWL_NOTIFICATIONS_CID,
    GROWL_NOTIFICATIONS_CONTRACTID,
    grNotificationsConstructor,
    grNotificationsRegister,
    grNotificationsUnregister },
};

NS_IMPL_NSGETMODULE(GrowlNotifications, components)
