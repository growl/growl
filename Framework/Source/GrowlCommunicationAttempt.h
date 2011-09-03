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
- (void) finishedWithAttempt:(GrowlCommunicationAttempt *)attempt;
- (void) queueAndReregister:(GrowlCommunicationAttempt *)attempt;

@end

enum {
	GrowlCommunicationAttemptTypeNone,
	GrowlCommunicationAttemptTypeRegister,
	GrowlCommunicationAttemptTypeNotify,
	GrowlCommunicationAttemptTypeSubscribe, //as yet unused
};
typedef NSUInteger GrowlCommunicationAttemptType;

@interface GrowlCommunicationAttempt : NSObject
{
	NSDictionary *dictionary;
	GrowlCommunicationAttemptType attemptType;
	GrowlCommunicationAttempt *nextAttempt;
	id <GrowlCommunicationAttemptDelegate> delegate;
	NSError *error;
}

//To be overridden by subclasses. If your subclass can be any attempt type, return GrowlCommunicationAttemptTypeNone and initialize the attemptType variable in your -initWithDictionary:. GrowlCommunicationAttempt's implementation of +attemptType throws an exception.
+ (GrowlCommunicationAttemptType) attemptType;

//Designated initializer
- (id) initWithDictionary:(NSDictionary *)dict;

@property(nonatomic, readonly) NSDictionary *dictionary;

//Initialized automatically by -[GrowlCommunicationAttempt initWithDictionary:] with the value returned by [[self class] attemptType].
@property(nonatomic, readonly) GrowlCommunicationAttemptType attemptType;

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
- (void) queueAndReregister;
- (void) stopAttempts;
- (void) succeeded;
- (void) failed;
- (void) finished;

@end
