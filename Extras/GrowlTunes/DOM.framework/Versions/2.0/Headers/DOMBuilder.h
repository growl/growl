/*
 * Iconara DOM framework: DOMBuilder (created 4 December 2002)
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

#import "DOM.h"


/*!
 * An abstract class for building documents.
 *
 * Subclasses of this class can build DOM-structures, this
 * abstract implementation cannot build anything.
 *
 * Concrete subclasses can be aquired by using the methods
 * in the BuilderFactory-category.
 *
 * To build a document use the default builder (aquired
 * by calling #defaultBuilder, or by using #documentFromFile:,
 * which calls the default builder internally.
 * 
 * @note
 *     All the build*-methods and documentFromFile may raise
 *     either an DOMMalformedDocumentException or a DOMNoDataException. 
 *
 * @exception DOMMalformedDocumentException 
 *     raised if the parser encountered an error. Additional 
 *     information (line and row number, document name and so on) 
 *     should be provided in the exception's message, if that 
 *     information is available from the parser.
 *
 * @exception DOMNoDataException 
 *      raised if the data sent to the parser or the data from 
 *      the URL sent was empty.
 *
 */
@interface DOMBuilder : NSObject { }

/*!
 * Convienience method for quickly building a document 
 * from a file, uses the default builder.
 *
 * @exception DOMMalformedDocumentException
 *     see class documentation for more info
 *
 * @exception DOMNoDataException
 *     see class documentation for more info
 */
+ (DOMDocument *)documentFromFile:(NSString *)path;

/*!
 * Builds a document from a file at path, returns the document
 * May be implemented in a subclass, otherwise reads the data
 * at the path and calls #buildFromData:sourceURL:.
 *
 * Unless overridden by a subclass, calls #buildFromData:sourceURL:
 *
 * @exception DOMMalformedDocumentException
 *     see class documentation for more info
 *
 * @exception DOMNoDataException
 *     see class documentation for more info
 */
- (DOMDocument*)buildFromFile:(NSString*)path;

/*!
 * buildFromData:
 * Build a document from a blob of data and returns it
 * May be implemented in a subclass, otherwise 
 * calls #buildFromData:sourceURL: with NULL as the source URL.
 *
 * Unless overridden by a subclass, calls #buildFromData:sourceURL:
 * (with nil as second argument).
 *
 * @exception DOMMalformedDocumentException
 *     see class documentation for more info
 *
 * @exception DOMNoDataException
 *     see class documentation for more info
 */
- (DOMDocument *)buildFromData:(NSData *)data;

/*!
 * Build a document from data located at an URL
 * May be implemented in a subclass, otherwise fetches the data 
 * at the URL and calls #buildFromData:sourceURL:.
 *
 * Unless overridden by a subclass, calls #buildFromData:sourceURL:
 *
 * @exception DOMMalformedDocumentException
 *     see class documentation for more info
 *
 * @exception DOMNoDataException
 *     see class documentation for more info
 */
- (DOMDocument *)buildFromURL:(NSURL *)url;

/*!
 * Build a document from a blob of data.
 *
 * The source URL is used to resolve any relative references 
 * contained in the document (if any). Pass nil if no URL 
 * is available. 
 *
 * To be implemented by a subclass, this version raises an exception.
 * Unless any of the other build*-methods are overridden, they
 * all call this method.
 *
 * @exception DOMMalformedDocumentException
 *     see class documentation for more info
 *
 * @exception DOMNoDataException
 *     see class documentation for more info
 */
- (DOMDocument *)buildFromData:(NSData *)data sourceURL:(NSURL *)url;

@end


/*!
 * Defines methods for creating builders
 * The most common way of getting a builder is by calling
 * +defaultBuilder.
 *
 * New builders can be plugged in into the DOM framework
 * by placing a bundle with the extension "builder" in
 * the PlugIns-directory in the framework bundle.
 * To aquire an instance of a plug in builder, use the
 * +builderForName-method (the name is the name of the bundle
 * minus the ".builder" extension).
 *
 * You can get a list of installed builders from the
 * method +installedBuilders.
 */
@interface DOMBuilder ( BuilderFactory )

/*!
 * Returns an instance of the default builder class
 * The default builder is currently an Cocoa-wrapped
 * version of the Expat builder.
 */
+ (DOMBuilder *)defaultBuilder;

/*!
 * Creates a builder by name
 * If there is an installed builder (a bundle with the extension ".builder")
 * in the frameworks plugin-directory (DOM.framework/PlugIns), named
 * as specified, that builder's bundle will be loaded and an
 * instance of it's principal class will be created. Do not include ".builder"
 * in the name, it will be added automatically.
 *
 * Example: 
 * @code
 *     // get an instance of the builder in "MyBuilder.builder"
 *     DOMBuilder *builder = [DOMBuilder builderForName:@"MyBuilder];
 * @endcode
 *
 * The principal class of the bundle is assumed to be a subclass of DOMBuilder.
 *
 * @param name     The name of the builder to be loaded, without the ".builder" extension
 * @result         An autoreleased instance of the named builder
 */
+ (DOMBuilder *)builderForName:(NSString *)name;

/*!
 * Returns an array of the names of all installed builders
 * Builders are installed in the framework's default plugin directory
 * (DOM.framework/PlugIns).
 */
+ (NSArray *)installedBuilders;
 
@end
