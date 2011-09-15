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
#import "GrowlNotifier.h"
#import "GrowlGNTPCommunicationAttempt.h"
#import "GrowlGNTPRegistrationAttempt.h"
#import "GrowlGNTPNotificationAttempt.h"

static GrowlNotifier *notifier = nil;

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
      
      
      NSDictionary *dict = [NSObject xpcObjectToNSObject:event];
      NSString *purpose = [dict valueForKey:@"GrowlDictType"];
      NSLog(@"purpose: %@", purpose);
      // Here we unpack our dictionary.
      NSDictionary *growlDict = [dict objectForKey:@"GrowlDict"];
            
      NSString *host = [dict valueForKey:@"GNTPHost"];
      NSString *pass = [dict valueForKey:@"GNTPPassword"];
            
      if ([purpose caseInsensitiveCompare:@"registration"] == NSOrderedSame) {
         GrowlGNTPRegistrationAttempt *registrationAttempt = [[[GrowlGNTPRegistrationAttempt alloc] initWithDictionary:growlDict] autorelease];
         registrationAttempt.delegate = (id <GrowlCommunicationAttemptDelegate>)notifier;
         registrationAttempt.host = host;
         registrationAttempt.password = pass;
         registrationAttempt.connection = peer;

         [notifier sendCommunicationAttempt:registrationAttempt];
      }
      else if ([purpose caseInsensitiveCompare:@"notification"] == NSOrderedSame) {
         GrowlGNTPNotificationAttempt *notificationAttempt = [[[GrowlGNTPNotificationAttempt alloc] initWithDictionary:growlDict] autorelease];
         notificationAttempt.delegate = (id <GrowlCommunicationAttemptDelegate>)notifier;
         notificationAttempt.host = host;
         notificationAttempt.password = pass;
         notificationAttempt.connection = peer;

         [notifier sendCommunicationAttempt:notificationAttempt];
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
   notifier = [[GrowlNotifier alloc] init];
	xpc_main(GNTP_event_handler);
	return 0;
}
