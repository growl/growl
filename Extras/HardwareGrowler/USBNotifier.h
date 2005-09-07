/* USBNotifier */

#include <CoreFoundation/CoreFoundation.h>

struct USBNotifierCallbacks {
	void (*didConnect)(CFStringRef deviceName);
	void (*didDisconnect)(CFStringRef deviceName);
};

void USBNotifier_init(const struct USBNotifierCallbacks *c);
void USBNotifier_dealloc(void);
