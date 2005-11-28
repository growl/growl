//
//	GrowlNonCopyingMutableDictionary.m
//	Growl
//
//	Created by Mac-arena the Bored Zo on 2005-08-21.
//	Copyright 2005 The Growl Project. All rights reserved.
//
//	This file is under the BSD License, refer to License.txt for details

#import "GrowlNonCopyingMutableDictionary.h"

//the enumerator class can be moved to its own pair of files if an immutable non-copying dictionary class is created.
@interface GrowlNonCopyingDictionaryEnumerator: NSEnumerator
{
	NSMapEnumerator mapEnum;
	unsigned reserved: 30;
	unsigned yieldKeys: 1;
	unsigned hasFreed: 1;
}

//if flag is NO, objects (values) will be yielded by -nextObject.
//otherwise, keys will be yielded.
- (id) initWithMapEnumerator:(NSMapEnumerator)newMapEnum enumerateKeys:(BOOL)flag;

@end

@implementation GrowlNonCopyingMutableDictionary

- (id) superInit {
	SEL init = @selector(init);
	//jump over superclasses (NSMutableDictionary and NSDictionary)
	return [[[super superclass] superclass] instanceMethodForSelector:init](self, init);
}

#pragma mark -

- (id) init {
	if ((self = [self superInit])) {
		backing = NSCreateMapTableWithZone(NSObjectMapKeyCallBacks, NSObjectMapValueCallBacks, 0U, [self zone]);
	}
	return self;
}

#pragma mark -

- (id) initWithCapacity:(unsigned)capacity {
	if ((self = [self superInit])) {
		backing = NSCreateMapTableWithZone(NSObjectMapKeyCallBacks, NSObjectMapValueCallBacks, capacity, [self zone]);
	}
	return self;
}

#pragma mark -

- (id) initWithDictionary:(NSDictionary *)other {
	NSParameterAssert(other != nil);
	if ((self = [self initWithCapacity:[other count]]))
		[self setDictionary:other];
	return self;
}

#pragma mark -

//more -init.. methods can go here.

//#pragma mark -

+ (id) dictionaryWithMapTable:(NSMapTable *)otherBacking {
	return [[[self alloc] initWithMapTable:otherBacking] autorelease];
}

- (id) initWithMapTable:(NSMapTable *)otherBacking {
	if ((self = [self superInit])) {
		backing = NSCopyMapTableWithZone(otherBacking, [self zone]);
	}
	return self;
}

#pragma mark -

- (void) dealloc {
	NSFreeMapTable(backing);

	[super dealloc];
}

#pragma mark -
#pragma mark Adding and changing values

- (id) objectForKey:(id)key {
	return NSMapGet(backing, key);
}

- (id) valueForKey:(NSString *)key {
	return [self objectForKey:key];
}

#pragma mark -

- (void) setObject:(id)obj forKey:(id)key {
	NSMapInsert(backing, key, obj);
}

- (void) setValue:(id)obj forKey:(NSString *)key {
	if (obj)
		NSMapInsert(backing, key, obj);
	else
		NSMapRemove(backing, key);
}

#pragma mark -

- (void) addEntriesFromDictionary:(NSDictionary *)other {
	NSParameterAssert(other);

	NSEnumerator *keyEnum = [other keyEnumerator];
	id key;
	while ((key = [keyEnum nextObject]))
		NSMapInsert(backing, key, [other objectForKey:key]);
}
- (void) setDictionary:(NSDictionary *)other {
	NSParameterAssert(other);

	[self removeAllObjects];
	[self addEntriesFromDictionary:other];
}

#pragma mark -
#pragma mark Removing values

- (void) removeObjectForKey:(id)key {
	NSMapRemove(backing, key);
}
- (void) removeObjectsForKeys:(NSArray *)keys {
	NSEnumerator *keyEnum = [keys objectEnumerator];
	id key;
	while((key = [keyEnum nextObject]))
		[self removeObjectForKey:key];
}

- (void) removeAllObjects {
	NSResetMapTable(backing);
}

#pragma mark -
#pragma mark Examination

- (NSArray *) allKeys {
	return NSAllMapTableKeys(backing);
}

- (NSArray *) allValues {
	return NSAllMapTableValues(backing);
}

- (NSEnumerator *) keyEnumerator {
	//enumerateKeys: YES
	return [[[GrowlNonCopyingDictionaryEnumerator allocWithZone:[self zone]] initWithMapEnumerator:NSEnumerateMapTable(backing) enumerateKeys:YES] autorelease];
}

- (NSEnumerator *) objectEnumerator {
	//enumerateKeys: NO
	return [[[GrowlNonCopyingDictionaryEnumerator allocWithZone:[self zone]] initWithMapEnumerator:NSEnumerateMapTable(backing) enumerateKeys:NO] autorelease];
}

#pragma mark -

- (unsigned) count {
	return NSCountMapTable(backing);
}

- (NSString *) description {
	NSMutableArray *elements = [[NSMutableArray alloc] initWithCapacity:[self count]];

	NSMapEnumerator backingEnum = NSEnumerateMapTable(backing);
	NSObject *key, *value;
	while(NSNextMapEnumeratorPair(&backingEnum, (void **)&key, (void **)&value)) {
		NSString *pairDesc = [[NSString alloc] initWithFormat:@"\t%@ = %@", [key description], [value description]];
		[elements addObject:pairDesc];
		[pairDesc release];
	}
	NSEndMapTableEnumeration(&backingEnum);

	NSString *desc = [[[NSString allocWithZone:[self zone]] initWithFormat:@"{\n%@}", [elements componentsJoinedByString:@";\n"]] autorelease];
	[elements release];
	return desc;
}

@end

#pragma mark -

@implementation GrowlNonCopyingDictionaryEnumerator

- (id) initWithMapEnumerator:(NSMapEnumerator)newMapEnum enumerateKeys:(BOOL)flag {
	if ((self = [super init])) {
		mapEnum = newMapEnum;
		yieldKeys = (flag != NO);
	}
	return self;
}

- (void) dealloc {
	if(!hasFreed)
		NSEndMapTableEnumeration(&mapEnum);

	[super dealloc];
}

#pragma mark -

- (id) nextObject {
	void *key, *value;
	if (!NSNextMapEnumeratorPair(&mapEnum, &key, &value)) {
		if (!hasFreed) {
			NSEndMapTableEnumeration(&mapEnum);
			hasFreed = YES;
		}
		return nil;
	} else if (yieldKeys)
		return key;
	else
		return value;
}

@end
