//
//  GrowlLog.h
//  Growl
//
//  Created by Ingmar Stein on 17.04.05.
//  Copyright 2004-2006 The Growl Project. All rights reserved.
//

#ifndef GROWL_LOG_H
#define GROWL_LOG_H

#include <CoreFoundation/CoreFoundation.h>
#include "CFGrowlAdditions.h"

void GrowlLog_log(STRING_TYPE message);
void GrowlLog_logNotificationDictionary(DICTIONARY_TYPE noteDict);
void GrowlLog_logRegistrationDictionary(DICTIONARY_TYPE regDict);

#endif
