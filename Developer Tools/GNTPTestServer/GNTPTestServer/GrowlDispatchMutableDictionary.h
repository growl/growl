//
//  GrowlDispatchMutableDictionary.h
//  GNTPTestServer
//
//  Created by Daniel Siemer on 7/9/12.
//  Copyright (c) 2012 The Growl Project, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GrowlDispatchMutableDictionary : NSObject

+(GrowlDispatchMutableDictionary*)dictionaryWithQueueName:(NSString*)queueName;
+(GrowlDispatchMutableDictionary*)dictionaryWithQueue:(dispatch_queue_t)queue;

-(void)setObject:(id)anObject forKey:(id)aKey;
-(id)objectForKey:(id)aKey;
-(NSArray*)allValues;
-(void)removeObjectForKey:(id)aKey;
-(void)removeAllObjects;

@end
