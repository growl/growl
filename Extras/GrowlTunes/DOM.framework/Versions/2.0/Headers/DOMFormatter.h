/*
 * Iconara DOM framework: DOMFormatter (created 9 December 2002)
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


@class DOMDocument, DOMFormatOptions;


/*!
 * A class for pretty-printing and outputing documents.
 *
 * Example usage:
 *
 * @code
 *
 * // the object "xml" will hold a string representation of a document
 * NSString *xml = [DOMFormatter stringFromNode:document];
 *
 * // the document will be written to a file
 * [DOMFormatter writeNode:document toFile:@"/tmp/document.xml"];
 *
 * @endcode
 *
 * The output format can be set by tweaking an instance of DOMFormatOptions.
 * See the documentation for that class for more information.
 *
 */
@interface DOMFormatter : NSObject <DOMVisitor> {
	DOMFormatOptions *formatOptions;

	id <DOMNode> contextNode;
}

/*!
 * Returns a new formatter.
 */
+ (DOMFormatter *)formatter;

/*!
 * See #stringFromNode:formatOptions:
 */
+ (NSString *)stringFromNode:(id <DOMNode>)node;

/*!
 * Equivalent to:
 *
 * @code
 *
 * DOMFormatter *formatter = [DOMFormatter formatter];
 *     
 * [formatter setContextNode:node];
 * [formatter setOptions:[DOMFormatOptions formatOptions]];
 *
 * NSString *result = [formatter string];
 *
 * @endcode
 */
+ (NSString *)stringFromNode:(id <DOMNode>)node formatOptions:(DOMFormatOptions *)options;

/*!
 * See #writeNode:toFile:formatOptions:
 */
+ (BOOL)writeNode:(id <DOMNode>)node toFile:(NSString *)path;

/*!
 * Equivalent to:
 *
 * @code
 *
 * DOMFormatter *formatter = [DOMFormatter formatter];
 *     
 * [formatter setContextNode:node];
 * [formatter setOptions:[DOMFormatOptions formatOptions]];
 *
 * [formatter writeToFile:@"..."];
 *
 * @endcode
 */
+ (BOOL)writeNode:(id <DOMNode>)node toFile:(NSString *)path formatOptions:(DOMFormatOptions *)options;

/*!
 * Sets a new options object as the options used.
 */
- (void)setFormatOptions:(DOMFormatOptions *)options;

/*!
 * Sets the context document. It is this document that will
 * be formatted and outputed
 */
- (void)setContextNode:(id <DOMNode>)node;

/*!
 * Creates a string representation of the document and returns it.
 * The document will be formatted according to the default format
 * options, or alternative format options, if applicable.
 *
 * Will replace &, <, >, ", and ' with the escaped versions.
 *
 * No XML prolog will be added to the string, even if that is set
 * in the options. The prolog is however added by #writeToFile:.
 * It's not clear whether or not this is the expected behaviour,
 * from reading the XML spec.
 */
- (NSString *)string;

/*!
 * Writes the results of #string to a file at the specified path.
 *
 * Currently, the file will be written using UTF-8 encoding. In the
 * future there will be a setting to change this.
 *
 * If the options are set to include a prolog, it will be added and
 * the encoding will be specified as UTF-8.
 */
- (BOOL)writeToFile:(NSString *)path;

@end
