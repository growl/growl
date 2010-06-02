//
//  GrowlSubscribeGNTPPacket.h
//  Growl
//
//  Created by Rudy Richter on 10/7/09.
//  Copyright 2009 The Growl Project. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GrowlGNTPPacket.h"
#import "GrowlGNTPHeaderItem.h"
#import "GrowlDefines.h"

@interface GrowlSubscribeGNTPPacket : GrowlGNTPPacket 
{
	NSString *mSubscriberKeyHash;
	NSString *mSubscriberID;
	NSString *mSubscriberName;
	NSInteger mSubscriberPort;
	NSInteger mTTL;
	
	NSMutableDictionary *subscriptionDict;

}

@property (retain) NSString *subscriberKeyHash;
@property (retain) NSString *subscriberID;
@property (retain) NSString *subscriberName;
@property (assign) NSInteger subscriberPort;
@property (assign) NSInteger ttl;
@end
