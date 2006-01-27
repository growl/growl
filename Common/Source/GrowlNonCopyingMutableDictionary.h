//
//	GrowlNonCopyingMutableDictionary.h
//	Growl
//
//	Created by Mac-arena the Bored Zo on 2005-08-21.
//	Copyright 2005-2006 The Growl Project. All rights reserved.
//
//	This file is under the BSD License, refer to License.txt for details

#import <Foundation/Foundation.h>

@interface GrowlNonCopyingMutableDictionary: NSMutableDictionary
{
	NSMapTable *backing;
}

+ (id) dictionaryWithMapTable:(NSMapTable *)otherBacking;

- (id) initWithMapTable:(NSMapTable *)otherBacking;

@end
