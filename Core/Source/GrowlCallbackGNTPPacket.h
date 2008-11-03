//
//  GrowlCallbackGNTPPacket.h
//  Growl
//
//  Created by Evan Schoenberg on 11/3/08.
//  Copyright 2008 Adium X / Saltatory Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GrowlGNTPPacket.h"

typedef enum {
	GrowlGNTPCallback_Closed,
	GrowlGNTPCallback_Clicked
} GrowlGNTPCallbackType;

@interface GrowlCallbackGNTPPacket : GrowlGNTPPacket {
	NSMutableDictionary *callbackDict;
	GrowlGNTPCallbackType callbackType;
}

- (GrowlGNTPCallbackType)callbackType;

@end
