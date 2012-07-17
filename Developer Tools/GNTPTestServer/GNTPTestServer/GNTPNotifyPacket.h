//
//  GNTPNotifyPacket.h
//  GNTPTestServer
//
//  Created by Daniel Siemer on 7/7/12.
//  Copyright (c) 2012 The Growl Project, LLC. All rights reserved.
//

#import "GNTPPacket.h"

@interface GNTPNotifyPacket : GNTPPacket {
	NSString *_callbackString;
	NSString *_callbackType;
}

+(NSData*)feedbackData:(BOOL)clicked forGrowlDictionary:(NSDictionary*)dictionary;

@end
