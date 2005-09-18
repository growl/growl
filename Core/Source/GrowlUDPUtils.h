//
//  GrowlUDPUtils.h
//  Growl
//
//  Created by Ingmar Stein on 20.11.04.
//  Copyright 2004-2005 The Growl Project. All rights reserved.
//

#ifndef GROWL_UDP_UTILS_H
#define GROWL_UDP_UTILS_H

#include <CoreFoundation/CoreFoundation.h>
#include <Security/Security.h>

#ifdef __OBJC__
#	define DICTIONARY_TYPE NSDictionary *
#else
#	define DICTIONARY_TYPE CFDictionaryRef
#endif

enum GrowlAuthenticationMethod {
	GROWL_AUTH_NONE,
	GROWL_AUTH_MD5,
	GROWL_AUTH_SHA256
};

unsigned char *GrowlUDPUtils_registrationToPacket(DICTIONARY_TYPE aNotification, enum GrowlAuthenticationMethod authMethod, const char *password, unsigned *packetSize);
unsigned char *GrowlUDPUtils_notificationToPacket(DICTIONARY_TYPE aNotification, enum GrowlAuthenticationMethod authMethod, const char *password, unsigned *packetSize);
void GrowlUDPUtils_cryptPacket(CSSM_DATA_PTR packet, CSSM_ALGORITHMS algorithm, CSSM_DATA_PTR password, Boolean doEncrypt);

#endif
