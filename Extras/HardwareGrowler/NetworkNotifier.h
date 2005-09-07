//
//  NetworkNotifier.h
//  HardwareGrowler
//
//  Created by Ingmar Stein on 18.02.05.
//  Copyright 2005 The Growl Project. All rights reserved.
//

#include <CoreFoundation/CoreFoundation.h>

struct NetworkNotifierCallbacks {
	void (*linkUp)(CFStringRef description);
	void (*linkDown)(CFStringRef description);
	void (*ipAcquired)(CFStringRef ip);
	void (*ipReleased)(void);
	void (*airportConnect)(CFStringRef description);
	void (*airportDisconnect)(CFStringRef description);
};

void NetworkNotifier_init(const struct NetworkNotifierCallbacks *c);
void NetworkNotifier_dealloc(void);
