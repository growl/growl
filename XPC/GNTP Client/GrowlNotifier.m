//
//  GrowlNotifier.m
//  Growl
//
//  Created by Daniel Siemer on 9/15/11.
//  Copyright 2011 The Growl Project. All rights reserved.
//

#import "GrowlNotifier.h"
#import "GrowlDefines.h"
#import "GrowlGNTPCommunicationAttempt.h"
#import "GrowlGNTPRegistrationAttempt.h"
#import "GrowlGNTPNotificationAttempt.h"

#import "NSObject+XPCHelpers.h"

@interface GrowlNotifier ()

@property (nonatomic, assign) dispatch_queue_t attemptArrayQueue;

@end

@implementation GrowlNotifier

@synthesize currentAttempts;

- (id)init
{
	self = [super init];
	if (self) {
		// Initialization code here.
		self.currentAttempts = [NSMutableArray array];
		NSString *attemptArrayQueueName = [[[NSBundle mainBundle] bundleIdentifier] stringByAppendingString:@".attemptArrayQueue"];
		self.attemptArrayQueue = dispatch_queue_create([attemptArrayQueueName UTF8String], DISPATCH_QUEUE_SERIAL);
	}
	
	return self;
}

- (void)dealloc
{
	[currentAttempts release];
	currentAttempts = nil;
	[super dealloc];
}

- (void) sendCommunicationAttempt:(GrowlCommunicationAttempt *)attempt
{
	__block GrowlNotifier *blockSelf = self;
	dispatch_sync(_attemptArrayQueue, ^{
		[[blockSelf currentAttempts] addObject:attempt];
	});
	[attempt begin];
}

-(void)sendXPCMessage:(id)nsMessage connection:(xpc_connection_t)connection
{
	if(connection != NULL){
		xpc_object_t message = [(NSObject*)nsMessage newXPCObject];
		xpc_connection_send_message(connection, message);
		xpc_release(message);
	}
}

- (void) sendXPCFeedback:(GrowlCommunicationAttempt *)attempt context:(id)context feedback:(NSString*)feedback
{
	NSMutableDictionary *response = [NSMutableDictionary dictionary];
	[response setValue:@"feedback" forKey:@"GrowlActionType"];
	
	[response setValue:context forKey:@"Context"];
   BOOL clicked = [feedback isEqualToString:@"Clicked"] ? YES : NO;
	[response setValue:[NSNumber numberWithBool:clicked] forKey:@"Clicked"];
   [response setValue:feedback forKey:@"Feedback"];
	[self sendXPCMessage:response connection:[(GrowlGNTPCommunicationAttempt*)attempt connection]];
}

-(NSString*)actionTypeForAttempt:(GrowlCommunicationAttempt*)attempt{
	NSString *result = nil;
	if([attempt isKindOfClass:[GrowlGNTPRegistrationAttempt class]]){
		result = @"registration";
	}else if([attempt isKindOfClass:[GrowlGNTPNotificationAttempt class]]){
		result = @"notification";
	}else {
		result = @"unknown";
	}
	return result;
}

- (void) attemptDidSucceed:(GrowlCommunicationAttempt *)attempt{
	NSMutableDictionary *response = [NSMutableDictionary dictionary];
	[response setValue:[NSNumber numberWithBool:YES] forKey:@"Success"];
	
	[response setObject:[self actionTypeForAttempt:attempt] forKey:@"GrowlActionType"];
	
	[self sendXPCMessage:response connection:[(GrowlGNTPCommunicationAttempt*)attempt connection]];
}
- (void) attemptDidFail:(GrowlCommunicationAttempt *)attempt{
	__block NSMutableDictionary *response = [NSMutableDictionary dictionary];
	[response setValue:[NSNumber numberWithBool:NO] forKey:@"Success"];
	[response setObject:[self actionTypeForAttempt:attempt] forKey:@"GrowlActionType"];
	
	[[(GrowlGNTPCommunicationAttempt*)attempt callbackHeaderItems] enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
		if([key isEqualToString:@"Error-Code"])
			[response setValue:obj forKey:key];
		if([key isEqualToString:@"Error-Description"])
			[response setValue:obj forKey:key];
	}];
	
	[self sendXPCMessage:response connection:[(GrowlGNTPCommunicationAttempt*)attempt connection]];
	
	__block GrowlNotifier *blockSelf = self;
	dispatch_async(_attemptArrayQueue, ^{
		[[blockSelf currentAttempts] removeObject:attempt];
	});
}
- (void) finishedWithAttempt:(GrowlCommunicationAttempt *)attempt{
	NSDictionary *response = [NSDictionary dictionaryWithObject:@"finishedAttempt" forKey:@"GrowlActionType"];
	
	[self sendXPCMessage:response connection:[(GrowlGNTPCommunicationAttempt*)attempt connection]];
	__block GrowlNotifier *blockSelf = self;
	dispatch_async(_attemptArrayQueue, ^{
		[[blockSelf currentAttempts] removeObject:attempt];
	});
}
- (void) queueAndReregister:(GrowlCommunicationAttempt *)attempt{
	//we will have to ask our host app for the reg dict again via XPC
	NSMutableDictionary *response = [NSMutableDictionary dictionary];
	[response setValue:@"reregister" forKey:@"GrowlActionType"];
	
	[self sendXPCMessage:response connection:[(GrowlGNTPCommunicationAttempt*)attempt connection]];
}
- (void) notificationClicked:(GrowlCommunicationAttempt *)attempt context:(id)context{
	[self sendXPCFeedback:attempt context:context feedback:@"Clicked"];
}
- (void) notificationTimedOut:(GrowlCommunicationAttempt *)attempt context:(id)context{
	[self sendXPCFeedback:attempt context:context feedback:@"Timedout"];
}
- (void) notificationClosed:(GrowlCommunicationAttempt *)attempt context:(id)context {
   [self sendXPCFeedback:attempt context:context feedback:@"Closed"];
}

- (void)stoppedAttempts:(GrowlCommunicationAttempt *)attempt{
	NSDictionary *response = [NSDictionary dictionaryWithObject:@"stoppedAttempts" forKey:@"GrowlActionType"];
	
	[self sendXPCMessage:response connection:[(GrowlGNTPCommunicationAttempt*)attempt connection]];
}

- (void) notificationWasNotDisplayed:(GrowlCommunicationAttempt *)attempt {
   //we will have to ask our host app for the reg dict again via XPC
	NSMutableDictionary *response = [NSMutableDictionary dictionary];
	[response setValue:@"wasNotDisplayed" forKey:@"GrowlActionType"];
	
	[self sendXPCMessage:response connection:[(GrowlGNTPCommunicationAttempt*)attempt connection]];
}
@end
