//
//  GrowlUDPUtils.m
//  Growl
//
//  Created by Ingmar Stein on 20.11.04.
//  Copyright 2004-2006 The Growl Project. All rights reserved.
//

#include "GrowlUDPUtils.h"
#include "GrowlDefines.h"
#include "GrowlDefinesInternal.h"
#include "CFGrowlAdditions.h"
#include "sha2.h"
#include "cdsa.h"

//see GrowlApplicationBridge-Carbon.c for rationale of using NSLog.
extern void NSLog(CFStringRef format, ...);

static void addChecksumToPacket(CSSM_DATA_PTR packet, enum GrowlAuthenticationMethod authMethod, const CSSM_DATA_PTR password) {
	unsigned       messageLength;
	CSSM_DATA      digestData;
	CSSM_CC_HANDLE ccHandle;
	CSSM_DATA      inData;
	CSSM_RETURN    crtn;

	switch (authMethod) {
		default:
		case GROWL_AUTH_MD5:
			crtn = CSSM_CSP_CreateDigestContext(cspHandle, CSSM_ALGID_MD5, &ccHandle);
			if (crtn)
				cssmPerror("CSSM_CSP_CreateDigestContext", crtn);
			crtn = CSSM_DigestDataInit(ccHandle);
			if (crtn)
				cssmPerror("CSSM_DigestDataInit", crtn);
			messageLength = packet->Length - MD5_DIGEST_LENGTH;
			inData.Data = packet->Data;
			inData.Length = messageLength;
			crtn = CSSM_DigestDataUpdate(ccHandle, &inData, 1U);
			if (crtn)
				cssmPerror("CSSM_DigestDataUpdate", crtn);
			if (password->Data && password->Length) {
				crtn = CSSM_DigestDataUpdate(ccHandle, password, 1U);
				if (crtn)
					cssmPerror("CSSM_DigestDataUpdate", crtn);
			}
			digestData.Data = packet->Data + messageLength;
			digestData.Length = MD5_DIGEST_LENGTH;
			crtn = CSSM_DigestDataFinal(ccHandle, &digestData);
			CSSM_DeleteContext(ccHandle);
			if (crtn)
				cssmPerror("CSSM_DigestDataFinal", crtn);
			break;
		case GROWL_AUTH_SHA256: {
#if MAC_OS_X_VERSION_MIN_REQUIRED >= MAC_OS_X_VERSION_10_4
			crtn = CSSM_CSP_CreateDigestContext(cspHandle, CSSM_ALGID_SHA256, &ccHandle);
			if (crtn)
				cssmPerror("CSSM_CSP_CreateDigestContext", crtn);
			crtn = CSSM_DigestDataInit(ccHandle);
			if (crtn)
				cssmPerror("CSSM_DigestDataInit", crtn);
			messageLength = packet->Length - SHA256_DIGEST_LENGTH;
			inData.Data = packet->Data;
			inData.Length = messageLength;
			crtn = CSSM_DigestDataUpdate(ccHandle, &inData, 1U);
			if (crtn)
				cssmPerror("CSSM_DigestDataUpdate", crtn);
			if (password->Data && password->Length) {
				crtn = CSSM_DigestDataUpdate(ccHandle, password, 1U);
				if (crtn)
					cssmPerror("CSSM_DigestDataUpdate", crtn);
			}
			digestData.Data = packet->Data + messageLength;
			digestData.Length = SHA256_DIGEST_LENGTH;
			crtn = CSSM_DigestDataFinal(ccHandle, &digestData);
			CSSM_DeleteContext(ccHandle);
			if (crtn)
				cssmPerror("CSSM_DigestDataFinal", crtn);
#else
			SHA_CTX sha_ctx;
			messageLength = packet->Length-SHA256_DIGEST_LENGTH;
			SHA256_Init(&sha_ctx);
			SHA256_Update(&sha_ctx, packet->Data, messageLength);
			if (password->Data && password->Length)
				SHA256_Update(&sha_ctx, password->Data, password->Length);
			SHA256_Final(packet->Data + messageLength, &sha_ctx);
#endif
			break;
		}
		case GROWL_AUTH_NONE:
			break;
	}
}

