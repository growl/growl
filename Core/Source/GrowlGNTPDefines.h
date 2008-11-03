//
//  GrowlGNTPDefines.h
//  Growl
//

#define GROWL_NETWORK_DOMAIN		@"GrowlNetwork"

typedef enum {
	GrowlGNTPHeaderError,
	GrowlGNTPMalformedProtocolIdentificationError,
	GrowlGNTPRegistrationPacketError,
	GrowlGNTPCallbackPacketError
} GrowlGNTPPacketErrorType;

typedef enum {
	GrowlGNTP_NoCallback,
	GrowlGNTP_TCPCallback,
	GrowlGNTP_URLCallback
} GrowlGNTPCallbackBehavior;
