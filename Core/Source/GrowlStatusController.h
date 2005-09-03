//
//  GrowlStatusController.h
//  Growl
//
//  Created by Ingmar Stein on 17.06.05.
//  Copyright 2005 The Growl Project. All rights reserved.
//

#ifndef GROWL_STATUS_CONTROLLER_H
#define GROWL_STATUS_CONTROLLER_H

#include <Carbon/Carbon.h>

__BEGIN_DECLS

void GrowlStatusController_init(void);
Boolean GrowlStatusController_isIdle(void);
void GrowlStatusController_dealloc(void);

__END_DECLS

#endif
