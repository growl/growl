/* BluetoothNotifier */

#ifndef BLUETOOTH_NOTIFIER_H
#define BLUETOOTH_NOTIFIER_H

#include <CoreFoundation/CoreFoundation.h>

struct BluetoothNotifierCallbacks {
	void (*didConnect)(CFStringRef device);
	void (*didDisconnect)(CFStringRef device);
};

void BluetoothNotifier_init(const struct BluetoothNotifierCallbacks *c);
void BluetoothNotifier_dealloc(void);

#endif
