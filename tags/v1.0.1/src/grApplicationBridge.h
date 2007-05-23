//
//  $Id$
//
//  Copyright 2007 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to license.txt for details

#ifndef grApplicationBridge_h_
#define grApplicationBridge_h_

#include "grIApplicationBridge.h"
#include "xpcom-config.h"

#define GROWL_APPLICATION_BRIDGE_CID \
  { 0x45f13a35, 0x93f7, 0x4d72, \
  { 0x84, 0x47, 0x75, 0xcf, 0xa4, 0x3b, 0x2c, 0x9c } }

#define GROWL_APPLICATION_BRIDGE_CONTRACTID \
  "@growl.info/application-bridge;1"

class grApplicationBridge : public grIApplicationBridge
{
public:
  NS_DECL_ISUPPORTS
  NS_DECL_GRIAPPLICATIONBRIDGE
};

#endif // grApplicationBridge_h_
