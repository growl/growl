//
//  GrowlCallbackGNTPPacket.h
//  Growl
//
//  Created by Evan Schoenberg on 11/3/08.
//  Copyright 2008-2009 The Growl Project. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GrowlGNTPPacket.h"

@interface GrowlCallbackGNTPPacket : GrowlGNTPPacket {
	NSMutableDictionary *callbackDict;
	GrowlGNTPCallbackType callbackType;
}

- (GrowlGNTPCallbackType)callbackType;

@end
