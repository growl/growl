/*
 * Iconara DOM framework: DOMText (created 5 May 2002)
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
#import "DOMCharacterData.h"
#import "DOMParentNode.h"


/*!
 * Represents a text node in an XML-document.
 */
@protocol DOMText <NSObject, DOMCharacterData>

/*!
 * "Breaks this node into two nodes at the specified offset,
 * keeping both in the tree as siblings."
 *
 * If the offset is equal to the length of this text, a new
 * empty node is created.
 *
 * @exception DOMIndexSizeException 
 *     Raises DOMIndexSizeException  if offset is negative
 *
 * @exception DOMIndexSizeException 
 *     Raises DOMIndexSizeException if the offset is beyond the 
 *     bounds of the text
 *
 * @returns The new text node
 */
- (id <DOMText>)splitTextAtOffset:(int)offset;

/*!
 * "Returns whether this text node contains whitespace in
 * element content, often abusively called 'ignorable whitespace'."
 *
 * Returns true if the node only contains characters in the
 * set returned by [NSCharacterSet whitespaceAndNewlineCharacterSet].
 *
 */
- (BOOL)isWhitespaceInElementContent;

/*!
 * "Substitutes the specified text for the text of the current
 * node and all logically-adjacent text nodes."
 *
 * All logically-adjacent text are removed save for the one
 * recieving the replacement text.
 *
 * @returns The node that recieved the replacement text.
 */
- (id <DOMText>)replaceWholeText:(NSString *)string;

/*!
 * "Returns all text of text nodes logically adjacent to this
 * node in document order."
 *
 * Logically adjacent text nodes are nodes that can be visited
 * in document order without passing, entering or exiting
 * other node types than text and cdata sections.
 */
- (NSString *)wholeText;

@end


@interface DOMText : DOMCharacterData <DOMText> { }

+ (id <DOMText>)textWithString:(NSString *)string;

@end
