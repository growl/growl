/*
 * Iconara DOM framework: DOMException (created 17 June 2003)
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

/* Exceptions defined by the DOM Level 1 Core */
extern NSString *DOMIndexSizeException;
extern NSString *DOMStringSizeException;
extern NSString *DOMHierarchyRequestException;
extern NSString *DOMWrongDocumentException;
extern NSString *DOMInvalidCharacterException;
extern NSString *DOMNoDataAllowedException;
extern NSString *DOMNoModificationAllowedException;
extern NSString *DOMNotFoundException;
extern NSString *DOMNotSupportedException;
extern NSString *DOMInuseAttributeException;

/* Exceptions defined by the DOM Level 2 Core */
extern NSString *DOMInvalidStateException;
extern NSString *DOMSyntaxException;
extern NSString *DOMInvalidModificationException;
extern NSString *DOMNamespaceException;
extern NSString *DOMInvalidAccessException;
extern NSString *DOMValidationException;

/* Exceptions defined by this framework */
extern NSString *DOMMalformedDocumentException; // raised by the builder
extern NSString *DOMNoDataException;			// raised by the builder
extern NSString *DOMNotYetImplementedException; // raised where applicable
extern NSString *DOMMalformedXPathExpression;   // raised by the XPath expression compilator
extern NSString *DOMXPathEvaluationException;   // raised by the XPath expression evaluator
extern NSString *DOMFormatterException;			// raised by the formatter
extern NSString *DOMXIncludeException;			// raised by the XInclude post processor
