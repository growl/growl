/*
 * Iconara DOM framework: DOMNamespaceAware (created 14 June 2004)
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


/*!
 * Nodes that are aware of namespaces should conform to this protocol.
 *
 * Namespace-aware nodes are elements and attributes by default.
 */
@protocol DOMNamespaceAware

/*!
 * Sets the namespace of this node.
 *
 * Pass nil or the empty string as URI to unset the namespace. 
 * Pass nil or the empty string as prefix to remove the prefix.
 * 
 * A node cannot have a prefix without having a namespace URI, it can,
 * however, have an URI without having a prefix.
 *
 * @exception DOMNamespaceException
 *     Raised if the URI is nil or the empty string and the prefix is not.
 *     Also raised if the prefix has previously been associated with 
 *     another namespace URI.
 *     Also raised if the prefix is reserved (e.g attributes with prefix "xmlns" ).
 *
 */
- (void)setNamespaceURI:(NSString *)namespaceURI prefix:(NSString *)prefix;

/*!
 * Returns the namespace of this node, or nil if the node is not in a namespace.
 */
- (NSString *)namespaceURI;

/*!
 * Returns the prefix of this node, or nil if the node has no prefix.
 */
- (NSString *)namespacePrefix;

@end
