/*
 * Iconara DOM framework: DOMTraversal (created 7 July 2004)
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


@protocol DOMNode;


/*!
 * 
 * 
 */
@interface DOMTraversal : NSObject {
	id <DOMNode> contextNode;
	id           delegate;
	void *       userInfo;
}

+ (void)startTraversalForContextNode:(id <DOMNode>)node delegate:(id)delegate userInfo:(id)userInfo;

- (id)initWithContextNode:(id <DOMNode>)node;

/*!
 * Set the delegate that will recieve messages during the traversal.
 *
 * The delgate should respond to any combination of these messages:
 *
 *     - visitNode:userInfo: or preorderVisitNode:userInfo:
 *       sent before the children of the node are traversed, i.e preorder traversal
 *
 *     - postorderVisitNode:userInfo:
 *       sent after the children of the node are traversed, i.e postorder traversal
 *
 * The first argument is a node (id < DOMNode >), the user info argument is 
 * a generic object pointer (id). The return type is void.
 *
 */
/*
 * @exception NSInvalidArgumentException
 *     Raised if the delegate does not implement the correct methods.
 */
- (void)setDelegate:(id)delegate;

/*!
 * The user info pointer will be sent to the delegate for each visited node.
 */
- (void)setUserInfo:(id)userInfo;

/*!
 * Starts the traversal.
 */
- (void)start;

@end
