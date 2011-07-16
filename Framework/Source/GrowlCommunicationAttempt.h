//
//  GrowlCommunicationAttempt.h
//  Growl
//
//  Copyright 2011 The Growl Project. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GrowlCommunicationAttempt;

@protocol GrowlCommunicationAttemptDelegate <NSObject>

- (void) attemptDidSucceed:(GrowlCommunicationAttempt *)attempt;
- (void) attemptDidFail:(GrowlCommunicationAttempt *)attempt;

@end

@interface GrowlCommunicationAttempt : NSObject
{
	NSDictionary *dictionary;
	GrowlCommunicationAttempt *nextAttempt;
	id <GrowlCommunicationAttemptDelegate> delegate;
}

//Designated initializer
- (id) initWithDictionary:(NSDictionary *)dict;

@property(nonatomic, readonly) NSDictionary *dictionary;

//Automatically creates (with the same dictionary) a new attempt that is an instance of this class and sets it as this attempt's next attempt.
- (id) makeNextAttemptOfClass:(Class)classToTryNext;

//Each attempt that fails will automatically tell the next attempt to begin.
@property(nonatomic, retain) GrowlCommunicationAttempt *nextAttempt;

@property(nonatomic, assign) id <GrowlCommunicationAttemptDelegate> delegate;

//Users of this class should examine this property if the attempt fails and they want to know why.
//Only subclasses should assign to it.
@property(nonatomic, retain) NSError *error;

//Start to try to communicate the dictionary. Subclasses: You must implement this completely yourself; this class's implementation throws an exception.
- (void) begin;

//Subclasses: Send these messages to yourself when succeeding or failing.
- (void) succeeded;
- (void) failed;

@end
