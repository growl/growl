/*
 * Iconara DOM framework: DOMAttribute (created 5 May 2002)
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
#import "DOMNamespaceAware.h"


@protocol DOMElement;


/*!
 * Represents an attribute with a value within a XML-document tag.
 *
 * An attribute is a key-value string (\<element key="value"/\>).
 *
 * Only DOMElements can contain attributes.
 *
 * There is no need to create attribute objects yourself. To add
 * attributes to an element, use DOMElement#setAttributeNamed:value: on an 
 * element node. You can then get a reference to the attribute 
 * object by using the DOMElement#attributeNamed: method, or get it's value 
 * directly with DOMElement#valueOfAttributeNamed:.
 *
 * A word on namespaces: an attribute cannot have a prefix without
 * being in a namespace (having a namespace URI). The methods
 * #setName: and #setNamespaceURI:prefix: will raise exceptions
 * if you try to set a name containing a colon or set a prefix
 * without first having put the attribute in the namespace.
 *
 */
@protocol DOMAttribute <DOMNode, DOMNamespaceAware>

/*!
 * Returns the qualified name of the attribute.
 * 
 * The qualified name is the namespace prefix (if any) a colon and the local,
 * name (iconara:book for example).
 */
- (NSString *)name;

/*!
 * Returns the local name of the attribute
 */
- (NSString *)localName;

/*!
 * Sets the name of this attribute.
 *
 * @exception DOMNamespaceException
 *     Raised if the name matches "xmlns" in any variation of case,
 *     "xmlns" is a reserved name.
 */
- (void)setName:(NSString *)name;

/*!
 * Returns the value of the attribute.
 */
- (NSString *)value;

/*!
 * Sets the value of this attribute.
 */
- (void)setValue:(NSString *)value;

/*!
 * Returns the element containing this attribute.
 */
- (id <DOMElement>)ownerElement;

/*!
 * Whether or not this attribute is an ID attribute.
 * To set this node as an ID attribute, use it's parent's DOMElement#setIdAttributeNamed:.
 */
- (BOOL)isId;

/*!
 * Sets the isId flag of this attribute. See #isId.
 */
- (void)setIsId:(BOOL)state;

@end


@interface DOMAttribute : DOMNode <DOMAttribute> {
	@private
		NSString *localName;
		NSString *prefix;
		NSString *value;
		NSString *namespaceURI;
	
		BOOL isId;
}

/*!
 * Returns an autoreleased initialized attribute with a name and a value string.
 *
 * @exception DOMNamespaceException See #setName:
 */
+ (id <DOMAttribute>)attributeWithName:(NSString *)name value:(NSString *)value;

/*!
 * @exception DOMNamespaceException See #setName: and #setNamespaceURI:prefix:
 */
+ (id <DOMAttribute>)attributeWithName:(NSString *)theName value:(NSString *)theValue namespaceURI:(NSString *)namespaceURI prefix:(NSString *)prefix;

/*!
 * Returns an newly initialized attribute with a name and a value.
 *
 * @exception DOMNamespaceException See #setName:
 */
- (id)initWithName:(NSString *)name value:(NSString *)value;

/*!
 * @exception DOMNamespaceException See #setName: and #setNamespaceURI:prefix:
 */
- (id)initWithName:(NSString *)name value:(NSString *)value namespaceURI:(NSString *)namespaceURI prefix:(NSString *)prefix;

@end