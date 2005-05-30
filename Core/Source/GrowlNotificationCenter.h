//
//  GrowlNotificationCenter.h
//  Growl
//
//  Created by Ingmar Stein on 27.04.05.
//  Copyright 2005 The Growl Project. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol GrowlNotificationObserver
- (oneway void) notifyWithDictionary:(bycopy NSDictionary *)dict;
@end

@protocol GrowlNotificationCenterProtocol
- (oneway void) addObserver:(byref id<GrowlNotificationObserver>)observer;
- (oneway void) removeObserver:(byref id<GrowlNotificationObserver>)observer;
@end

@interface GrowlNotificationCenter : NSObject <GrowlNotificationCenterProtocol> {
	NSMutableArray *observers;
}
- (void) notifyObservers:(NSDictionary *)dict;
@end

