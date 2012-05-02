/*
 *  PowerNotifier.h
 *  HardwareGrowler
 *
 *  Created by Evan Schoenberg on 3/27/06.
 *
 */

#ifndef POWER_NOTIFIER_H
#define POWER_NOTIFIER_H

typedef enum {
	HGUnknownPower = -1,
	HGACPower = 0,
	HGBatteryPower,
	HGUPSPower
} HGPowerSource;

void PowerNotifier_init(void);
void PowerNotifier_dealloc(void);

#endif
