/*
 * Iconara DOM framework: DOMDocumentRepresentation (created 12 Augut 2004)
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


/*!
 *
 *
 */
@interface DOMDocumentRepresentation : NSObject {
	NSMutableString *stringRep;

	NSString *indentString;
	
	int indentLevel;
}

- (id)initWithIndentString:(NSString *)indent;

- (NSString *)stringRepresentation;

- (void)appendIndent;

- (void)appendNewline;

- (void)appendString:(NSString *)string;

- (void)indent;

- (void)outdent;

@end
