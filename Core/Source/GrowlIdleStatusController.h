//
//  GrowlIdleStatusController.h
//  Growl
//
//  Created by Ingmar Stein on 17.06.05.
//  Copyright 2005-2006 The Growl Project. All rights reserved.
//

#ifndef GROWL_STATUS_CONTROLLER_H
#define GROWL_STATUS_CONTROLLER_H

#include <CoreFoundation/CoreFoundation.h>

//30 seconds of inactivity is considered idle
#define MACHINE_IDLE_THRESHOLD			30

void GrowlIdleStatusController_setThreshold(int idle);
void GrowlIdleStatusController_init(void);
Boolean GrowlIdleStatusController_isIdle(void);
void GrowlIdleStatusController_dealloc(void);

#endif
