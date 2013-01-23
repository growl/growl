//
//  GrowlDispatchMutableDictionary.m
//  GNTPTestServer
//
//  Created by Daniel Siemer on 7/9/12.
//  Copyright (c) 2012 The Growl Project, LLC. All rights reserved.
//

#import "GrowlDispatchMutableDictionary.h"

@interface GrowlDispatchMutableDictionary ()

@property (nonatomic, assign) dispatch_queue_t dispatchQueue;
@property (nonatomic, retain) NSMutableDictionary *dictionary;

@end

@implementation GrowlDispatchMutableDictionary

@synthesize dispatchQueue = _dispatchQueue;
@synthesize dictionary = _dictionary;

+(GrowlDispatchMutableDictionary*)dictionaryWithQueueName:(NSString*)queueName {
	return [[[GrowlDispatchMutableDictionary alloc] initWithDispatchQueueName:queueName] autorelease];
}

+(GrowlDispatchMutableDictionary*)dictionaryWithQueue:(dispatch_queue_t)queue {
	return [[[GrowlDispatchMutableDictionary alloc] initWithDispatchQueue:queue] autorelease];
}

-(id)init {
	if((self = [super init])){
		self.dictionary = [NSMutableDictionary dictionary];
	}
	return self;
}

-(id)initWithDispatchQueueName:(NSString*)queueName{
	if((self = [self init])){
		self.dispatchQueue = dispatch_queue_create([queueName UTF8String], DISPATCH_QUEUE_CONCURRENT);
	}
	return self;
}

/* CALLER NEEDS TO SEND A RELEASE TO THE QUEUE */
-(id)initWithDispatchQueue:(dispatch_queue_t)queue {
	if((self = [self init])){
		self.dispatchQueue = queue;
		dispatch_retain(queue);
	}
	return self;
}

-(void)dealloc {
	dispatch_release(self.dispatchQueue);
	self.dictionary = nil;
	[super dealloc];
}

-(void)setObject:(id)anObject forKey:(NSString*)aKey {
	dispatch_barrier_async(self.dispatchQueue, ^{
		[self.dictionary setObject:anObject forKey:aKey];
	});
}

-(id)objectForKey:(NSString*)aKey {
	__block id obj = nil;
	dispatch_sync(self.dispatchQueue, ^{
		obj = [self.dictionary objectForKey:aKey];
		[obj retain];
	});
	return [obj autorelease];
}

-(NSArray*)allValues {
	__block NSArray *array = nil;
	dispatch_sync(self.dispatchQueue, ^{
		array = [self.dictionary allValues];
		[array retain];
	});
	return [array autorelease];
}

-(NSUInteger)objectCount {
	__block NSUInteger count = 0;
	dispatch_sync(self.dispatchQueue, ^{
		count = [[self.dictionary allValues] count];
	});
	return count;
}

-(NSDictionary*)dictionaryCopy {
	__block NSDictionary *copy = nil;
	dispatch_sync(self.dispatchQueue, ^{
		copy = [self.dictionary copy];
	});
	return [copy autorelease];
}

-(void)removeObjectForKey:(id)aKey {
	if(aKey){
		dispatch_barrier_async(self.dispatchQueue, ^{
			[self.dictionary removeObjectForKey:aKey];
		});
	}
}

-(void)removeAllObjects {
	dispatch_barrier_async(self.dispatchQueue, ^{
		[self.dictionary removeAllObjects];
	});
}

@end
