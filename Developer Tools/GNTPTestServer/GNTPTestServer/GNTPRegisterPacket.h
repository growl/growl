//
//  GNTPRegisterPacket.h
//  GNTPTestServer
//
//  Created by Daniel Siemer on 7/4/12.
//  Copyright (c) 2012 The Growl Project, LLC. All rights reserved.
//

#import "GNTPPacket.h"

@interface GNTPRegisterPacket : GNTPPacket {
	NSUInteger _totalNotifications;
	NSUInteger _readNotifications;
	NSMutableArray *_notificationDicts;

}

@property (nonatomic, retain) NSMutableArray *notificationDicts;

@end