unsigned char *GrowlUDPUtils_notificationToPacket(CFDictionaryRef aNotification, enum GrowlAuthenticationMethod authMethod, const char *password, unsigned *packetSize) {
	struct GrowlNetworkNotification *nn;
	unsigned char  *data;
	size_t         length;
	unsigned short notificationNameLen;
	unsigned short applicationNameLen;
	unsigned short titleLen;
	unsigned short descriptionLen;
	char           *notificationName;
	char           *applicationName;
	char           *title;
	char           *description;
	unsigned       digestLength;
	CSSM_DATA      packetData;
	CSSM_DATA      passwordData;
	CFNumberRef    priority;
	CFBooleanRef   isSticky;

	notificationName    = copyCString(CFDictionaryGetValue(aNotification, GROWL_NOTIFICATION_NAME), kCFStringEncodingUTF8);
	applicationName     = copyCString(CFDictionaryGetValue(aNotification, GROWL_APP_NAME), kCFStringEncodingUTF8);
	title               = copyCString(CFDictionaryGetValue(aNotification, GROWL_NOTIFICATION_TITLE), kCFStringEncodingUTF8);
	description         = copyCString(CFDictionaryGetValue(aNotification, GROWL_NOTIFICATION_DESCRIPTION), kCFStringEncodingUTF8);
	notificationNameLen = strlen(notificationName);
	applicationNameLen  = strlen(applicationName);
	titleLen            = strlen(title);
	descriptionLen      = strlen(description);

	priority = CFDictionaryGetValue(aNotification, GROWL_NOTIFICATION_PRIORITY);
	isSticky = CFDictionaryGetValue(aNotification, GROWL_NOTIFICATION_STICKY);

	switch (authMethod) {
		case GROWL_AUTH_NONE:
			digestLength = 0U;
			break;
		default:
		case GROWL_AUTH_MD5:
			digestLength = MD5_DIGEST_LENGTH;
			break;
		case GROWL_AUTH_SHA256:
			digestLength = SHA256_DIGEST_LENGTH;
			break;
	}
	length = sizeof(*nn) + notificationNameLen + applicationNameLen + titleLen + descriptionLen + digestLength;

	nn = (struct GrowlNetworkNotification *)malloc(length);
	nn->common.version = GROWL_PROTOCOL_VERSION;
	switch (authMethod) {
		default:
		case GROWL_AUTH_MD5:
			nn->common.type     = GROWL_TYPE_NOTIFICATION;
			break;
		case GROWL_AUTH_SHA256:
			nn->common.type     = GROWL_TYPE_NOTIFICATION_SHA256;
			break;
		case GROWL_AUTH_NONE:
			nn->common.type     = GROWL_TYPE_NOTIFICATION_NOAUTH;
			break;
	}
	nn->flags.reserved = 0;
	if (priority) {
		int value;
		CFNumberGetValue(priority, kCFNumberIntType, &value);
		nn->flags.priority = value;
	} else {
		nn->flags.priority = 0;
	}
	nn->flags.sticky   = isSticky ? CFBooleanGetValue(isSticky) : 0;
	nn->nameLen        = htons(notificationNameLen);
	nn->titleLen       = htons(titleLen);
	nn->descriptionLen = htons(descriptionLen);
	nn->appNameLen     = htons(applicationNameLen);
	data = nn->data;
	memcpy(data, notificationName, notificationNameLen);
	data += notificationNameLen;
	memcpy(data, title, titleLen);
	data += titleLen;
	memcpy(data, description, descriptionLen);
	data += descriptionLen;
	memcpy(data, applicationName, applicationNameLen);
	data += applicationNameLen;

	packetData.Data = (unsigned char *)nn;
	packetData.Length = length;
	passwordData.Data = (uint8 *)password;
	passwordData.Length = password ? strlen(password) : 0U;
	addChecksumToPacket(&packetData, authMethod, &passwordData);

	*packetSize = length;

	free(notificationName);
	free(applicationName);
	free(title);
	free(description);

	return (unsigned char *)nn;
}

#warning we need a way to handle the unlikely but fully-possible case wherein the dictionary contains more All notifications than the 8-bit Default indices can hold (Zero-One-Infinity) - first stage would be to try moving all the default notifications to the lower indices of the All array, second stage would be to create multiple packets

