//
//  GrowlNotificationServer.h
//  Growl
//
//  Created by Ingmar Stein on 15.11.04.
//  Copyright 2004 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to License.txt for details

#import <Foundation/Foundation.h>

@protocol GrowlNotificationProtocol
- (oneway void) registerApplication:(bycopy in NSDictionary *)dict;
- (oneway void) postNotification:(bycopy in NSDictionary *)notification;
- (NSString *) growlVersion;
@end

@interface GrowlPathway : NSObject {
}

- (void) registerApplicationWithDictionary:(NSDictionary *)dict;
- (void) postNotificationWithDictionary:(NSDictionary *)dict;

@end
