/*
 * Iconara DOM framework: DOMElement (created 27 April 2002)
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
 
/*
 * TODO:
 * - DOM compliance & nice: normalize
 */

#import <Foundation/Foundation.h>
#import "DOMParentNode.h";
#import "DOMNamespaceAware.h"


@protocol DOMAttribute;


/*!
 * Represents an element (\<elementname\>\</elementname\>) in an XML-document.
 *
 * An element cannot contain a doctype node, any attempt
 * to add one will result in an exception being raised.
 *
 * A word on namespaces: an attribute cannot have a prefix without
 * being in a namespace (having a namespace URI). The methods
 * #setName: and #setNamespaceURI:prefix: will raise exceptions
 * if you try to set a name containing a colon or set a prefix
 * without first having put the attribute in the namespace.
 *
 */
@protocol DOMElement <DOMParent, DOMNode, DOMNamespaceAware>

/*!
 * The qualified name of this node.
 *
 * The qualified name is the namespace prefix (if any)
 * a colon and the local name (iconara:book for example).
 */
- (NSString *)name;

/*!
 * The same as #name:
 */
- (NSString *)tagName;

/*!
 * Returns the local name of the element.
 */
- (NSString *)localName;

/*!
 * Sets the name of this element.
 *
 * If the name includes a namespace prefix, that prefix is
 * looked up and set as the namespace of this element, 
 * discarding any previous namespace.
 */
- (void)setName:(NSString *)name;

/*!
 * Adds a new attribute to the list of attributes.
 */
- (void)setAttributeNamed:(NSString *)name value:(NSString *)value;

/*!
 * Adds a new attribute to the list of attributes, the attribute is placed
 * in the specified namespace. Pass nil or the empty string as URI for no namespace.
 * 
 * If the attribute is placed in a namespace, it must have a prefix.
 *
 * If there is a prefix, there must be a valid namespace URI.
 *
 * @exception NSInvalidArgumentException
 *     If namespace URI is nil or empty, and the prefix is not nil or empty
 *
 * @exception DOMNamespaceException
 *     Raised if there is a namespace URI, but no prefix or
 *     if the name contains a prefix, but the namespace URI is invalid
 */
- (void)setAttributeNamed:(NSString *)localName value:(NSString *)value inNamespace:(NSString *)namespaceURI prefix:(NSString *)prefix;

/*!
 * Mark the attribute named as a user defined ID attribute.
 *
 * @exception DOMNotFoundException 
 *     Raises a DOMNotFoundException if the named attribute
 *     is not a child of this element
 */
- (void)setIdAttributeNamed:(NSString *)name;

/*!
 * Mark the attribute named as a user defined ID attribute. 
 * Works exactly as #setIdAttribute:, but looks only for attributes
 * in the specified namespace.
 *
 * @exception DOMNotFoundException 
 *     Raises a DOMNotFoundException if the named attribute
 *     is not a child of this element
 */
- (void)setIdAttributeNamed:(NSString *)localName inNamespace:(NSString *)namespaceURI prefix:(NSString *)prefix;
 
/*!
 * Returns the attribute with the specified name.
 */
- (id <DOMAttribute>)attributeNamed:(NSString *)name;

/*!
 * Returns the attribute with the specified name, in the specified namespace.
 *
 * @exception NSInvalidArgumentException
 *     If namespace URI is nil or empty, and the prefix is not nil or empty
 */
- (id <DOMAttribute>)attributeNamed:(NSString *)localName inNamespace:(NSString *)namespaceURI prefix:(NSString *)prefix;

/*!
 * Convenience method identical to [[element attributeNamed:name] value].
 *
 * Available only as a sort of DOM-compliance, but with a proper name 
 * (not the DOM version: getAttribute()).
 */
- (NSString *)valueOfAttributeNamed:(NSString *)name;

/*!
 * See #valueOfAttributeNamed:.
 */
- (NSString *)valueOfAttributeNamed:(NSString *)localName inNamespace:(NSString *)namespaceURI prefix:(NSString *)prefix;

/*!
 * Removes an attribute by it's name.
 */
- (void)removeAttributeNamed:(NSString *)name;

/*!
 * Remove an attribute by name and namespace.
 */
- (void)removeAttributeNamed:(NSString *)localName inNamespace:(NSString *)namespaceURI prefix:(NSString *)prefix;

/*!
 * Returns a dictionary of all attributes of this element
 * with the qualified name of the attribute as key.
 */
- (NSDictionary *)attributes;

/*!
 * Returns YES if this element has an attribute with the specified name.
 */
- (BOOL)hasAttributeNamed:(NSString *)name;

/*!
 * Returns YES if this element has an attribute with the specified name in
 * the specified namespace.
 */
- (BOOL)hasAttributeNamed:(NSString *)aLocalName inNamespace:(NSString *)nsURI prefix:(NSString *)aPrefix;

/*!
 *
 */
- (void)removeAttributeNamed:(NSString *)localName inNamespace:(NSString *)namespaceURI prefix:(NSString *)prefix;
 
@end


@interface DOMElement : DOMParent <DOMElement, DOMNamespaceAware> {
	@private
		NSString *localName;
		NSString *prefix;
		NSString *namespaceURI;
	
		NSMutableDictionary *attributes;
}

+ (id <DOMElement>)elementWithName:(NSString *)name;

+ (id <DOMElement>)elementWithName:(NSString *)name namespaceURI:(NSString *)nsURI;

+ (id <DOMElement>)elementWithName:(NSString *)name namespaceURI:(NSString *)nsURI prefix:(NSString *)prefix;

/*!
 * Initializes a new element with a name.
 *
 * @param name     The name of the element (\<elementname\>)
 * @result         A newly initialized element
 */
- (id)initWithName:(NSString *)name;

- (id)initWithName:(NSString *)name namespaceURI:(NSString *)nsURI;

- (id)initWithName:(NSString *)name namespaceURI:(NSString *)nsURI prefix:(NSString *)prefix;

@end
