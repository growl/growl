/*
 * Iconara DOM framework: DOMXPathExpression (created 2 October 2003)
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
#import "DOM.h"


/*!
 * Perfoms XPath searches on node trees.
 * XPath compliance:
 *     - handles basic axes (./, ../, /, //, .//, \@)
 *     - handles all named axes except following and preceeding
 *     - handles unions (path|path)
 *     - does not handle functions, subscripts 
 *       nor other predicates
 */
@interface DOMXPathExpression : NSObject {	
	NSString *expression;
}

/*!
 * Convenience construtor, see #initWithString:
 */
+ (DOMXPathExpression *)expressionWithString:(NSString *)expr;

/*!
 * Initializes this object with an XPath expression.
 *
 * Abbreviated axes in the expression are expanded prior
 * to evaluation (i.e. ".." is expanded to "parent::node()").
 */
- (id)initWithString:(NSString *)expression;

/*!
 * Returns an array containing all nodes matching the expression.
 *
 * If no nodes matches the expression, returns an empty array.
 *
 * @param contextNode The node for which to start the evaluation
 *
 * @returns An array with the matching nodes, or an empty array
 */
- (NSArray *)matchesForContextNode:(id <DOMNode>)contextNode;

/*!
 * Returns the first node in document order that matches the expression
 * 
 * Returns nil if no nodes matched the expression. See #matchesForContextNode: 
 * for further documentation. There is no performance gain in using this method
 * over #matchesForContextNode:.
 *
 * @param contextNode The node for which to start the evaluation
 *
 * @returns A DOMNode or nil
 */
- (id <DOMNode>)firstMatchForContextNode:(id <DOMNode>)contextNode;

@end


@interface DOMXPathExpression ( PrivateMethods )

/*!
 * Expands occurences of shorthand axis notation to the regular form.
 *
 * Example:
 * @code
 *     "/name"       becomes  "parent::name"
 *     "."           becomes  "self::node()"
 *     "//para/@id"  becomes  "descendant-or-self::para/attribute::id"
 * @endcode
 */
+ (NSString *)expandExpression:(NSString *)expression;

+ (NSArray *)evaluateExpression:(NSString *)expression forContextNode:(id <DOMNode>)contextNode;

+ (NSArray *)axisContents:(NSString *)axis forContextNode:(id <DOMNode>)contextNode;

+ (NSString *)axisOfExpression:(NSString *)expression;

+ (NSString *)nodeTestOfExpression:(NSString *)expression;

+ (NSArray *)predicatesOfExpression:(NSString *)expression;

+ (NSArray *)filter:(NSArray *)swarm withTest:(NSString *)nodeTest attributes:(BOOL)attributes;

+ (NSArray *)filter:(NSArray *)swarm withPredicate:(NSString *)predicate;

@end
