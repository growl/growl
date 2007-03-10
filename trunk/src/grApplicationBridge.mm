//
//  $Id$
//
//  Copyright 2007 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to license.txt for details

#import <Growl/GrowlApplicationBridge.h>
#import "grApplicationBridge.h"

NS_IMPL_THREADSAFE_ADDREF(grApplicationBridge)
NS_IMPL_THREADSAFE_RELEASE(grApplicationBridge)

NS_INTERFACE_MAP_BEGIN(grApplicationBridge)
  NS_INTERFACE_MAP_ENTRY_AMBIGUOUS(nsISupports, grIApplicationBridge)
  NS_INTERFACE_MAP_ENTRY(grIApplicationBridge)
NS_INTERFACE_MAP_END_THREADSAFE

NS_IMETHODIMP
grApplicationBridge::GetGrowlInstalled(PRBool *aInstalled)
{
  *aInstalled = [GrowlApplicationBridge isGrowlInstalled] == YES ? PR_TRUE :
                                                                   PR_FALSE;
  return NS_OK;
}

NS_IMETHODIMP
grApplicationBridge::GetGrowlRunning(PRBool *aRunning)
{
  *aRunning = [GrowlApplicationBridge isGrowlRunning] == YES ? PR_TRUE :
                                                               PR_FALSE;
  return NS_OK;
}
