//
//  GrowlUDPServer.h
//  Growl
//
//  Created by Ingmar Stein on 18.11.04.
//  Copyright 2004 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to License.txt for details

#import <Foundation/Foundation.h>

@interface GrowlUDPServer : NSObject {
	NSSocketPort *sock;
	NSFileHandle *fh;
}

@end
