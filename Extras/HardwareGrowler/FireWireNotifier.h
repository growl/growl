/* FireWireNotifier */

#ifndef FIREWIRE_NOTIFIER_H
#define FIREWIRE_NOTIFIER_H

#include <CoreFoundation/CoreFoundation.h>

struct FireWireNotifierCallbacks {
	void (*didConnect)(CFStringRef deviceName);
	void (*didDisconnect)(CFStringRef deviceName);
};

void FireWireNotifier_init(const struct FireWireNotifierCallbacks *c);
void FireWireNotifier_dealloc(void);

#endif
