//
//  GrowlNotificationCenter.h
//  Growl
//
//  Created by Ingmar Stein on 27.04.05.
//  Copyright 2005-2006 The Growl Project. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/*!
 *	@protocol GrowlNotificationObserver
 *	@abstract Required protocol for GrowlNotificationCenter observers.
 *	@discussion Objects that want to be registered as observers for the
 *      GrowlNotificationCenter have to adhere to this protocol. It provides
 *      a callback that is called for every notification.
 */
@protocol GrowlNotificationObserver
- (oneway void) notifyWithDictionary:(bycopy NSDictionary *)dict;
@end

/*!
 *	@protocol GrowlNotificationCenterProtocol
 *	@abstract Formal protocol for the GrowlNotificationCenter.
 *	@discussion The methods in this protocol are available via DO.
 */
@protocol GrowlNotificationCenterProtocol
- (oneway void) addObserver:(byref id<GrowlNotificationObserver>)observer;
- (oneway void) removeObserver:(byref id<GrowlNotificationObserver>)observer;
@end

/*!
 *	@class      GrowlNotificationCenter
 *	@abstract   A DO server for Growl's notification.
 *	@discussion GrowlNotificationCenter is an exposed distributed object
 *      where observers can subscribe to be notified of every notification
 *      that is received by Growl.
 */
@interface GrowlNotificationCenter : NSObject <GrowlNotificationCenterProtocol> {
	NSMutableArray *observers;
}

/*!
 *	@method notifyObservers
 *	@abstract Notify all registered observers.
 *	@discussion Send -notifyWithDictionary: to all registered observers.
 *      dict should be the dictionary representation of a Growl notification.
 */
- (void) notifyObservers:(NSDictionary *)dict;

@end
