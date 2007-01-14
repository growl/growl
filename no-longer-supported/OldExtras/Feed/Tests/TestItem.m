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

#import "TestItem.h"
#import "KNItem.h"

@implementation TestItem

-(void)testItemCreation{
	KNItem *			anItem = [[KNItem alloc] init];
	
	STAssertNotNil(anItem, @"Could not create Item instance");	
	[anItem release];
}

-(void)testItemUniquness{
	KNItem *						newItem = nil;
	NSMutableDictionary *		items = [NSMutableDictionary dictionary];
	unsigned					i;
	unsigned					crashes = 0;
	
	
	for( i=0;i<100000;i++){
		newItem = [[KNItem alloc] init];
		if( [items objectForKey: [newItem key]] ){
			crashes++;
		}
		[items setObject: newItem forKey: [newItem key]];
	}
	
	STAssertTrue( crashes == 0, [NSString stringWithFormat:@"Too many key crashes: %u", crashes] );
}

-(void)testItemAdd{
	KNItem *			anItem = [[KNItem alloc] init];
	KNItem *			anotherItem = [[KNItem alloc] init];
	
	[anItem addChild: anotherItem];
	[anotherItem release];
	
	STAssertEquals( [anItem childCount], (unsigned) 1, @"Adding item failed");
	
	STAssertThrows( [anItem addChild: nil], @"Adding nil child did not throw exception" );	
	STAssertThrows( [anItem addChild: [NSDictionary dictionary]], @"Adding non-Item class did not throw exception" );
	
	[anItem release];
}

-(void)testItemRemove{
	KNItem *			anItem = [[KNItem alloc] init];
	KNItem *			anotherItem = [[KNItem alloc] init];
	
	[anItem addChild: anotherItem];
	[anItem removeChildAtIndex: 0];
	
	STAssertEquals( [anItem childCount], (unsigned) 0, @"Removing item failed" );
	
	[anotherItem release];
	[anItem release];
}

-(void)testItemOutOfRange{
	KNItem *			anItem = [[KNItem alloc] init];
	
	STAssertTrue( [anItem lastChild] == nil , @"Calling lastChild on empty did not return nil" );
	STAssertTrue( [anItem firstChild] == nil , @"Calling firstChild on empty did not return nil" );
	STAssertTrue([anItem childAtIndex: 200] == nil, @"Requesting index 200 of empty did not return nil");
	STAssertTrue([anItem childAtIndex: -1] == nil, @"Requesting index -1 of empty did not return nil");
	
	[anItem release];
}

-(void)testItemCount{
	KNItem *			anItem = [[KNItem alloc] init];
	KNItem *			aChild = nil;
	unsigned		i = 0;
	
	for(i=0;i<10;i++){
		aChild = [[KNItem alloc] init];
		[anItem addChild: aChild];
		[aChild release];
	}
	STAssertEquals( [anItem childCount], (unsigned) 10, @"Adding 10 children failed");
	
	for(i=0;i<4;i++){
		[anItem removeChildAtIndex: 0];
	}
	STAssertEquals( [anItem childCount], (unsigned) 6, @"Removing 4 children failed");
	
	while( [anItem firstChild] ){
		[anItem removeChildAtIndex: 0];
	}
	STAssertEquals( [anItem childCount], (unsigned) 0, @"Removing all remaining children failed");
	
	[anItem release];
}


/* testItemEncoding
		Test round-trips through object encoding.	
*/
-(void)testArchiving{
	KNItem *					anItem1 = [[KNItem alloc] init];
	NSMutableData *			data1 = [NSMutableData data];
	NSKeyedArchiver *		archiver1 = [[NSKeyedArchiver alloc] initForWritingWithMutableData: data1];
	
	KNItem *					child1 = [[KNItem alloc] init];
	[anItem1 setName: @"Testing"];
	[anItem1 addChild: child1];
	
	[archiver1 encodeObject: anItem1 forKey:@"root"];
	[archiver1 finishEncoding];
	
	KNItem *					anItem2 = [NSKeyedUnarchiver unarchiveObjectWithData: data1];
	KNItem *					child2 = [anItem2 firstChild];
	
	STAssertEqualObjects( anItem1, anItem2, @"Item did not survive encoding");
	STAssertEqualObjects( [anItem1 name], [anItem2 name], @"Name did not survive encoding" );
	STAssertEqualObjects( child1, child2, @"Child objects did not survive encoding");
	
	[anItem1 release];
	[archiver1 release];
}

/* testSetName
		Make sure name attribute is settable and gettable
*/
-(void)testSetName{
	KNItem *					anItem = [[KNItem alloc] init];
	NSString *				name1 = @"Name1";
	
	/* basic setting */
	[anItem setName: name1];
	STAssertEqualObjects( [anItem name], name1, @"Item did not return same name" );
	
	/* setting nil */
	STAssertThrows([anItem setName: nil], @"Item did not throw exception on nil name");
	
	STAssertEqualObjects( [anItem name], name1, @"Item did not return same name after nil setting attempt" );
}

/* rearrangeChildren
	Make sure we can insert and rearrange children
*/
-(void)rearrangeChildren{
	KNItem *					anItem = [[KNItem alloc] init];
	KNItem *					child1 = [[KNItem alloc] init];
	KNItem *					child2 = [[KNItem alloc] init];
	KNItem *					child3 = [[KNItem alloc] init];
		
	[anItem addChild: child1];
	[anItem addChild: child2];
	
	[anItem insertChild: child3 atIndex: 1];
	STAssertEquals( [anItem indexOfChild: child2], (unsigned) 2, @"Inserting did not move existing child" );
	
	[anItem removeChildAtIndex: 1];
	STAssertEquals( [anItem indexOfChild: child2], (unsigned) 1, @"Removing did not move existing child" );
}

/* testEquality
	Make sure that isEqual is actually working
*/
-(void)testEquality{
	KNItem *					anItem = [[KNItem alloc] init];
	KNItem *					anotherItem = [[KNItem alloc] init];
	
	STAssertTrue( [anItem isEqual: anItem], @"isEqual against self didn't return true");
	STAssertFalse( [anItem isEqual: anotherItem], @"isEqual against different object returned true");
}

-(void)testItemKeyLookup{
	KNItem *				anItem = [[KNItem alloc] init];
	KNItem *				specialItem = [[KNItem alloc] init];
	NSString *			targetKey = [specialItem key];
	int					i;
	
	for(i=0;i<5;i++){
		KNItem *				newChild = [[KNItem alloc] init];
		[anItem addChild: newChild];
		[newChild release];
	}
	
	[[anItem childAtIndex:2] addChild: specialItem];
	
	STAssertEqualObjects( specialItem, [anItem itemForKey: targetKey ], @"Searching for item key didn't return correct child item");
	STAssertEqualObjects( [anItem key], [[anItem itemForKey:[anItem key]] key], @"Top-level key search failed");
}

@end
