//
//  GrowlNetworkPacketParser.h
//  Growl
//
//  Created by Evan Schoenberg on 9/5/08.
//  Copyright 2008 Adium X / Saltatory Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef enum {
	GrowlHeaderError
} GrowlNetworkPacketErrorType;
	
@interface GrowlNetworkPacketParser : NSObject {
	NSMutableDictionary *currentNetworkPackets;
}

@end
