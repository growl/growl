//
//  GrowlGNTPNotificationAttempt.m
//  Growl
//
//  Created by Peter Hosey on 2011-07-14.
//  Copyright 2011 The Growl Project. All rights reserved.
//

#import "GrowlGNTPNotificationAttempt.h"

#import "GrowlGNTPOutgoingPacket.h"

@implementation GrowlGNTPNotificationAttempt

- (GrowlGNTPOutgoingPacket *) packet {
	return [GrowlGNTPOutgoingPacket outgoingPacketOfType:GrowlGNTPOutgoingPacket_NotifyType forDict:self.dictionary];
}

@end
