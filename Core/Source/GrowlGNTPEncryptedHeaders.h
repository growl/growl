//
//  GrowlGNTPEncryptedHeaders.h
//  Growl
//
//  Created by Rudy Richter on 10/12/09.
//  Copyright 2009 The Growl Project. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GrowlTCPPathway.h"

@interface GrowlGNTPEncryptedHeaders : NSObject<GNTPOutgoingItem> 
{
	NSData *_headers;
}

+ (GrowlGNTPEncryptedHeaders *)headerItemFromData:(NSData *)inData error:(NSError **)outError;
- (id)initForData:(NSData *)inData error:(NSError **)outError;
- (NSData *)GNTPRepresentation;
		 
@property (retain) NSData *headers;
@end
