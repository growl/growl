/*
 * Iconara DOM framework: DOMPreprocessor (created 8 May 2003)
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
 * A preprocessor is a black box where data.
 * comes in at one end, and comes out again,
 * processed, on the other end.
 * 
 * Preprocessors can be good for many things, for
 * example to resolve external dependencies and
 * processing instructions.
 *
 */
@interface DOMPreprocessor : NSObject { }

+ (DOMPreprocessor *)preprocessor;

/*!
 * Process a chunk of data.
 */
- (NSData *)process:(NSData *)data;

/*!
 * Process a chunk of data.
 *
 * The source URL is used to resolve any external dependencies.
 */
- (NSData *)process:(NSData *)data sourceURL:(NSURL *)sourceURL;

@end
