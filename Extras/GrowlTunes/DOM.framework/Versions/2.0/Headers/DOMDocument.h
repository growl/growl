/*
 * Iconara DOM framework: DOMDocument (created 27 April 2002)
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
#import "DOMParentNode.h"


@protocol DOMNode, 
          DOMDocType, 
	      DOMElement;


/*!
 * Represents a XML-document itself.
 *
 * A document cannot contain text or attribute nodes,
 * any attempt to append or insert one will result in
 * an exception being raised.
 * A document can only contain one doctype and one
 * element node. Should you try to append or insert
 * a second, the first vill be removed.
 */
@protocol DOMDocument <DOMNode, DOMParent>

/*!
 * Sets a new root element.
 *
 * The element is detached before it is set. It will
 * also be added to the same index in the childrens
 * array as the last root element.
 *
 * The previous root element is detached and removed.
 *
 * @param element The new root element
 */
- (void)setDocumentElement:(id <DOMElement>)element;

/*!
 * Returns the root element of this document.
 */
- (id <DOMElement>)documentElement;

/*!
 * Sets the doctype of this document.
 *
 * The doctype is always the first node in the document.
 *
 * The node is detached before it is set and the previous doctype 
 * is detached and removed.
 *
 * @param docType The new doctype
 */
- (void)setDocType:(id <DOMDocType>)docType;

/*!
 * Returns the doctype of this document.
 */
- (id <DOMDocType>)docType;

@end


@interface DOMDocument : DOMParent <DOMDocument> {
	id <DOMDocType> docType;
	id <DOMElement> documentElement;
}

+ (id <DOMDocument>)document;

+ (id <DOMDocument>)documentWithElement:(id <DOMElement>)root;

/*!
 * Initializes a new document and sets the root element.
 *
 * The root element specified will be detached before set, 
 * just to be sure that it does not belong to another document.
 *
 * @param element  The root element to use
 * @result         A fresh, new DOMDocument is returned
 */
- (id)initWithElement:(id <DOMElement>)element;

@end