unsigned char *GrowlUDPUtils_registrationToPacket(CFDictionaryRef aNotification, enum GrowlAuthenticationMethod authMethod, const char *password, unsigned *packetSize) {
	struct GrowlNetworkRegistration *nr;
	unsigned char  *data;
	char           *notification;
	unsigned       i;
	unsigned       size;
	unsigned       digestLength;
	unsigned       notificationIndex;
	size_t         length;
	unsigned short applicationNameLen;
	char           *applicationName;
	unsigned       numAllNotifications;
	unsigned       numDefaultNotifications;
	CFTypeID       CFNumberID = CFNumberGetTypeID();
	CSSM_DATA      packetData;
	CSSM_DATA      passwordData;
	CFArrayRef     allNotifications;
	CFArrayRef     defaultNotifications;

	applicationName         = copyCString(CFDictionaryGetValue(aNotification, GROWL_APP_NAME), kCFStringEncodingUTF8);
	allNotifications        = CFDictionaryGetValue(aNotification, GROWL_NOTIFICATIONS_ALL);
	defaultNotifications    = CFDictionaryGetValue(aNotification, GROWL_NOTIFICATIONS_DEFAULT);
	applicationNameLen      = strlen(applicationName);
	numAllNotifications     = CFArrayGetCount(allNotifications);
	numDefaultNotifications = CFArrayGetCount(defaultNotifications);

	// compute packet size
	switch (authMethod) {
		case GROWL_AUTH_NONE:
			digestLength = 0U;
			break;
		default:
		case GROWL_AUTH_MD5:
			digestLength = MD5_DIGEST_LENGTH;
			break;
		case GROWL_AUTH_SHA256:
			digestLength = SHA256_DIGEST_LENGTH;
			break;
	}
	length = sizeof(*nr) + applicationNameLen + digestLength;
	for (i = 0; i < numAllNotifications; ++i) {
		notification = copyCString(CFArrayGetValueAtIndex(allNotifications, i), kCFStringEncodingUTF8);
		length       += sizeof(unsigned short) + strlen(notification);
		free(notification);
	}
	size = numDefaultNotifications;
	for (i = 0; i < numDefaultNotifications; ++i) {
		CFNumberRef num = CFArrayGetValueAtIndex(defaultNotifications, i);
		if (CFGetTypeID(num) == CFNumberID) {
			CFNumberGetValue(num, kCFNumberIntType, &notificationIndex);
			if (notificationIndex >= numAllNotifications) {
				NSLog(CFSTR("Warning: index %u found in defaultNotifications is not within the range (%u) of the notifications array"), notificationIndex, numAllNotifications);
				--size;
			} else if (notificationIndex > UCHAR_MAX) {
				NSLog(CFSTR("Warning: index %u found in defaultNotifications is not within the range (%u) of an 8-bit unsigned number"), notificationIndex);
				--size;
			} else {
				++length;
			}
		} else {
			notificationIndex = CFArrayGetFirstIndexOfValue(allNotifications, CFRangeMake(0, numAllNotifications), num);
			if (notificationIndex == (unsigned)-1) {
				NSLog(CFSTR("Warning: defaultNotifications is not a subset of allNotifications (object found in defaultNotifications that is not in allNotifications; description of object is %@)"), num);
				--size;
			} else {
				++length;
			}
		}
	}

	nr = (struct GrowlNetworkRegistration *)malloc(length);
	nr->common.version          = GROWL_PROTOCOL_VERSION;
	switch (authMethod) {
		default:
		case GROWL_AUTH_MD5:
			nr->common.type     = GROWL_TYPE_REGISTRATION;
			break;
		case GROWL_AUTH_SHA256:
			nr->common.type     = GROWL_TYPE_REGISTRATION_SHA256;
			break;
		case GROWL_AUTH_NONE:
			nr->common.type     = GROWL_TYPE_REGISTRATION_NOAUTH;
			break;
	}
	nr->appNameLen              = htons(applicationNameLen);
	nr->numAllNotifications     = (unsigned char)numAllNotifications;
	nr->numDefaultNotifications = (unsigned char)size;
	data = nr->data;
	memcpy(data, applicationName, applicationNameLen);
	data += applicationNameLen;
	for (i = 0; i < numAllNotifications; ++i) {
		notification = copyCString(CFArrayGetValueAtIndex(allNotifications, i), kCFStringEncodingUTF8);
		size = strlen(notification);
		*(unsigned short *)data = htons(size);
		data += sizeof(unsigned short);
		memcpy(data, notification, size);
		data += size;
		free(notification);
	}
	for (i = 0; i < numDefaultNotifications; ++i) {
		CFNumberRef num = CFArrayGetValueAtIndex(defaultNotifications, i);
		if (CFGetTypeID(num) == CFNumberID) {
			CFNumberGetValue(num, kCFNumberIntType, &notificationIndex);
			if ((notificationIndex <  numAllNotifications)
			&& (notificationIndex <= UCHAR_MAX)) {
				*data++ = notificationIndex;
			}
		} else {
			notificationIndex = CFArrayGetFirstIndexOfValue(allNotifications, CFRangeMake(0, numAllNotifications), num);
			if ((notificationIndex <  numAllNotifications)
			&& (notificationIndex <= UCHAR_MAX)
			&& (notificationIndex != (unsigned)-1)) {
				*data++ = notificationIndex;
			}
		}
	}

	packetData.Data = (unsigned char *)nr;
	packetData.Length = length;
	passwordData.Data = (uint8 *)password;
	passwordData.Length = password ? strlen(password) : 0U;
	addChecksumToPacket(&packetData, authMethod, &passwordData);

	*packetSize = length;

	free(applicationName);

	return (unsigned char *)nr;
}

