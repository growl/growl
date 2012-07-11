//
//  GrowlTCPPathway.h
//  Growl
//
//  Created by Peter Hosey on 2006-02-13.
//  Copyright 2006 The Growl Project. All rights reserved.
//

#import "GrowlRemotePathway.h"
#import "GNTPServer.h"

@class MD5Authenticator;

@protocol GNTPOutgoingItem
/*!
 * @brief Get the GNTP representation of an item
 *
 * The returned NSData is CRLF terminated and UTF8 encoded.
 */
- (NSData *)GNTPRepresentation;

//Primarily for debugging purposes, though subclasses may put the implementation here and simply implement -GNTPRepresentation to send this string dataUsingEncoding:NSUTF8StringEncoding.
- (NSString *) GNTPRepresentationAsString;
@end

@interface GrowlTCPPathway : GrowlRemotePathway

@end
