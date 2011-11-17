//
//  GrowlKeychainUtilities.h
//  Growl
//
//  Created by Daniel Siemer on 11/17/11.
//  Copyright (c) 2011 The Growl Project. All rights reserved.
//

#import <Foundation/Foundation.h>

#define GrowlOutgoingNetworkPassword   @"GrowlOutgoingNetworkConnection"
#define GrowlSubscriberPassword        @"GrowlSubscriberConnection"
#define GrowlSubscribeToPassword       @"GrowlSubscribeToConnection"
#define GrowlIncomingNetworkPassword   @"Growl"

@interface GrowlKeychainUtilities : NSObject

+(NSString*)passwordForServiceName:(NSString*)service accountName:(NSString*)account;
+(BOOL)setPassword:(NSString*)password forService:(NSString*)service accountName:(NSString*)account;
+(BOOL)removePasswordForService:(NSString*)service accountName:(NSString*)account;

@end
