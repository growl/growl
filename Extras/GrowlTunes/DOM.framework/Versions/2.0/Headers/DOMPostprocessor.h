/*
 * Iconara DOM framework: DOMPostprocessor (created 30 January 2005)
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


@protocol DOMDocument;


/*!
 * Abstract superclass of post processors.
 *
 * A postprocessor takes a document or a node after it has been
 * parsed and performs some kind of processing of the nodes,
 * an example is resolving XIncludes.
 *
 */
@interface DOMPostprocessor : NSObject { }

+ (id)postprocessor;

/*!
 * Performs processing of a node. The source URL is used to resolve 
 * relative URI:s, if needed.
 *
 * The returned node may or may not be the same as the one passed.
 *
 * To be implemented by a concrete subclass.
 */
- (id <DOMNode>)processNode:(id <DOMNode>)node sourceURL:(NSURL *)url;

/*!
 * See #processNode:sourceURL:.
 *
 * Subclasses does not need to override this method.
 */
- (id <DOMNode>)processNode:(id <DOMNode>)node;

@end