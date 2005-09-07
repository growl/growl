//
//  SyncNotifier.h
//  HardwareGrowler
//
//  Created by Ingmar Stein on 03.09.05.
//  Copyright 2005 The Growl Project. All rights reserved.
//

#include <CoreFoundation/CoreFoundation.h>

struct SyncNotifierCallbacks {
	void (*syncStarted)(void);
	void (*syncFinished)(void);
};

void SyncNotifier_init(const struct SyncNotifierCallbacks *c);
void SyncNotifier_dealloc(void);
