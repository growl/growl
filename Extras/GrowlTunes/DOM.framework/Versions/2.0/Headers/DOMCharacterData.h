/*
 * Iconara DOM framework: DOMCharacterData (created 26 August 2002)
 *
 * Release 1
 *
 * Copyright 2002-2003 Iconara/Theo Hultberg
 *
 *
 * This file is part of the Iconara DOM framework.
 *
 * Iconara DOM is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * Iconara DOM is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Iconara DOM; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 */

#import <Foundation/Foundation.h>
#import "DOMNode.h"


@protocol DOMCharacterData <DOMNode>

/*!
 * Returns the string of this object.
 */
- (NSString *)data;

/*!
 * Returns the string of this object without "ignorable whitespace".
 */
- (NSString *)dataIgnoreWhitespace:(BOOL)noWS;

/*!
 * Returns the length of this character data.
 */
- (unsigned)length;

/*!
 *
 */
- (NSString *)substringDataWithRange:(NSRange)range;

/*!
 * Sets the string of this object.
 */
- (void)setData:(NSString *)string;

/*!
 *
 */
- (void)appendData:(NSString *)data;

/*!
 * @param data     
 * @param offset   
 */
- (void)insertData:(NSString *)data atOffset:(int)offset;

/*!
 * @param range    
 */
- (void)deleteDataInRange:(NSRange)range;

/*!
 * @param range    
 * @param data     
 */
- (void)replaceDataInRange:(NSRange)range withData:(NSString *)data;

/*!
 * Trims whitespace from the begining and end and replaces all 
 * whitespace runs with a single space. 
 *
 * This means that tabs and newlines are also replaced by spaces.
 *
 * Rules:
 *     - If the data starts with a space, that space is kept.
 *     - If the data ends with whitespace, it will end in a single space.
 *     - If the data is nothing but whitespace, it will be empty.
 *
 * @result Returns true if the node was changed
 */
- (BOOL)normalizeWhitespace;

@end


/*!
 * Abstract superclass of DOMComment and DOMText.
 */
@interface DOMCharacterData : DOMNode <DOMCharacterData> {
	NSString *data;
}

/*!
 * Initializes with a string.
 */
- (id)initWithData:(NSString *)data;

@end


/*!
 * Defines some useful methods for handling whitespace.
 */
@interface DOMCharacterData ( WhitespaceUtilities )

/*!
 * See #normalizeWhitespace for explanation.
 */
+ (NSString *)whitespaceNormalizedDataOfNode:(id <DOMCharacterData>)string;

/*!
 * Replaces all whitespace runs with a single space
 */
+ (NSString *)implodeWhitespace:(NSString *)string;

@end
