//
//  GNTPSubscribePacket.m
//  GNTPTestServer
//
//  Created by Daniel Siemer on 7/10/12.
//  Copyright (c) 2012 The Growl Project, LLC. All rights reserved.
//

#import "GNTPSubscribePacket.h"

@implementation GNTPSubscribePacket

+(id)convertedObjectFromGrowlObject:(id)obj forGNTPKey:(NSString *)gntpKey {
	id converted = [super convertedObjectFromGrowlObject:obj forGNTPKey:gntpKey];
	if(converted)
		return converted;
	if([gntpKey isEqualToString:GrowlGNTPSubscriberPort]){
		if([obj integerValue] > 0 && [obj integerValue] != GROWL_TCP_PORT)
			converted = [NSString stringWithFormat:@"%ld", [obj integerValue]];
	}
	
	return converted;
}

@end
