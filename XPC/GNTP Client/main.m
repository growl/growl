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

static NSDictionary * xpcDictionaryToNSDict(xpc_object_t object)
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    xpc_dictionary_apply(object, ^bool(const char *key, xpc_object_t value){
        NSString *nsKey = [NSString stringWithCString:key encoding:NSUTF8StringEncoding];
        id nsValue = nil;
        
        xpc_type_t newType = xpc_get_type(value);
        
        if (newType == XPC_TYPE_DICTIONARY) {
            nsValue = xpcDictionaryToNSDict(value);
        }
        else if (newType == XPC_TYPE_STRING) {
            const char *string = xpc_string_get_string_ptr(value);
            nsValue = [NSString stringWithUTF8String:string];
        }
        else if (newType == XPC_TYPE_BOOL) {
            BOOL boolValue = xpc_bool_get_value(value);
            nsValue = [NSNumber numberWithBool:boolValue];
        }
        else if (newType == XPC_TYPE_INT64) {
            int64_t intValue = xpc_int64_get_value(value);
            nsValue = [NSNumber numberWithInteger:intValue];
        }
        else if (newType == XPC_TYPE_DATA) {
            const void *rawData = xpc_data_get_bytes_ptr(value);
            size_t dataLength = xpc_data_get_length(value);
            nsValue = [[[NSData alloc] initWithBytes:rawData length:dataLength] autorelease];
        }
        
        if (nsValue && ![nsKey isEqualToString:@"growlMessagePurpose"])
            [dict setObject:nsValue forKey:nsKey];
        
        return true;
    });
    
    return dict;
}

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
        
        // Here we unpack our dictionary.
        NSDictionary *dict = xpcDictionaryToNSDict(event);
        NSLog(@"test %@", [dict valueForKey:GROWL_APP_NAME]);
      
        if (!strcmp(purpose,"registration")) {
            // The rest of our xpc_dictionary is a registration packet.  
            
            // Build GNTP packet and send onwards
            
            // Send back a reply when done, with a single boolean parameter
            // named 'success'
        }
        else if (!strcmp(purpose,"notification")) {
            // The rest of our xpc_dictionary is a notification packet.
            
            // Build GNTP packet and send onward
            
            // Send back a reply when done, with a single boolean parameter
            // named 'success'
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
