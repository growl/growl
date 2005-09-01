//
//  GBSingletonObject.m
//  GBUtilities
//
//  Created by Ofri Wolfus on 15/08/05.
//  Copyright 2005 Ofri Wolfus. All rights reserved.
//

#import "GrowlAbstractSingletonObject.h"


@interface GrowlAbstractSingletonObject (_private)
- (void)_setIsInitialized:(BOOL)flag;
@end

@implementation GrowlAbstractSingletonObject

//This dictionary will contain all singleton objects that are inherited from GBAbstractSingletonObject.
static NSMutableDictionary	*singletonObjects = nil;

//Create our dictionary
+ (void)initialize {
	@synchronized(singletonObjects) {
		if(!singletonObjects)
			singletonObjects = [[NSMutableDictionary alloc] init];
	}
}

//Returns the shared instance of this class
+ (id)sharedInstance {
	id	returnedObject = nil;
	
	if (singletonObjects) {
		@synchronized(singletonObjects) {
			//Look of we already have an instance
			returnedObject = [singletonObjects objectForKey:self];
			
			//We don't have any instance so lets create it
			if(!returnedObject) {
				returnedObject = [[self alloc] initSingleton];
				
				if(returnedObject)
					[singletonObjects setObject:returnedObject forKey:[self class]];
			}
		}
	}
	
	return returnedObject;
}

//Release the singletonObjects dictionary and by that destory all the object's it contains
+ (void)destroyAllSingletons {
	NSDictionary *dict = singletonObjects;
	
	//We first make singletonObjects to point to nil in order to allow deallocation of our singletons
	singletonObjects = nil;
	//And then release the dictionary. When the dictionary is released, it releases all it's objects.
	//When the objects were added to the dict, they received a retain message and since we override
	//-retain to do nothing, the objects still have a retain count of 1.
	//That's why all the objects will be released.
	[dict release];
}

//Used by +alloc to set the _isInitialized flag.
- (void)_setIsInitialized:(BOOL)flag {
	_isInitialized = flag;
}

//Implemented by subclasses
- (id)initSingleton {
	id	object = [singletonObjects objectForKey:[self class]];
	
	if (object || _isInitialized) {
		[self release];
		NSLog(@"Initializing an object twice is not a very good idea...");
		[self doesNotRecognizeSelector:_cmd];
		return [[self class] sharedInstance];
	}
	else
		return self;
}

//Does nothing by default
- (oneway void)destroy {
	[super dealloc];
}

//Override to work only in case we don't already have an instance
+ (id)alloc {
	id	object = nil;
	
	if (singletonObjects) {
		object = [singletonObjects objectForKey:[self class]];
		
		if (object) {
			NSLog(@"An attempt to allocate a new %@ singleton object has been made. "
				  @"Don't do that! It's not healthy!", NSStringFromClass([self class]));
			[self doesNotRecognizeSelector:_cmd];	//This wasn't supposed to happen!
		} else {
			object = [super alloc];
			[object _setIsInitialized:NO];
		}
	}
	
	return object;
}

//Init should never be called!
- (id)init {
	[self release];	//In most cases does nothing.
	NSLog(@"An attempt to initialize a new %@ singleton object has been made. "
		  @"Don't do that! It's not healthy!", NSStringFromClass([self class]));
	[self doesNotRecognizeSelector:_cmd];
	return [[self class] sharedInstance];
}

//Release anything but our shared class
- (void)release {
	id	object = [singletonObjects objectForKey:[self class]];
	
	if (self != object)
		[super release];
}

//Allow deallocation only when destroying all singletons
- (void)dealloc {
	if (!singletonObjects) {
		[self destroy];
	}
}

//I think it's pretty obvious what this does.
- (id)autorelease {
	return self;
}

//And if you didn't get it from the comment above - it does NOTHING! :D
- (id)retain {
	return self;
}

//I have nothing to write here but i should since i've written in all the above methods...
- (unsigned)retainCount {
	if (singletonObjects)
		return UINT_MAX;
	else
		return [super retainCount];		//Always 1 since -retain does nothing.
}

@end
