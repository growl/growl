//
//  GNTPSubscribePacket.h
//  GNTPTestServer
//
//  Created by Daniel Siemer on 7/10/12.
//  Copyright (c) 2012 The Growl Project, LLC. All rights reserved.
//

#import "GNTPPacket.h"

@interface GNTPSubscribePacket : GNTPPacket

@property (nonatomic, assign) NSUInteger ttl;

@end
