/*
 * Iconara DOM framework: DOMFormatOptions (created 10 December 2002)
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
 * This class encapsulates information on how a document should be formatted when
 * being converted to a string or written to a file.
 *
 * Currently there are five options:
 *
 *   - indent string
 *     Determines which string is used for indenting, the default is tab (\\t),
 *     can be set to the empty string for no indentation at all
 *
 *   - use newlines
 *     Determines if there will be any line breaks between nodes,
 *     the output will be totally unintelligible if newlines are not
 *     used, but it will be more compact, which may be desired
 *
 *   - normalize whitespace
 *     This setting will make the formatter normalize the whitespace of 
 *     text nodes before their contents are included (see #[DOMText dataNormalizeWhitespace:]
 *     for more info).
 *
 *   - include prolog
 *     This setting applies only when the document is written to a file,
 *     if set to YES, the XML prolog (<?xml version="1.0"?>) will be written
 *     at the top of the file, the encoding will also be specified.
 *
 *   - inline content of elements
 *     This setting takes a set of element names (as strings), when encountering
 *     these elements, the formatter will not include newlines before or after
 *     the element. Elements in mixed content (elements that have text node siblings)
 *     will always be inlined. Example (the element "string" has inlined contents):
 *
 *     @code
 *         <test>
 *             <string>It is usually not this cold in may</string>
 *         </test>
 *     @endcode
 *
 * This class also encapsulates some logic determining how these options should 
 * affect the result. The formatter will query it's options object about when
 * to add a newline, add indentation, and so forth.
 *
 */
@interface DOMFormatOptions : NSObject {
	NSString *indentString;
	NSSet *inlinedElements;

	BOOL usesNewlines;
	BOOL includeProlog;
	BOOL normalizeWhitespace;
}

/*!
 * Returns options object with the default options set.
 *
 * The default options are:
 *   - indent string: "\\t"
 *   - use newlines: YES
 *   - include prolog: YES
 *   - normalize whitespace: YES
 *   - don't inline the contents of any elements (except those in mixed content)
 */
+ (DOMFormatOptions* )formatOptions;

- (void)setIndentString:(NSString *)indent;

- (NSString *)indentString;

- (void)setUsesNewlines:(BOOL)newlines;

- (BOOL)usesNewlines;

- (void)setIncludeProlog:(BOOL)prolog;

- (BOOL)includeProlog;

- (void)setNormalizeWhitespace:(BOOL)normalize;

- (BOOL)normalizeWhitespace;

/*!
 * The named elements will have their content inlined, that
 * is, there will be no space between the end of the tag and
 * the content.
 *
 * Elements in mixed content (elements that have text node siblings) will
 * always be inlined.
 *
 * @param elementNames
 *        The names of the elements that should be inlined in
 *        text (ex. ["span", "bold", "name"]), an NSSet of NSStrings
 */
- (void)inlineContentOfElements:(NSSet *)elementNames;

/*!
 * Returns true if the element should have inlined content (as
 * specified by #inlineContentOfElements).
 */
- (BOOL)elementShouldHaveInlinedContent:(NSString *)elementName;

/*!
 * Decides which nodes to indent, based on rules and options.
 *
 * All nodes should be indented, except for:
 *   - In mixed content nodes should not be indented, except 
 *     for the first sibling, which should be indented if 
 *     the parent is not in mixed content.
 *   - Text node children of elements that should have inlined text
 */
- (BOOL)shouldIndentNode:(id <DOMNode>)node;

/*!
 * In these cases there should NOT be a newline after:
 *   - Nodes whose parent is in mixed content.
 *   - Nodes in mixed content (unless it is the last one).
 *   - Nodes with a parent that has been set to have inlined content.
 */
- (BOOL)shouldHaveNewlineAfterNode:(id <DOMNode>)node;

/*!
 * In these cases there should NOT be a newline before:
 *   - Nodes whose parent is in mixed content.
 *   - Nodes with a parent that has been set to have inlined content.
 */
- (BOOL)shouldHaveNewlineBeforeNode:(id <DOMNode>)node;

@end


/*!
 * Defines methods to read and write format options files.
 *
 * Format options can be stored as property list files (Apple Plist format).
 */
@interface DOMFormatOptions ( Serialization )

/*!
 * Reads a format options object from a property list file.
 */
+ (DOMFormatOptions *)formatOptionsFromFile:(NSString *)path;

/*!
 * Saves this format options object to a file as a property list.
 */
- (void)saveToFile:(NSString *)path;

@end