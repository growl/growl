/*
 * Iconara DOM framework: DOMNode (created 27 April 2002)
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
#import "DOMVisitor.h"


/*!
 * Defines constants that can be used to identify the type
 * of a node. Used in the method #nodeType of DOMNode.
 */
typedef enum {
	DOMUnknownNodeType                = -1,
	DOMElementNodeType                = 1,
	DOMAttributeNodeType              = 2,
	DOMTextNodeType                   = 3,
	DOMCDATASectionNodeType           = 4,
	DOMEntityReferenceNodeType        = 5,
	DOMEntityNodeType                 = 6,
	DOMProcessingInstructionNodeType  = 7,
	DOMCommentNodeType                = 8,
	DOMDocumentNodeType               = 9,
	DOMDocTypeNodeType                = 10,
	DOMDocumentFragmentNodeType       = 11,
	DOMNotationNodeType               = 12
} DOMNodeType;


@protocol DOMNode, DOMDocument, DOMElement, DOMParent;


/*!
 * The DOMNode protocol defines the common interface of all nodes
 * A node can, for example, be an element, a comment or a 
 * processing instruction.
 *
 * One may ask why there is a protocol named DOMNode and a class
 * with the same name. The reason is to increase the extensibility
 * of the framework.
 *
 * The thought is that when adding new node types, or extensions
 * of existing node types one should not be forced to extend by
 * inheritance (which would be bad design since it couples the
 * extension to tightly to the existing framework).
 *
 * The DOMNode class is a convenience class for internal use
 * within the framework. A class that extends the framework
 * should conform to the DOMNode protocol, or to the DOMParent
 * protocol if the extension is a parent type. Should that
 * extension not want to reimplement the same logic as the
 * concrete class, it's OK to delegate that responsibility
 * to an instance of that class -- just don't inherit from it!
 * 
 */
@protocol DOMNode <NSObject>

/*!
 * Returns the name of this node.
 *
 * The name and value of a node varies accordning to the table below:
 *
 * @code
 *     Node type		name					value
 *     ------------------------------------------------------------
 *     Attribute		name of attribute		value
 *     CDATASection		"#cdata-section"		content
 *     Comment			"#comment"				content
 *     Document			"#document"				nil
 *     DocumentFragment	"#document-fragment" 	nil
 *     DocumentType 	document type name		nil
 *     Element 			tag name				nil
 *     PI 				target					content, w/o target
 *     Text 			"#text" 				content
 *     ------------------------------------------------------------
 * @endcode
 *
 */
- (NSString *)nodeName;

/*!
 * Returns the value of this node.
 *
 * The name and value of a node varies accordning
 * to the type, see the table in the documentation
 * of #name: for more information.
 */
- (NSString *)nodeValue;

/*!
 */
- (DOMNodeType)nodeType;

/*!
 * Returns the parent of this node or nil, if the node has no parent.
 */
- (id <DOMParent, DOMNode>)parentNode;

/*!
 * Sets the parent of this node.
 *
 * It's your responsibility to make sure that the node
 * is added to the new parent, it is not done automatically.
 *
 * Please note that in order to prevent retain-cycles 
 * the node does NOT retain the parent.
 *
 */
- (void)setParentNode:(id <DOMParent, DOMNode>)newParent;

/*!
 * Returns the document this node is placed in or nil, if the 
 * node is not part of a document.
 *
 * A node is considered part of a document if it's parent is part
 * of that document, of the parent is that document.
 *
 */
- (id <DOMDocument>)ownerDocument;

/*!
 * Detaches this tag from it's parent.
 *
 * A detached tag belongs to no parent and no document, it is free.
 *
 * When detached, the tag removes itself from it's
 * parent's list of children, and removes the reference to 
 * it's parent.
 *
 * A document node or document fragment can never be detached.
 *
 * @result Returns the node itself.
 */
- (id <DOMNode>)detach;

/*!
 * Returns whether or not this method is detached.
 *
 * Returns YES if this tag has no parent and NO otherwise.
 *
 * A document or document fragment is never detached.
 *
 * @result YES if detached, NO otherwise
 */
- (BOOL)isDetached;

/*!
 * Returns YES if this node has child nodes.
 */
- (BOOL)hasChildren;

/*!
 * Returns the node before this node in the node's parent's list of children, 
 * or nil if this node is the first.
 */
- (id <DOMNode>)previousSibling;

/*!
 * Returns the node after this node in the node's parent's list of children, 
 * or nil if this node is the last
 */
 - (id <DOMNode>)nextSibling;
 
/*!
 * Returns the text contained by this node.
 *
 * The result of this method depends on the node type, see table below:
 *
 * @code
 *     Node type            textContent
 *     ------------------------------------------------------------
 *     Attribute            same as -value
 *     CDATASection         same as -value
 *     Comment              same as -value
 *     Text                 same as -value
 *     PI                   same as -value
 *     DocumentFragment     concatenation of textContent of all 
 *       & Element            children, excluding comments and pi's
 *     DocumentType         nil
 *     Document             nil
 *     ------------------------------------------------------------
 * @endcode
 *
 */
- (NSString *)textContent;
 
/*!
 * Sets the text contained by this node.
 *
 * The result of this method depends on the node type, see table below:
 *
 * @code
 *     Node type            setTextContent
 *     ------------------------------------------------------------
 *     Attribute            same as -setValue
 *     CDATASection         same as -setData
 *     Comment              same as -setData
 *     Text                 same as -setData
 *     PI                   same as -setDataString
 *     DocumentFragment     all children are removed and replaced by
 *       & Elemenet           a single text node
 *     DocumentType         no effect
 *     Document             no effect
 *     ------------------------------------------------------------
 * @endcode
 *
 */
- (void)setTextContent:(NSString *)text;

/*
 * Returns a reference to the namespace manager for this node.
 *
- (id)namespaceManager;
 */


/*!
 * Checks for equality, as defined by being of the same node type 
 * and having the same properties.
 *
 * The implementation of this method depends heavily
 * on which type of node it is, it can be very expensive
 * when the node is a parent since it checks for equality
 * recursively. See NSArray's -isEqualToArray for more information.
 *
 * When comparing text nodes, CDATA sections and comments, ignorable
 * whitespace is ignored. Ignoreable whitespace is, in this framework,
 * defined as the characters in the set 
 * [NSCharacterSet whitespaceAndNewlineCharacterSet].
 */
- (BOOL)isEqualToNode:(id <DOMNode>)node;

@end


/*!
 * Abstract superclass to all nodes in the framework.
 */
@interface DOMNode : NSObject <DOMNode, DOMVisitable, NSCopying> {
	@private
		id <DOMParent, DOMNode> parent;
}

@end
