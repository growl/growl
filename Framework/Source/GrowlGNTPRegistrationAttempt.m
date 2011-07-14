//
//  GrowlGNTPRegistrationAttempt.m
//  Growl
//
//  Created by Peter Hosey on 2011-07-14.
//  Copyright 2011 The Growl Project. All rights reserved.
//

#import "GrowlGNTPRegistrationAttempt.h"

#import "GrowlGNTPOutgoingPacket.h"

@implementation GrowlGNTPRegistrationAttempt

- (GrowlGNTPOutgoingPacket *) packet {
	return [GrowlGNTPOutgoingPacket outgoingPacketOfType:GrowlGNTPOutgoingPacket_RegisterType forDict:self.dictionary];
}

@end
