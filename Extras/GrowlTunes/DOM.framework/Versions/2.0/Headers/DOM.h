/*
 * Iconara DOM framework: DOM (created 27 April 2002)
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

/*!
 * @mainpage Iconara DOM framework
 * @author   Theo Hultberg / Iconara
 * @version  v2.0
 *
 * Iconara DOM framework is a Cocoa-framework for accessing, 
 * manipulating and outputting XML-data. It's similar to the 
 * JDOM and XOM frameworks for Java.
 *
 * An XML-document can be thought of as a tree of nodes. Nodes
 * can be of different types, an the most common types are
 * elements (XML-tags, "<tag>") and text nodes. There are
 * also processing instruction nodes, comment nodes and
 * CDATA-section nodes. The whole document is also considered
 * to be a node in itself. Nodes that can contain other nodes are
 * called parent nodes, and regular nodes are called leaf nodes.
 *
 * This framework provides access to an XML-document in this way,
 * which is called the Document Object Model, hence DOM.
 * Elements, text and other nodes types can be accessed and 
 * manipulated. A document can be created either from a file or
 * programmaticaly by creating and adding node objects. A document
 * can also be written to a file (serialized), and formatted in
 * a way that is suitable.
 *
 * The framework consist of a number of components: the core API,
 * the core implementation, the builder API, the formatter, 
 * the traversal module and the XPath module.
 *
 * The core API and core implementation are the two most important, and
 * most of the time you can regard these as being one. The core API
 * is defined by a set of protocols defining the different node types
 * and which methods they implement, the node types are Node (abstract),
 * Document, Element, Attribute, DocumentFragment, CharacterData (abstract),
 * Text, Comment, CDATASection, DocType, ProcessingInstruction, Attribute
 * and Parent. The core implementation is just concrete implementations of
 * these protocols.
 *
 * The reason for using protocols to define the external API is a question
 * of design; apart for being a clean separation of API and implementation
 * it allows for more than one concrete implementation. There could be,
 * for example, an implementation that saved the data in a database instead
 * of keeping the whole object graph in memory. There is also other DOM or
 * DOM-like implementations for C and Objective-C that could be used as
 * part of this DOM framework, if a wrapper was written. By separating the 
 * API from the implementation this becomed much easier to do.
 *
 * The Objective-C syntax is, in my opinion, a little biased towards classes,
 * protocols don't fit in very well, as the do in Java. Moreover, the names
 * of the core protocols are the same as the names of the core classes, that
 * may be confusing, but I thought it was best to do it that way. You may
 * find the protocol based API a bit annoying, that has not been my intention 
 * to do, it is only in the interest of good design. 
 *
 * The builder API defines a common way of creating DOM trees. The builder are
 * implemented as plug-ins to the framework. Currently the only plug-in is
 * a builder that uses the popular open source parser Expat. It is not hard to
 * write implementations for other parsers, for example Apple's NSXML or CFXML
 * parsers, although those two lack namespace support. I would very much like
 * to see contributions in this area. Other parsers that could be wrapped are
 * Sablotron, libxml or Xerces (the C++ version).
 *
 * The formatter is used to output XML from a DOM tree. The output format can
 * be configured to suit most needs (although not all, I'm afraid).
 *
 * The traversal module encapsulates a pre- or post-order traversal of the DOM
 * tree, which is useful if your application needs to visit all nodes in a
 * document in order (for example when building a tree-view, pretty-printing,
 * or doing other kinds of processing based on the structure of the tree). It
 * also contains protocols for formally implementing the visitor pattern (which
 * is used in most cases where the traversal is used).
 *
 * Finally the XPath module enables you to run XPath queries on the DOM tree.
 * The current implementation handles basic expressions, advanced predicates 
 * are not supported yet (but location predicates are).
 *
 * 
 *
 * @note
 *     Iconara DOM is released under the GNU GPL licence. If the
 *     application you are working on has an incompatible licence,
 *     contact me, and we'll sort it out. The rationale behind
 *     using GPL for the framework is that I'm not interested in
 *     anyone making money of my work, but at the same time, I want
 *     to give something back to the community.
 *
 */

/*!
 * @file DOM.h
 *
 * Iconara DOM Framework prefix header
 *
 * Imports the interfaces of the node types and the helper classes
 *
 */

#import <Foundation/Foundation.h>

/* The nodes */
#import "DOMNode.h"
#import "DOMParentNode.h"
#import "DOMAttribute.h"
#import "DOMCDATASection.h"
#import "DOMCharacterData.h"
#import "DOMComment.h"
#import "DOMDocType.h"
#import "DOMDocument.h"
#import "DOMDocumentFragment.h"
#import "DOMElement.h"
#import "DOMProcessingInstruction.h"
#import "DOMText.h"

/* The helper classes */
#import "DOMBuilder.h"
#import "DOMFormatter.h"
#import "DOMFormatOptions.h"
#import "DOMExceptions.h"
#import "DOMNamespaceAware.h"
#import "DOMXPathExpression.h"
#import "DOMTraversal.h"
#import "DOMVisitor.h"

/* Other classes */
#import "DOMPreprocessor.h"
#import "DOMPostprocessor.h"
#import "DOMEntityResolver.h"
#import "DOMXIncludeResolver.h"