static uint8 iv[16] = { 0U,0U,0U,0U,0U,0U,0U,0U,0U,0U,0U,0U,0U,0U,0U,0U };
static const CSSM_DATA ivCommon = {16U, iv};

void GrowlUDPUtils_cryptPacket(CSSM_DATA_PTR packet, CSSM_ALGORITHMS algorithm, CSSM_DATA_PTR password, Boolean doEncrypt) {
	CSSM_CC_HANDLE   ccHandle;
	CSSM_KEY         key;
	CSSM_DATA        inData;
	CSSM_DATA        remData;
	CSSM_CRYPTO_DATA seed;
	CSSM_RETURN      crtn;
	uint32           bytesCrypted;

	seed.Param = *password;
	seed.Callback = NULL;
	seed.CallerCtx = NULL;

	crtn = CSSM_CSP_CreateDeriveKeyContext(cspHandle, CSSM_ALGID_PKCS12_PBE_ENCR,
										   algorithm, 128U,
										   /*AccessCred*/ NULL,
										   /*BaseKey*/ NULL,
										   /*IterationCount*/ 1U,
										   /*Salt*/ NULL,
										   /*Seed*/ &seed,
										   &ccHandle);
	crtn = CSSM_DeriveKey(ccHandle,
						  (CSSM_DATA_PTR)&ivCommon,
						  doEncrypt ? CSSM_KEYUSE_ENCRYPT : CSSM_KEYUSE_DECRYPT,
						  /*KeyAttr*/ 0U,
						  /*KeyLabel*/ NULL,
						  /*CredAndAclEntry*/ NULL,
						  &key);
	CSSM_DeleteContext(ccHandle);

	crtn = CSSM_CSP_CreateSymmetricContext(cspHandle,
										   algorithm,
										   CSSM_ALGMODE_CBCPadIV8,
										   /*AccessCred*/ NULL,
										   &key,
										   &ivCommon,
										   CSSM_PADDING_PKCS7,
										   /*Reserved*/ NULL,
										   &ccHandle);

	inData.Data = packet->Data + 1;	// skip the version byte
	inData.Length = packet->Length - 1;
	remData.Data = NULL;
	remData.Length = 0U;
	if (doEncrypt) {
		crtn = CSSM_EncryptData(ccHandle,
								&inData,
								1U,
								&inData,
								1U,
								&bytesCrypted,
								&remData);
		if (remData.Length) {
			unsigned newlength = packet->Length + remData.Length;
			packet->Data = realloc(packet->Data, newlength);
			memcpy(packet->Data + packet->Length, remData.Data, remData.Length);
			packet->Length = newlength;
		}
		packet->Data[0] = GROWL_PROTOCOL_VERSION_AES128;	// adjust version byte
	} else {
		crtn = CSSM_DecryptData(ccHandle,
								&inData,
								1U,
								&inData,
								1U,
								&bytesCrypted,
								&remData);
		packet->Data[0] = GROWL_PROTOCOL_VERSION;	// adjust version byte
	}
	packet->Length = bytesCrypted + 1;
	if (remData.Data)
		free(remData.Data);

	CSSM_DeleteContext(ccHandle);
	CSSM_FreeKey(cspHandle,
				 /*AccessCred*/ NULL,
				 &key,
				 /*Delete*/ CSSM_FALSE);
}
