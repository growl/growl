//
//  GNTPSubscribePacket.m
//  GNTPTestServer
//
//  Created by Daniel Siemer on 7/10/12.
//  Copyright (c) 2012 The Growl Project, LLC. All rights reserved.
//

#import "GNTPSubscribePacket.h"
#import "GrowlDefinesInternal.h"

@implementation GNTPSubscribePacket

@synthesize ttl = _ttl;

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

-(id)init {
	if((self = [super init])){
		self.ttl = 3600;
	}
	return self;
}

-(NSString*)responseString {
	NSMutableString *returnHeaders = [NSMutableString string];
	[returnHeaders appendFormat:@"%@: %lu\r\n", GrowlGNTPResponseSubscriptionTTL, self.ttl];
	return [[super responseString] stringByAppendingString:returnHeaders];
}

-(BOOL)validate {
	return [super validate] && 
	[self.gntpDictionary objectForKey:GrowlGNTPSubscriberID] &&
	[self.gntpDictionary objectForKey:GrowlGNTPSubscriberName];
}

@end
