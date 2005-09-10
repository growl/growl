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
	void (*airportConnect)(CFStringRef networkName, const unsigned char *bssidBytes);
	void (*airportDisconnect)(CFStringRef networkName);
};

void NetworkNotifier_init(const struct NetworkNotifierCallbacks *c);
void NetworkNotifier_dealloc(void);
