//
//  GrowlGNTPRegistrationAttempt.m
//  Growl
//
//  Created by Peter Hosey on 2011-07-14.
//  Copyright 2011 The Growl Project. All rights reserved.
//

#import "GrowlGNTPRegistrationAttempt.h"

#import "GNTPRegisterPacket.h"

@implementation GrowlGNTPRegistrationAttempt

+ (GrowlCommunicationAttemptType) attemptType {
	return GrowlCommunicationAttemptTypeRegister;
}
/*
- (GrowlGNTPOutgoingPacket *) packet {
	return [GrowlGNTPOutgoingPacket outgoingPacketOfType:GrowlGNTPOutgoingPacket_RegisterType forDict:self.dictionary];
}
*/

-(NSData*)outgoingData {
	return [GNTPRegisterPacket gntpDataFromGrowlDictionary:self.dictionary ofType:@"REGISTER" withKey:self.key];
}

@end
