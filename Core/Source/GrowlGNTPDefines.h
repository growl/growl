//
//  GrowlGNTPDefines.h
//  Growl
//

#define GROWL_NETWORK_DOMAIN		@"GrowlNetwork"

typedef enum {
	GrowlGNTPHeaderError,
	GrowlGNTPMalformedProtocolIdentificationError,
	GrowlGNTPRegistrationPacketError
} GrowlGNTPPacketErrorType;
