/*
 * Iconara DOM framework: DOMParentNode (created 11 December 2002)
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
 * Common interface for nodes that can contain other nodes.
 */
@protocol DOMParent <NSObject>

/*!
 * Returns an array of all children. The array is not live, i.e. it
 * does not update it's contents when new nodes are added or removed.
 */
- (NSArray *)children;

/*!
 * Returns the first child of this node.
 */
- (id <DOMNode>)firstChild;

/*!
 * Returns the last child of this node.
 */
- (id <DOMNode>)lastChild;

/*!
 * Returns YES if this parent contains child. Equality is checked
 * by #isEqual, not #isEqualToNode.
 */
- (BOOL)containsChild:(id <DOMNode>)child;

/*!
 * Adds a node as a child to this element.
 *
 * The node is detached before it is added which
 * means that if it was a child of another element
 * or document, it will be removed from that element
 * or document and added as a child to this.
 * If the node is already a child of this parent
 * it will also be detached and inserted last.
 *
 * These are the rules on which nodes can contain which:
 *
 *     - DOMDocument cannot contain text, CDATA 
 *       or attribute nodes.
 *
 *     - DOMDocument can only contain one 
 *       doctype node, and only one element node, 
 *       if a new is appended the previous will 
 *       be removed.
 *
 *     - DOMElement cannot contain doctype nodes.
 *
 *     - No parent node can contain DOMDocument nodes
 *       nor attribute nodes (elements contain attributes
 *       separately from other nodes)
 *
 * There are also rules on which order nodes can be
 * contained in a document (more to come):
 *
 *     - The doctype cannot come after the root element
 *
 * @exception NSInvalidArgumentException
 *     Will raise a NSInvalidArgumentException if a 
 *     node of the wrong type is added to this node.
 *
 * @param child The tag to add
 * @returns The appended node
 */
- (id <DOMNode>)appendChild:(id <DOMNode>)child;

/*!
 * Adds all children in an array.
 *
 * Calls -appendChild: repeatedly, which is not the
 * most efficient way to do it, but it'll do for now.
 */
- (void)appendChildren:(NSArray *)children;

/*!
 * Inserts a new node after the specified node.
 *
 * The new node is detached before it's added,
 * which means that if it's already a child
 * of this node, this will still work
 *
 * @exception NSInvalidArgumentException
 *     Will raise a NSInvalidArgumentException if a 
 *     node of the wrong type is added to this node.
 *     See #appendNode: for rules on which nodes 
 *     can contain which.
 *
 * @exception 
 *     Will raise an  NSInvalidArgumentException if
 *     the before-node is not a child of this node.
 *
 * @returns The inserted node
 */
- (id <DOMNode>)insertChild:(id <DOMNode>)child after:(id <DOMNode>)node;

/*!
 * Inserts a new node after the specified node.
 *
 * The new node is detached before it's added,
 * which means that if it's already a child
 * of this node, this will still work.
 *
 * @exception
 *     Will raise an NSInvalidArgumentException if a 
 *     node of the wrong type is added to this node.
 *     See #appendNode: for rules on which nodes 
 *     can contain which.
 *
 * @exception 
 *     Will raise an  NSInvalidArgumentException if
 *     the before-node is not a child of this node.
 *
 * @returns The inserted node
 */
- (id <DOMNode>)insertChild:(id <DOMNode>)child before:(id <DOMNode>)other;

/*!
 * Removes the specified node from the list of children.
 *
 *
 * @returns The removed node or nil if no node was removed
 */
- (id <DOMNode>)removeChild:(id <DOMNode>)child;

/*!
 * Removes all children from this parent.
 * 
 * Calls #removeChild: repeatedly.
 */
- (void)removeAllChildren;

/*!
 * Replaces a child with another node.
 *
 * The replaced child is detached and released.
 *
 * @exception NSInvalidArgumentException
 *     Will raise a NSInvalidArgumentException if a 
 *     node of the wrong type is added to this node.
 *     See #appendNode: for rules on which nodes 
 *     can contain which.
 *
 * @returns The replaced node
 */
- (id <DOMNode>)replaceChild:(id <DOMNode>)child withNode:(id <DOMNode>)other;

/*!
 * If there is a child of this document that has the specified ID, 
 * that element is returned,  otherwise nil.
 *
 * Since this framework has no idea of what actually
 * is an ID attribute, and what isn't, this method
 * is not correct. What it does it that it finds a
 * child node that has an attribute that returns 
 * yes from -isId. The implementation of that method
 * just assumes that any attribute named "id" (higher
 * or lowercase, or mixed) is an id-attribute.
 *
 * The implementation first gets all elements in the
 * tree below this node by calling #getElementsByTagName:\@"*"
 * and then searching this list until it finds an
 * element with an id-attribute with the specified value.
 *
 * A future implementation of this method will perform
 * a recursive traversal instead, which may be more efficient.
 *
 */
- (id <DOMElement>)childElementById:(NSString *)ID;

/*!
 * Searches the subtree at this node for any elements
 * with a specified name (local name) and returns these.
 *
 * If tagname is "*", returns all elements.
 */
- (NSArray *)childElementsByTagName:(NSString *)tagname;

/*!
 * Searches the subtree at this node for any elements
 * with a specified name (local name) in a specified namespace
 * and returns these.
 *
 * If tagname is "*", returns all elements.
 */
- (NSArray *)childElementsByTagName:(NSString *)tagname inNamespace:(NSString *)namespaceURI;

@end


/*!
 * DOMParent is a concrete implementation of the DOMParent protocol
 */
@interface DOMParent : DOMNode <DOMParent> {
	NSMutableArray *children;
}

@end

/*!
 * Protected methods, do no use
 */
@interface DOMParent ( ProtectedMethods )

- (id <DOMNode>)insertChild:(id <DOMNode>)node atIndex:(int)index;

- (BOOL)isValidChild:(id <DOMNode>)node;

@end
