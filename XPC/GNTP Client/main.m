//
//  main.m
//  GNTP
//
//  Created by Rachel Blackman on 9/01/11.
//  Copyright (c) 2011 The Growl Project. All rights reserved.
//

#include <xpc/xpc.h>
#import <Foundation/Foundation.h>
#import "GrowlDefines.h"
#import "NSObject+XPCHelpers.h"

static void GNTP_peer_event_handler(xpc_connection_t peer, xpc_object_t event) 
{
	xpc_type_t type = xpc_get_type(event);
	if (type == XPC_TYPE_ERROR) {
		if (event == XPC_ERROR_CONNECTION_INVALID) {
			// The client process on the other end of the connection has either
			// crashed or cancelled the connection. After receiving this error,
			// the connection is in an invalid state, and you do not need to
			// call xpc_connection_cancel(). Just tear down any associated state
			// here.
		} else if (event == XPC_ERROR_TERMINATION_IMMINENT) {
			// Handle per-connection termination cleanup.
		}
	} else {
		assert(type == XPC_TYPE_DICTIONARY);
      
      /*
       xpc_connection_t remote = xpc_dictionary_get_remote_connection(event);
       
       xpc_object_t reply = xpc_dictionary_create_reply(event); */
      
      const char *purpose = xpc_dictionary_get_string(event, "growlMessagePurpose");
      
      xpc_object_t xpcGrowlDict = xpc_dictionary_get_value(event, "GrowlDict");
      // Here we unpack our dictionary.
      assert(xpc_get_type(xpcGrowlDict) == XPC_TYPE_DICTIONARY);
      
      NSDictionary *growlDict = [NSObject xpcObjectToNSObject:xpcGrowlDict];
      NSLog(@"test %@", [growlDict valueForKey:GROWL_APP_NAME]);
      
      if (!strcmp(purpose,"registration")) {
      
      }
      else if (!strcmp(purpose,"notification")) {

      }
	}
}

static void GNTP_event_handler(xpc_connection_t peer) 
{
	// By defaults, new connections will target the default dispatch
	// concurrent queue.
	xpc_connection_set_event_handler(peer, ^(xpc_object_t event) {
		GNTP_peer_event_handler(peer, event);
	});
	
	// This will tell the connection to begin listening for events. If you
	// have some other initialization that must be done asynchronously, then
	// you can defer this call until after that initialization is done.
	xpc_connection_resume(peer);
}

int main(int argc, const char *argv[])
{
	xpc_main(GNTP_event_handler);
	return 0;
}
