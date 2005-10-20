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

#import <Cocoa/Cocoa.h>
#import "KNUtility.h"

#define FeedItemException @"FeedItemException"
#define FeedItemTypeItem @"Item"
#define FeedItemReleaseNotification @"FeedItemReleaseNotification"

#define ItemParent @"parent"
#define ItemChildren @"children"
#define ItemKey @"key"
#define ItemName @"name"
#define ItemPrefs @"prefs"

/*!
	@class Item
	@abstract Base class for all model objects in the library.
	@discussion An Item provides the base functionality common to all other object types. Every
		item has a unique key, a name, some number of children and a current child. Without having
		to subclass, this effectively provides the capabilities of a Folder.
*/
@interface KNItem : NSObject <NSCoding>{
	NSMutableArray *			children;
	NSString *					key;
	NSString *					name;
	NSMutableDictionary *		prefs;
	
	KNItem *						parent;
}

/*!
	@functiongroup Properties
*/

/*!
	@method key 
	@abstract Returns the unique key as generated at initialization.
*/
-(NSString *)key;

/*!
	@method type
	@abstract Returns the type of item. 
	@discussion Subclasses must override this to return an appropriate type. The
				default type is FeedItemType.
*/
-(NSString *)type;

/*!
	@method canHaveChildren
	@abstract Returns whether this item is allowed to have children.
	@discussion The default implementation returns	
			YES. Subclasses must override this method to disable children. The addChild: and 
			insertChild:atIndex: methods check the result of this method and throw FeedItemException 
			if it returns NO.
*/
-(BOOL)canHaveChildren;

-(void)setParent:(KNItem *)anItem;
-(KNItem *)parent;


/*!
	@method name 
	@abstract Returns the current name of the Item.
	@result Returns the current name of the Item.
*/
-(NSString *)name;

/*!
	@method setName:
	@abstract Sets the current name of the Item.
	@param aName A string specifying the new name. This method will throw a FeedItemException if aName is nil.
*/
-(void)setName:(NSString *)aName;

/*!
	@method isEqualToItem:
	@param anItem The item to compare against
	@abstract Test to see if items are equal.
	@discussion Equality of items is determined by their keys. If the keys are the same, then two items
			are considered equal.
*/
-(BOOL)isEqualToItem:(KNItem *)anItem;

/*!
	@method itemForKey:
	@param aKey The key of the item to return
	@abstract Finds the item represented by aKey
	@discussion In order to support locating objects by key, this method will return self if it matches
				or will descend through it's children looking for a match. Returns nil if not found.
*/
-(KNItem *)itemForKey:(NSString *)aKey;

/*!
	@method allChildrenOfType:
	@param aType The type of child to return
	@abstract Finds all children of the desired type recursively (including self)
*/
-(NSArray *)itemsOfType:(NSString *)aType;
-(NSSet *)uniqueItemsOfType:(NSString *)aType;
-(NSArray *)itemsWithProperty:(NSString *)keyPath equalTo:(id)otherObject;

/*!
	@method unreadCount
	@abstract Returns the unread count of this item including all children
*/
-(unsigned)unreadCount;

/*!
	@functiongroup Child Management
*/

/*!
	@method addChild:
	@abstract Appends aChild to the end of the list of children.
	@param aChild An Item object to add as a child. Throws FeedItemException if aChild is nil.
*/
-(void)addChild:(KNItem *)aChild;

/*!
	@method insertChild:atIndex:
	@abstract Inserts an item into the list of children at a specified index.
	@discussion When the requested index of the child is equal to the number of children already 
				in the list, the child is appended to the list (emulating addChild).
	@param aChild An Item object to insert as a child. Throws FeedItemException if aChild is nil.
	@param anIndex The location in the list of children to insert. Throws FeedItemException if anIndex is out of range
*/
-(void)insertChild:(KNItem *)aChild atIndex:(unsigned)anIndex;

/*!
	@method removeChild:(Item *)aChild
	@abstract Removes a child from the list of children.
*/
-(void)removeChild:(KNItem *)aChild;

/*!
	@method removeChildAtIndex:
	@abstract Removes child at the requested index.
	@param anIndex The index of the child to remove. Throws FeedItemException if anIndex is out of range.
*/
-(void)removeChildAtIndex:(unsigned)anIndex;

/*!
	@method childAtIndex:
	@abstract Returns the child item at the requested index.
	@param anIndex The index of the child to return.
	@result Returns the requested child item or nil if anIndex is out of range.
*/
-(KNItem *)childAtIndex:(unsigned)anIndex;

/*!
	@method indexOfChild:
	@abstract Returns index in the list of children of the specified item
	@param aChild The item to look for
	@result Returns the index of the specified child item or NSNotFound if child is not in the list of children.
*/
-(unsigned)indexOfChild:(KNItem *)aChild;

/*!
	@method childCount
	@abstract Returns the number of children in the list.
*/
-(unsigned)childCount;

/*!
	@method firstChild
	@abstract Returns the first child in the list of children or nil if there are no children.
*/
-(KNItem *)firstChild;

/*!
	@method lastChild
	@abstract Returns the last child in the list of children or nil if there are no children.
*/
-(KNItem *)lastChild;

@end

void ItemThrow(NSString *aString);

