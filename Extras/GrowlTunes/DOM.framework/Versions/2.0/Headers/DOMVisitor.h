/*
 * Iconara DOM framework: DOMVisitor (created 12 August 2004)
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
 *
 * For API documentation see the corresponding header file.
 *
 */

#import <Foundation/Foundation.h>


@protocol DOMDocument, 
          DOMCDATASection, 
          DOMComment, 
          DOMDocType, 
          DOMDocumentFragment, 
          DOMElement, 
          DOMProcessingInstruction, 
          DOMText;


/*!
 * Formal declaration of the visitor pattern.
 * 
 */
@protocol DOMVisitor <NSObject>

- (void)visitDocumentNode:(id <DOMDocument>)document userInfo:(id)userInfo;

- (void)visitCDATASectionNode:(id <DOMCDATASection>)cdata userInfo:(id)userInfo;

- (void)visitCommentNode:(id <DOMComment>)comment userInfo:(id)userInfo;

- (void)visitDocTypeNode:(id <DOMDocType>)docType userInfo:(id)userInfo;

- (void)visitDocumentFragmentNode:(id <DOMDocumentFragment>)fragment userInfo:(id)userInfo;

- (void)visitElementNode:(id <DOMElement>)element userInfo:(id)userInfo;

- (void)visitProcessingInstructionNode:(id <DOMProcessingInstruction>)pi userInfo:(id)userInfo;

- (void)visitTextNode:(id <DOMText>)text userInfo:(id)userInfo;

@end


/*!
 * To be implemented by visitable nodes.
 *
 * The basic implementation is this:
 *
 * @code
 *     - (void)acceptVisitor:(id < DOMVisitor >)visitor {
 *         [visitor visit[NODETYPE]Node:self];
 *     }
 * @endcode
 *
 * Where [NODETYPE] should be the type of the node.
 *
 * The visitor should implement the #DOMVisitor protocol. If it doesn't, the
 * corresponding message will be sent anyway, and the client code
 * is responsible for actually implementing the message.
 * 
 */
@protocol DOMVisitable <NSObject>

- (void)acceptVisitor:(id)visitor userInfo:(id)userInfo;

@end