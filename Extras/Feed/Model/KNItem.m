/*

BSD License

Copyright (c) 2005, Keith Anderson
All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

*	Redistributions of source code must retain the above copyright notice,
	this list of conditions and the following disclaimer.
*	Redistributions in binary form must reproduce the above copyright notice,
	this list of conditions and the following disclaimer in the documentation
	and/or other materials provided with the distribution.
*	Neither the name of keeto.net or Keith Anderson nor the names of its
	contributors may be used to endorse or promote products derived
	from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS
BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


*/

#import "KNItem.h"
#import "KNUtility.h"
#import "Library.h"


#define UNIQUEKEYLENGTH 25
void ItemThrow(NSString *aString){
	[NSException raise: FeedItemException format:aString];
}


@implementation KNItem


-(id)init{
	if( (self = [super init]) ){
		parent = nil;
		key = [KNUniqueKeyWithLength(UNIQUEKEYLENGTH) retain];
		children = [[NSMutableArray array] retain];
		name = [[NSString stringWithString: key] retain];
		prefs = [[NSMutableDictionary alloc] init];
	}
	return self;
}

-(id)initWithCoder:(NSCoder *)aCoder{
	if( (self = [super init]) ){
		parent = [aCoder decodeObjectForKey: ItemParent];
		children = [[aCoder decodeObjectForKey: ItemChildren] retain];
		key = [[aCoder decodeObjectForKey: ItemKey] retain];
		name = [[aCoder decodeObjectForKey: ItemName] retain];
		prefs = [[aCoder decodeObjectForKey: ItemPrefs] retain];
	}
	return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder{
	[aCoder encodeObject: parent forKey: ItemParent];
	[aCoder encodeObject: children forKey: ItemChildren];
	[aCoder encodeObject: key forKey: ItemKey];
	[aCoder encodeObject: name forKey: ItemName];
	[aCoder encodeObject: prefs forKey: ItemPrefs];
}

-(void)dealloc{
	KNDebug(@"%@ dealloc", [self class]);
	[key release];
	[children release];
	[name release];
	[prefs release];
	
	[super dealloc];
}

-(NSString *)description{
	return [NSString stringWithFormat: @"<%@:%@>",[self type], ([[self name] isEqualToString:@""] ? [self key] : [self name])];
}

-(id)valueForUndefinedKey:(NSString *)aKey{
#pragma unused( aKey )
	//KNDebug(@"Returning nil in %@ for undefined key: %@", [self class], aKey);
	return nil;
}

-(BOOL)isEqual:(id)other{
	if( other == self ){
		return YES;
	}
	if( !other || ![other isKindOfClass: [self class]] ){
		return NO;
	}
	return [self isEqualToItem: other];
}

-(unsigned)hash{
	return [key hash];
}

-(BOOL)isEqualToItem:(KNItem *)anItem{
	if( self == anItem ){
		return YES;
	}
	return [[self key] isEqualToString: [anItem key]];
}

-(KNItem *)itemForKey:(NSString *)aKey{
	KNItem *					foundItem = nil;
	
	if( [aKey isEqualToString: key] ){
		return self;
	}else{	
		unsigned					i;
		for(i=0;i<[self childCount];i++){
			foundItem = [[self childAtIndex:i] itemForKey: aKey];
			if( foundItem ){ break; }
		}
	}
	return foundItem;
}

-(NSArray *)itemsOfType:(NSString *)aType{
	NSMutableArray *				results = [NSMutableArray array];
	unsigned						i;
	
	if( [[self type] isEqualToString: aType] ){
		[results addObject: self];
	}
	
	for(i=0;i<[self childCount];i++){
		[results addObjectsFromArray: [[self childAtIndex:i] itemsOfType: aType]];
	}
	
	return results;
}

-(NSSet *)uniqueItemsOfType:(NSString *)aType{
	NSMutableSet *					results = [NSMutableSet set];
	unsigned						i;
	
	if( [[self type] isEqualToString: aType] ){
		[results addObject: self];
	}
	
	for(i=0;i<[self childCount];i++){
		[results unionSet: [[self childAtIndex:i] uniqueItemsOfType: aType]];
	}
	
	return results;
}

-(NSArray *)itemsWithProperty:(NSString *)keyPath equalTo:(id)otherObject{
	NSMutableArray *				results = [NSMutableArray array];
	unsigned						i;
	
	if( [[self valueForKeyPath:keyPath] isEqual: otherObject] ){
		[results addObject: self];
	}
	
	for(i=0;i<[self childCount];i++){
		if( [[[self childAtIndex:i] valueForKeyPath:keyPath] isEqual: otherObject] ){
			[results addObject: [self childAtIndex: i]];
		}
	}
	return results;
}

-(unsigned)unreadCount{
	unsigned						count = 0;
	unsigned						i;
	
	for(i=0;i<[self childCount];i++){
		count += [[self childAtIndex:i] unreadCount];
	}
	
	return count;
}

#pragma mark -
#pragma mark Properties

-(NSString *)key{
	return key;
}


-(void)setName:(NSString *)aName{
	if( aName ){
		[name autorelease];
		name = [aName retain];
		[LIB makeDirty];
	}else{
		ItemThrow(@"Can't set nil name in Item");
	}
}

-(NSString *)name{
	return name;
}

-(NSString *)type{
	return FeedItemTypeItem;
}

-(BOOL)canHaveChildren{
	return YES;
}

-(void)setParent:(KNItem *)anItem{
	parent = anItem;
}

-(KNItem *)parent{
	return parent;
}

#pragma mark -
#pragma mark Child Management

-(void)addChild:(KNItem *)aChild{
	if( ! [self canHaveChildren] ){ ItemThrow(@"Attempt to add child to barren item"); }
	
	if( aChild ){
		if( [aChild isKindOfClass:[KNItem class]] ){
			[aChild setParent: self];
			[children addObject: aChild];
			[LIB makeDirty];
		}else{
			ItemThrow([NSString stringWithFormat:@"Only Items are allowed as children (%@ vs %@)", [aChild class], [KNItem class]]);
		}
	}else{
		ItemThrow(@"Can't add nil child to Item");
	}
}

-(void)insertChild:(KNItem *)aChild atIndex:(unsigned)anIndex{
	if( ! [self canHaveChildren] ){ ItemThrow(@"Attempt to add child to barren item"); }
	
	if( (anIndex <= [children count]) ){
		if( aChild ){
			[aChild setParent: self];
			if( anIndex == [children count] ){
				[self addChild: aChild];
			}else{
				[children insertObject: aChild atIndex: anIndex];
			}
			[LIB makeDirty];
		}else{
			ItemThrow(@"Can't insert nil child in Item");
		}
	}else{
		ItemThrow(@"Attempt to insert child out of range");
	}
}

-(void)removeChild:(KNItem *)aChild{
	if( [self indexOfChild: aChild] != NSNotFound ){
		[self removeChildAtIndex: [self indexOfChild: aChild]];
		[LIB makeDirty];
	}
}

-(void)removeChildAtIndex:(unsigned)anIndex{
	if(anIndex < [children count]){
		[[children objectAtIndex:anIndex] setParent: nil];
		[children removeObjectAtIndex: anIndex];
		[LIB makeDirty];
	}else{
		ItemThrow(@"Attempt to remove child out of range");
	}
}

-(KNItem *)childAtIndex:(unsigned)anIndex{
	KNItem *					aChild = nil;
	
	if( anIndex < [children count] ){
		aChild = [children objectAtIndex: anIndex];
	}
	return aChild;
}

-(unsigned)indexOfChild:(KNItem *)aChild{
	unsigned				anIndex = NSNotFound;
	
	if( aChild ){
		anIndex = [children indexOfObject: aChild];
	}
	
	return anIndex;
}

-(unsigned)childCount{
	return [children count];
}

-(KNItem *)firstChild{
	KNItem *				anItem = nil;
	
	if( [self childCount] > 0 ){
		anItem = [children objectAtIndex: 0];
	}
	return anItem;
}

-(KNItem *)lastChild{
	return [children lastObject];
}

@end
