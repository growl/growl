/*
 * Iconara DOM framework: DOMXIncludeResolver (created 30 January 2005)
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
#import "DOMPostprocessor.h"


/*!
 * Resolves XIncludes in the source document. The includes are
 * done in-place, since that is assumed to be the desired action,
 * since the post processing should be performed just after the 
 * document has been parsed.
 *
 * @note
 *     The #processNode: method of this class expects a parent node,
 *     else it will raise an NSInvalidArgumentException.
 *
 * @note
 *     Current implementation resolves simple href-attribute based 
 *     relative includes.The implementation of this post processor 
 *     is very basic, it serves more as an example of what can be 
 *     done with post processors.
 */
@interface DOMXIncludeResolver : DOMPostprocessor <DOMVisitor> { }

@end
